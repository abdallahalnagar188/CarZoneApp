# 06 - Web Developer API Integration Guide

This guide provides clean, production-ready TypeScript code examples using `@supabase/supabase-js` (or `@supabase/ssr` in Next.js) to build both the **Car Wash Dashboard** and the **Platform Admin Panel**.

---

## 1. Client Initialization & Setup

### Install Dependencies
```bash
npm install @supabase/supabase-js @supabase/ssr
```

### Shared Client Utility (`lib/supabase/client.ts`)
```typescript
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  );
}
```

---

## 2. Car Wash Dashboard Endpoints & Queries

### A. Fetch Dashboard Overview Statistics (Today)
Fetches today's total reservations, active bays, revenue, and pending bookings for the current branch.

```typescript
export async function getBranchDailyStats(branchId: string) {
  const supabase = createClient();
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  // 1. Fetch today's orders
  const { data: orders, error } = await supabase
    .from('orders')
    .select('id, total, status, payment_status, scheduled_at, duration_min')
    .eq('branch_id', branchId)
    .gte('scheduled_at', startOfDay.toISOString())
    .lte('scheduled_at', endOfDay.toISOString());

  if (error) throw error;

  const totalBookings = orders.length;
  const completedOrders = orders.filter((o) => o.status === 'completed');
  const todayRevenue = completedOrders.reduce((sum, o) => sum + o.total, 0);
  const activeNow = orders.filter((o) => o.status === 'in_service').length;
  const pendingConfirmation = orders.filter((o) => o.status === 'pending').length;

  return {
    totalBookings,
    todayRevenue,
    activeNow,
    pendingConfirmation,
    orders,
  };
}
```

---

### B. Live Bay Dispatcher & Realtime Incoming Bookings Subscription
Subscribes via Supabase Realtime to order insertions and status updates for the current branch so the bay dispatcher board updates instantly without polling.

```typescript
export function subscribeToBranchOrders(
  branchId: string,
  onOrderChanged: (order: any) => void
) {
  const supabase = createClient();

  const channel = supabase
    .channel(`branch-orders-${branchId}`)
    .on(
      'postgres_changes',
      {
        event: '*', // Listen to INSERT, UPDATE, DELETE
        schema: 'public',
        table: 'orders',
        filter: `branch_id=eq.${branchId}`,
      },
      (payload) => {
        console.log('Realtime order update received:', payload);
        onOrderChanged(payload.new);
      }
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}
```

---

### C. Booking Check-In & Code Verification (QR Scanner)
When a customer arrives at the wash bay, the staff either scans their QR code or types in the 5-character check-in code.

```typescript
export async function verifyAndCheckInOrder(branchId: string, codeOrNumber: string) {
  const supabase = createClient();

  // Search by 5-char code or order number (e.g. 'CZ-10042')
  const { data: order, error } = await supabase
    .from('orders')
    .select(`
      id,
      number,
      code,
      scheduled_at,
      status,
      payment_status,
      total,
      items,
      note,
      customers:customer_id (id, name, phone),
      vehicles:vehicle_id (make, model, color, plate)
    `)
    .eq('branch_id', branchId)
    .or(`code.eq.${codeOrNumber.trim().toUpperCase()},number.eq.${codeOrNumber.trim().toUpperCase()}`)
    .maybeSingle();

  if (error) throw error;
  if (!order) throw new Error('Booking not found for this branch');

  return order;
}
```

---

### D. Advance Booking Lifecycle Status
Transitions an order from `confirmed` ➔ `waiting` (checked in) ➔ `in_service` ➔ `completed`.

```typescript
export async function advanceOrderStatus(
  orderId: string,
  nextStatus: 'waiting' | 'in_service' | 'completed' | 'cancelled' | 'no_show',
  options?: { paymentStatus?: 'paid'; cancelReason?: string }
) {
  const supabase = createClient();

  // 1. Fetch existing timeline
  const { data: current, error: fetchErr } = await supabase
    .from('orders')
    .select('timeline')
    .eq('id', orderId)
    .single();

  if (fetchErr) throw fetchErr;

  const updatedTimeline = [
    ...(current.timeline || []),
    { key: nextStatus, at: new Date().toISOString() },
  ];

  const updatePayload: Record<string, any> = {
    status: nextStatus,
    timeline: updatedTimeline,
  };

  if (options?.paymentStatus) {
    updatePayload.payment_status = options.paymentStatus;
  }
  if (options?.cancelReason) {
    updatePayload.cancel_reason = options.cancelReason;
  }

  const { data, error } = await supabase
    .from('orders')
    .update(updatePayload)
    .eq('id', orderId)
    .select()
    .single();

  if (error) throw error;
  return data;
}
```

---

### E. Service Catalog Management (Add / Update Services)

```typescript
export async function upsertWashService(service: {
  id?: string;
  branch_id: string;
  type: 'primary' | 'addon';
  category: string;
  name: { ar: string; en: string };
  description: { ar: string; en: string };
  price: number;
  duration_min: number;
  active: boolean;
}) {
  const supabase = createClient();

  const payload = {
    id: service.id || `srv_${Date.now()}`,
    branch_id: service.branch_id,
    type: service.type,
    category: service.category,
    name: service.name,
    description: service.description,
    price: service.price,
    duration_min: service.duration_min,
    active: service.active,
  };

  const { data, error } = await supabase
    .from('services')
    .upsert(payload)
    .select()
    .single();

  if (error) throw error;
  return data;
}
```

---

### F. Reply to Customer Review

