# 09 - Gaps, Security Audit & Strategic Recommendations

This document details the findings discovered during the comprehensive audit of the live Supabase project (`tbcmgdwzarfdgzzmmele`) and the Flutter mobile codebase, accompanied by a prioritized mitigation plan and open architectural questions.

---

## 1. Discovered Gaps & Findings (Step 1C Analysis)

### A. Critical Security Vulnerabilities [P0]

#### 1. Ineffective Row-Level Security (RLS) Permissive Policies
- **Current State**: While RLS is technically toggled on across all 13 existing tables, every table contains an identical wide-open policy:
  ```sql
  -- On orders, customers, branches, services, reviews, vehicles...
  CREATE POLICY "Public write ..." ON public.orders FOR ALL TO anon, authenticated
  USING (true) WITH CHECK (true);
  ```
- **Vulnerability**: Any external actor possessing the public Supabase `anon` API key (which is embedded in client builds) can execute raw REST queries to `DELETE FROM orders;`, wipe the entire customer directory, alter service prices, or delete car wash branches.
- **Fix**: Revoke all `FOR ALL ... USING (true)` policies. Replace with authenticated role-specific policies (`customer`, `carwash_owner`, `carwash_staff`, `admin`) as provided in [04_SCHEMA.sql](file:///docs/backend-handoff/04_SCHEMA.sql).

#### 2. Plaintext JWT Storage in Database (`customers.access_token`)
- **Current State**: The Flutter client actively updates the `customers` table with the raw session access token:
  ```dart
  // In lib/core/services/carzone_db_service.dart:364
  await SupabaseService.client.from('customers').update({
    'access_token': token,
    'token_updated_at': now,
  }).eq('id', customerId);
  ```
- **Vulnerability**: Because `customers` is publicly readable under the current RLS policy, valid active bearer tokens of customers are exposed in plaintext.
- **Fix**: Immediately deprecate and cease writing to `customers.access_token`. Client session state should remain exclusively in local secure storage (`flutter_secure_storage`).

---

### B. Relational Integrity & Missing Foreign Keys [P1]

During the database inspection, multiple loose textual references were identified that lack formal foreign key constraints, risking orphaned records:

| Column | References | Issue | Mitigation |
|---|---|---|---|
| `branches.business_id` | No table exists | Loose string (e.g. `'biz_oasis'`). No parent entity exists for car wash companies. | Introduce `businesses` table with FK constraint. |
| `orders.offer_id` | `offers.id` | Nullable string without FK constraint. | Add `REFERENCES offers(id) ON DELETE SET NULL`. |
| `orders.vehicle_id` | `vehicles.id` | Text string without FK constraint. | Add `REFERENCES vehicles(id) ON DELETE SET NULL`. |
| `reviews.order_id` | `orders.id` | Nullable text without FK constraint. | Add `REFERENCES orders(id) ON DELETE SET NULL`. |
| `complaints.order_id` | `orders.id` | Text without FK constraint. | Add `REFERENCES orders(id) ON DELETE SET NULL`. |
| `complaints.customer_id` | `customers.id` | Text without FK constraint. | Add `REFERENCES customers(id) ON DELETE SET NULL`. |

---

### C. Database Performance & Indexing Advisories [P1]

The official Supabase Database Advisors (`get_advisors`) identified the following unindexed foreign keys and query bottlenecks:

1. **Unindexed Foreign Keys**:
   - `public.branch_shares` -> `branch_shares_branch_id_fkey` lacks a covering index.
   - `public.favorites` -> `favorites_branch_id_fkey` lacks a covering index.
2. **Missing Ordering & Filter Indexes**:
   - `orders (scheduled_at)`: Queried in slot overlap and day dispatching algorithms. Needs a BTREE index.
   - `orders (created_at)`: Queried on every home screen and booking history fetch. Needs a BTREE index.
   - `orders (number)`: Needs a `UNIQUE` index to prevent duplicate order numbers during concurrent checkout.

---

### D. Architectural & Feature Gaps for Web Panels [P1]

1. **No User Roles Table**: Currently, only `auth.users` exists with standard authenticated status. There is no representation of branch managers, technicians, or system administrators.
2. **Zero Realtime Tables Broadcasted**: The publication `supabase_realtime` contains 0 tables! Both the Flutter app and the proposed web dashboards would have to resort to aggressive polling without realtime enabled.
3. **Missing Financial Ledger**: Currently, payment is recorded as a simple string (`'pending'` or `'paid'`). There is no accounting for platform commission splits, partner earnings balances, or bank payouts.
4. **No Push Notification Device Registry**: The Flutter app handles notifications as in-app database records in `notifications`, but there is no table to store Firebase Cloud Messaging (FCM) device registration tokens.

---

## 2. Prioritized Roadmap & Fix List

```
┌────────────────────────────────────────────────────────────────────────┐
│ Phase 0: Critical Security & Integrity (Immediate - Before Launch)    │
├────────────────────────────────────────────────────────────────────────┤
│ [ ] Deploy hardened RLS policies (04_SCHEMA.sql)                       │
│ [ ] Deprecate customers.access_token writes from Flutter client         │
│ [ ] Add missing FK constraints (branches.business_id, orders FKs)      │
│ [ ] Add covering indexes on branch_shares and favorites                │
└────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Phase 1: Web Panel Multi-Tenancy Foundations                           │
├────────────────────────────────────────────────────────────────────────┤
│ [ ] Create user_roles, businesses, and branch_staff tables             │
│ [ ] Provision initial Super Admin account via SQL script               │
│ [ ] Add orders, notifications, and branches to supabase_realtime pub   │
│ [ ] Deploy automatic commission calculation trigger                    │
└────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Phase 2: Web Panels Frontend Development                               │
├────────────────────────────────────────────────────────────────────────┤
│ [ ] Build Car Wash Dashboard (Dispatcher, Bookings, Services, Earnings)│
│ [ ] Build Platform Admin Panel (Partner Approvals, Payouts, Settings)  │
│ [ ] Implement QR Code check-in scanner on Dashboard                    │
└────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Phase 3: Financial & Messaging Enhancements                            │
├────────────────────────────────────────────────────────────────────────┤
│ [ ] Integrate FCM push notification token storage                      │
│ [ ] Integrate Paymob / Fawry payment gateway for online prepayment     │
│ [ ] Implement automated bank wire payout export file (ACH / IBAN)      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Open Questions for Platform Leadership

Please review these strategic and operational decisions to guide the external web engineering team:

1. **Online Payment Gateway Provider**:
   - Current implementation defaults to Pay-at-Wash (Cash / POS Card).
   - If online prepayment is introduced, which Egyptian payment gateway will be primary? (**Paymob**, **Fawry**, **Kashier**, or **Stripe**)?
2. **Platform Commission Policy**:
   - The proposed schema introduces a default 15% platform commission rate with customizable per-business overrides. Is a **percentage per booking** model desired, or should there be a **monthly recurring SaaS subscription** per branch, or a **fixed fee per wash** (e.g., 20 EGP per booking)?
3. **Mobile Wash Service Expansion**:
   - The current codebase is architected for customer arrivals at fixed physical car wash locations (`at car wash location`).
   - If **mobile detailing at customer's home/work** is supported in the future, should we introduce customer address geocoordinates and service vans/drivers into the schema now?
4. **Partner Self-Registration vs Admin Manual Creation**:
   - Should partner car washes be able to register publicly from the landing page of the Car Wash Dashboard (entering a `pending` approval queue), or will the CarZone team manually provision partner businesses and issue staff credentials?
5. **Staff PIN Check-in**:
   - For fast bay operation in noisy/wet car wash bays, do you want receptionists to log into the tablet dashboard using individual 4-digit PINs (like restaurant POS terminals), or standard email/password?