```typescript
export async function replyToReview(reviewId: string, replyText: string) {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('reviews')
    .update({ reply: replyText })
    .eq('id', reviewId)
    .select()
    .single();

  if (error) throw error;
  return data;
}
```

---

## 3. Platform Admin Panel Endpoints & Queries

### A. List Partner Applications Pending Approval

```typescript
export async function getPendingApplications() {
  const supabase = createClient();

  const { data, error } = await supabase
    .from('businesses')
    .select(`
      id,
      name,
      legal_name,
      tax_number,
      commercial_reg_no,
      phone,
      email,
      created_at,
      branches (
        id,
        name,
        address,
        area_id,
        capacity,
        phone,
        approval_status
      )
    `)
    .eq('status', 'pending')
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}
```

---

### B. Approve or Reject a Business Application

```typescript
export async function setBusinessApproval(
  businessId: string,
  decision: 'approved' | 'rejected',
  commissionRate: number = 15.0
) {
  const supabase = createClient();

  // 1. Update business record
  const { error: bizErr } = await supabase
    .from('businesses')
    .update({
      status: decision,
      commission_rate: commissionRate,
      updated_at: new Date().toISOString(),
    })
    .eq('id', businessId);

  if (bizErr) throw bizErr;

  // 2. Cascade approval to associated branches
  const { error: branchErr } = await supabase
    .from('branches')
    .update({
      approval_status: decision,
    })
    .eq('business_id', businessId);

  if (branchErr) throw branchErr;

  // 3. Log audit event
  await logAdminAction({
    action: `business.${decision}`,
    target_entity: 'businesses',
    target_id: businessId,
    payload: { commission_rate: commissionRate },
  });

  return { success: true };
}
```

---

### C. Financial Settlement & Batch Payout Generation

```typescript
export async function generatePayoutBatch(params: {
  business_id: string;
  period_start: string; // 'YYYY-MM-DD'
  period_end: string;
  bank_account_id: string;
}) {
  const supabase = createClient();

  // 1. Calculate sum of unsettled net payouts from commissions
  const { data: commissions, error: commErr } = await supabase
    .from('commissions')
    .select('id, net_payout, order_id')
    .eq('business_id', params.business_id)
    .eq('status', 'pending');

  if (commErr) throw commErr;
  if (!commissions || commissions.length === 0) {
    throw new Error('No pending commissions eligible for payout');
  }

  const totalAmount = commissions.reduce((sum, c) => sum + c.net_payout, 0);

  // 2. Insert payout record
  const { data: payout, error: payErr } = await supabase
    .from('payouts')
    .insert({
      business_id: params.business_id,
      bank_account_id: params.bank_account_id,
      amount: totalAmount,
      period_start: params.period_start,
      period_end: params.period_end,
      status: 'pending',
    })
    .select()
    .single();

  if (payErr) throw payErr;

  // 3. Mark commission rows as settled
  const commissionIds = commissions.map((c) => c.id);
  await supabase
    .from('commissions')
    .update({ status: 'settled' })
    .in('id', commissionIds);

  return payout;
}
```

---

### D. File Upload to Supabase Storage (`images` Bucket)
Used for uploading branch cover images, partner registration papers, and service photos.

```typescript
export async function uploadPublicImage(
  file: File,
  folder: 'branches' | 'services' | 'complaints'
): Promise<string> {
  const supabase = createClient();
  const fileExt = file.name.split('.').pop();
  const filePath = `${folder}/${Date.now()}_${Math.random().toString(36).substring(2, 8)}.${fileExt}`;

  const { data, error } = await supabase.storage
    .from('images')
    .upload(filePath, file, {
      cacheControl: '3600',
      upsert: false,
    });

  if (error) throw error;

  // Generate public download URL
  const { data: publicUrlData } = supabase.storage
    .from('images')
    .getPublicUrl(filePath);

  return publicUrlData.publicUrl;
}
```

---

### E. Standardized Audit Logger Helper

```typescript
export async function logAdminAction(params: {
  action: string;
  target_entity: string;
  target_id?: string;
  payload?: Record<string, any>;
}) {
  const supabase = createClient();
  const { data: user } = await supabase.auth.getUser();

  await supabase.from('audit_logs').insert({
    actor_id: user.user?.id,
    actor_role: user.user?.app_metadata?.role || 'admin',
    action: params.action,
    target_entity: params.target_entity,
    target_id: params.target_id,
    payload: params.payload || {},
  });
}
```

---

## 4. Standard Pagination & Filtering Pattern

To optimize query speeds and maintain lightweight JSON payloads across large tables (`orders`, `reviews`, `audit_logs`):

```typescript
export async function getPaginatedOrders(options: {
  page: number; // 1-indexed
  pageSize: number;
  branchId?: string;
  status?: string;
  startDate?: string;
  endDate?: string;
}) {
  const supabase = createClient();
  const from = (options.page - 1) * options.pageSize;
  const to = from + options.pageSize - 1;

  let query = supabase
    .from('orders')
    .select('*', { count: 'exact' })
    .order('scheduled_at', { ascending: false })
    .range(from, to);

  if (options.branchId) query = query.eq('branch_id', options.branchId);
  if (options.status) query = query.eq('status', options.status);
  if (options.startDate) query = query.gte('scheduled_at', options.startDate);
  if (options.endDate) query = query.lte('scheduled_at', options.endDate);

  const { data, count, error } = await query;
  if (error) throw error;

  return {
    orders: data,
    totalCount: count ?? 0,
    totalPages: Math.ceil((count ?? 0) / options.pageSize),
  };
}
```
