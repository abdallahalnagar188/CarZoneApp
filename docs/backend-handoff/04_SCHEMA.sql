-- ==============================================================================
-- CARZONE PLATFORM - COMPLETE DATABASE SCHEMA
-- File: 04_SCHEMA.sql
-- Description: Idempotent, runnable PostgreSQL schema for CarZone.
-- Supports: Customer Mobile App (Flutter), Car Wash Dashboard, Admin Panel.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. HELPER FUNCTIONS FOR ROW LEVEL SECURITY (RLS)
-- ==============================================================================

-- Returns the platform role of the currently authenticated user
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT role FROM public.user_roles WHERE user_id = auth.uid() LIMIT 1),
    'customer'
  );
$$;

-- Returns the business_id owned by the currently authenticated user
CREATE OR REPLACE FUNCTION auth.user_business_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.businesses WHERE owner_id = auth.uid() LIMIT 1;
$$;

-- Returns a set of branch_ids that the currently authenticated user has access to
-- (either as business owner or as assigned branch staff)
CREATE OR REPLACE FUNCTION auth.user_branch_ids()
RETURNS TABLE(branch_id text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- Branches owned via business
  SELECT b.id FROM public.branches b
  JOIN public.businesses biz ON b.business_id = biz.id
  WHERE biz.owner_id = auth.uid()
  UNION
  -- Branches assigned as staff
  SELECT s.branch_id FROM public.branch_staff s
  WHERE s.user_id = auth.uid() AND s.active = true;
$$;

-- ==============================================================================
-- 3. CORE IDENTITY & MULTI-TENANCY TABLES
-- ==============================================================================

-- USER ROLES [NEW]
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'carwash_owner', 'carwash_staff', 'admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_roles_user UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- BUSINESSES [NEW]
CREATE TABLE IF NOT EXISTS public.businesses (
    id TEXT PRIMARY KEY DEFAULT ('biz_' || substr(gen_random_uuid()::text, 1, 8)),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    name JSONB NOT NULL DEFAULT '{"ar": "", "en": ""}'::jsonb,
    legal_name TEXT,
    tax_number TEXT,
    commercial_reg_no TEXT,
    phone TEXT NOT NULL,
    email TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'suspended')),
    commission_rate NUMERIC(5,2) DEFAULT NULL CHECK (commission_rate IS NULL OR commission_rate >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_businesses_owner_id ON public.businesses(owner_id);
CREATE INDEX IF NOT EXISTS idx_businesses_status ON public.businesses(status);

-- CUSTOMERS [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.customers (
    id TEXT PRIMARY KEY, -- Maps to auth.users.id as string
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
    avatar_url TEXT,
    access_token TEXT,
    token_updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers(phone);

-- ==============================================================================
-- 4. BRANCHES & CATALOG TABLES
-- ==============================================================================

-- AREAS [EXISTING]
CREATE TABLE IF NOT EXISTS public.areas (
    id TEXT PRIMARY KEY,
    name JSONB NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- BRANCHES [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.branches (
    id TEXT PRIMARY KEY,
    business_id TEXT NOT NULL,
    area_id TEXT NOT NULL REFERENCES public.areas(id) ON DELETE RESTRICT,
    name JSONB NOT NULL,
    address JSONB NOT NULL,
    lat DOUBLE PRECISION NOT NULL,
    lng DOUBLE PRECISION NOT NULL,
    phone TEXT NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 4 CHECK (capacity > 0),
    featured BOOLEAN NOT NULL DEFAULT false,
    photo_seed INTEGER NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true,
    business_active BOOLEAN NOT NULL DEFAULT true,
    approval_status TEXT NOT NULL DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    logo_url TEXT,
    cover_image_url TEXT,
    working_hours JSONB NOT NULL DEFAULT '[]'::jsonb,
    amenities JSONB NOT NULL DEFAULT '[]'::jsonb,
    settings JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_branches_area_id ON public.branches(area_id);
CREATE INDEX IF NOT EXISTS idx_branches_business_id ON public.branches(business_id);
CREATE INDEX IF NOT EXISTS idx_branches_approval_status ON public.branches(approval_status);

-- BRANCH STAFF [NEW]
CREATE TABLE IF NOT EXISTS public.branch_staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'receptionist' CHECK (role IN ('manager', 'receptionist', 'technician')),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_branch_staff UNIQUE (branch_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_branch_staff_branch_id ON public.branch_staff(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_staff_user_id ON public.branch_staff(user_id);

-- SERVICES [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.services (
    id TEXT PRIMARY KEY,
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('primary', 'addon')),
    category TEXT NOT NULL,
    name JSONB NOT NULL,
    description JSONB NOT NULL,
    price INTEGER NOT NULL CHECK (price >= 0),
    duration_min INTEGER NOT NULL DEFAULT 30 CHECK (duration_min > 0),
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_services_branch_id ON public.services(branch_id);
CREATE INDEX IF NOT EXISTS idx_services_type_active ON public.services(type, active);

-- OFFERS [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.offers (
    id TEXT PRIMARY KEY,
    platform BOOLEAN NOT NULL DEFAULT false,
    branch_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    service_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    title JSONB NOT NULL,
    description JSONB NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
    discount_value INTEGER NOT NULL CHECK (discount_value > 0),
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'expired')),
    featured BOOLEAN NOT NULL DEFAULT false,
    photo_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- BRANCH SHARES [EXISTING]
CREATE TABLE IF NOT EXISTS public.branch_shares (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    user_id TEXT,
    platform TEXT DEFAULT 'native_share',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_branch_shares_branch_id ON public.branch_shares(branch_id);

-- ==============================================================================
-- 5. VEHICLES, BOOKINGS & ORDERS
-- ==============================================================================

-- VEHICLES [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.vehicles (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year INTEGER,
    color TEXT NOT NULL,
    plate TEXT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT false,
    vehicle_size TEXT NOT NULL DEFAULT 'sedan' CHECK (vehicle_size IN ('sedan', 'suv', 'truck', 'van', 'motorcycle')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_vehicles_customer_id ON public.vehicles(customer_id);

-- PAYOUTS [NEW] (defined before orders to allow orders.payout_id reference)
CREATE TABLE IF NOT EXISTS public.payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id TEXT NOT NULL,
    amount INTEGER NOT NULL CHECK (amount > 0),
    bank_account_id UUID,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    reference_number TEXT,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_by UUID REFERENCES auth.users(id),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_payouts_business_id ON public.payouts(business_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON public.payouts(status);

-- ORDERS [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    number TEXT NOT NULL UNIQUE,
    code TEXT NOT NULL,
    customer_id TEXT NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    vehicle_id TEXT REFERENCES public.vehicles(id) ON DELETE SET NULL,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    subtotal INTEGER NOT NULL CHECK (subtotal >= 0),
    discount INTEGER NOT NULL DEFAULT 0 CHECK (discount >= 0),
    offer_id TEXT,
    total INTEGER NOT NULL CHECK (total >= 0),
    duration_min INTEGER NOT NULL DEFAULT 30 CHECK (duration_min > 0),
    scheduled_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'waiting', 'in_service', 'completed', 'cancelled', 'no_show')),
    payment_status TEXT NOT NULL DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded')),
    payment_method TEXT NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'card_machine', 'online')),
    commission_amount INTEGER NOT NULL DEFAULT 0,
    payout_id UUID REFERENCES public.payouts(id) ON DELETE SET NULL,
    note TEXT,
    timeline JSONB NOT NULL DEFAULT '[]'::jsonb,
    cancel_reason TEXT,
    late_cancel BOOLEAN NOT NULL DEFAULT false,
    complaint_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_branch_id ON public.orders(branch_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_scheduled_at ON public.orders(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);

-- FAVORITES [EXISTING]
CREATE TABLE IF NOT EXISTS public.favorites (
    user_id TEXT NOT NULL,
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    PRIMARY KEY (user_id, branch_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_branch_id ON public.favorites(branch_id);

-- ==============================================================================
-- 6. FEEDBACK, DISPUTES & COMMISSIONS
-- ==============================================================================

-- REVIEWS [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.reviews (
    id TEXT PRIMARY KEY,
    order_id TEXT REFERENCES public.orders(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    branch_id TEXT NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    service_name JSONB NOT NULL,
    stars INTEGER NOT NULL CHECK (stars BETWEEN 1 AND 5),
    comment TEXT NOT NULL,
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    reply TEXT,
    status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'hidden')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_reviews_branch_id ON public.reviews(branch_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order_id ON public.reviews(order_id);

-- COMPLAINTS [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.complaints (
    id TEXT PRIMARY KEY,
    ticket_number TEXT NOT NULL UNIQUE,
    customer_id TEXT REFERENCES public.customers(id) ON DELETE SET NULL,
    order_id TEXT REFERENCES public.orders(id) ON DELETE SET NULL,
    reason TEXT,
    details TEXT,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'resolved', 'dismissed')),
    resolution_notes TEXT,
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_complaints_order_id ON public.complaints(order_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON public.complaints(status);

-- COMMISSIONS [NEW]
CREATE TABLE IF NOT EXISTS public.commissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id TEXT NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
    business_id TEXT NOT NULL,
    order_total INTEGER NOT NULL,
    rate_applied NUMERIC(5,2) NOT NULL,
    amount INTEGER NOT NULL,
    net_payout INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'settled', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_commissions_business_id ON public.commissions(business_id);
CREATE INDEX IF NOT EXISTS idx_commissions_order_id ON public.commissions(order_id);
CREATE INDEX IF NOT EXISTS idx_commissions_status ON public.commissions(status);

-- BUSINESS BANK ACCOUNTS [NEW]
CREATE TABLE IF NOT EXISTS public.business_bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id TEXT NOT NULL,
    bank_name TEXT NOT NULL,
    account_holder TEXT NOT NULL,
    account_number TEXT NOT NULL,
    iban TEXT NOT NULL,
    swift_code TEXT,
    is_primary BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 7. SYSTEM CONFIG, NOTIFICATIONS & AUDIT
-- ==============================================================================

-- PLATFORM SETTINGS [NEW]
CREATE TABLE IF NOT EXISTS public.platform_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- NOTIFICATIONS [EXISTING / MODIFIED]
CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL,
    title JSONB NOT NULL,
    body JSONB NOT NULL,
    order_id TEXT,
    read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);

-- USER PUSH TOKENS [NEW]
CREATE TABLE IF NOT EXISTS public.user_push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'android' CHECK (platform IN ('ios', 'android', 'web')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_push_token UNIQUE (user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_user_push_tokens_user_id ON public.user_push_tokens(user_id);

-- AUDIT LOGS [NEW]
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES auth.users(id),
    actor_role TEXT NOT NULL,
    action TEXT NOT NULL,
    target_entity TEXT NOT NULL,
    target_id TEXT,
    payload JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at);

-- APP HEALTH [EXISTING]
CREATE TABLE IF NOT EXISTS public.app_health (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name TEXT,
    status TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- ==============================================================================
-- 8. BUSINESS LOGIC TRIGGERS: AUTOMATIC COMMISSION GENERATION
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_order_completion_commission()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_business_id TEXT;
    v_rate NUMERIC(5,2);
    v_commission_amount INTEGER;
    v_net_payout INTEGER;
BEGIN
    -- Only trigger when order transitions to 'completed'
    IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed') THEN
        -- 1. Identify parent business ID from branch
        SELECT business_id INTO v_business_id
        FROM public.branches
        WHERE id = NEW.branch_id;

        -- 2. Lookup commission rate (business override or platform default)
        SELECT commission_rate INTO v_rate
        FROM public.businesses
        WHERE id = v_business_id;

        IF v_rate IS NULL THEN
            SELECT (value->>'percentage')::numeric INTO v_rate
            FROM public.platform_settings
            WHERE key = 'default_commission';
            
            IF v_rate IS NULL THEN
                v_rate := 15.00; -- Default fallback 15%
            END IF;
        END IF;

        -- 3. Calculate commission and net payout
        v_commission_amount := ROUND((NEW.total * v_rate) / 100.0);
        v_net_payout := NEW.total - v_commission_amount;

        -- Update order commission amount snapshot
        NEW.commission_amount := v_commission_amount;

        -- Insert commission ledger record
        INSERT INTO public.commissions (
            order_id,
            business_id,
            order_total,
            rate_applied,
            amount,
            net_payout,
            status
        ) VALUES (
            NEW.id,
            COALESCE(v_business_id, 'biz_default'),
            NEW.total,
            v_rate,
            v_commission_amount,
            v_net_payout,
            'pending'
        ) ON CONFLICT (order_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_order_commission ON public.orders;
CREATE TRIGGER trg_order_commission
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.handle_order_completion_commission();

-- ==============================================================================
-- 9. ROW-LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_health ENABLE ROW LEVEL SECURITY;

-- Areas Policies
DROP POLICY IF EXISTS "Public read areas" ON public.areas;
CREATE POLICY "Public read areas" ON public.areas FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Admin write areas" ON public.areas;
CREATE POLICY "Admin write areas" ON public.areas FOR ALL TO authenticated USING (auth.user_role() = 'admin');

-- Branches Policies
DROP POLICY IF EXISTS "Public read branches" ON public.branches;
CREATE POLICY "Public read branches" ON public.branches FOR SELECT TO anon, authenticated
USING (approval_status = 'approved' OR auth.user_role() = 'admin' OR id IN (SELECT auth.user_branch_ids()));

DROP POLICY IF EXISTS "Owner update branches" ON public.branches;
CREATE POLICY "Owner update branches" ON public.branches FOR UPDATE TO authenticated
USING (id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin')
WITH CHECK (id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

-- Services Policies
DROP POLICY IF EXISTS "Public read services" ON public.services;
CREATE POLICY "Public read services" ON public.services FOR SELECT TO anon, authenticated USING (active = true OR auth.user_role() = 'admin' OR branch_id IN (SELECT auth.user_branch_ids()));

DROP POLICY IF EXISTS "Owner write services" ON public.services;
CREATE POLICY "Owner write services" ON public.services FOR ALL TO authenticated
USING (branch_id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

-- Orders Policies
DROP POLICY IF EXISTS "Customer read own orders" ON public.orders;
CREATE POLICY "Customer read own orders" ON public.orders FOR SELECT TO authenticated
USING (customer_id = (SELECT auth.uid())::text OR branch_id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

DROP POLICY IF EXISTS "Customer insert orders" ON public.orders;
CREATE POLICY "Customer insert orders" ON public.orders FOR INSERT TO authenticated
WITH CHECK (customer_id = (SELECT auth.uid())::text);

DROP POLICY IF EXISTS "Staff and Admin update orders" ON public.orders;
CREATE POLICY "Staff and Admin update orders" ON public.orders FOR UPDATE TO authenticated
USING (customer_id = (SELECT auth.uid())::text OR branch_id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

-- Vehicles Policies
DROP POLICY IF EXISTS "Customer read own vehicles" ON public.vehicles;
CREATE POLICY "Customer read own vehicles" ON public.vehicles FOR SELECT TO authenticated
USING (customer_id = (SELECT auth.uid())::text OR auth.user_role() = 'admin');

DROP POLICY IF EXISTS "Customer write own vehicles" ON public.vehicles;
CREATE POLICY "Customer write own vehicles" ON public.vehicles FOR ALL TO authenticated
USING (customer_id = (SELECT auth.uid())::text OR auth.user_role() = 'admin')
WITH CHECK (customer_id = (SELECT auth.uid())::text OR auth.user_role() = 'admin');

-- Reviews Policies
DROP POLICY IF EXISTS "Public read reviews" ON public.reviews;
CREATE POLICY "Public read reviews" ON public.reviews FOR SELECT TO anon, authenticated USING (status = 'published' OR auth.user_role() = 'admin');

DROP POLICY IF EXISTS "Customer insert reviews" ON public.reviews;
CREATE POLICY "Customer insert reviews" ON public.reviews FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Staff reply reviews" ON public.reviews;
CREATE POLICY "Staff reply reviews" ON public.reviews FOR UPDATE TO authenticated
USING (branch_id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

-- Favorites Policies
DROP POLICY IF EXISTS "User manage favorites" ON public.favorites;
CREATE POLICY "User manage favorites" ON public.favorites FOR ALL TO authenticated
USING (user_id = (SELECT auth.uid())::text)
WITH CHECK (user_id = (SELECT auth.uid())::text);

-- Notifications Policies
DROP POLICY IF EXISTS "User read notifications" ON public.notifications;
CREATE POLICY "User read notifications" ON public.notifications FOR SELECT TO authenticated
USING (user_id = (SELECT auth.uid())::text OR auth.user_role() = 'admin');

DROP POLICY IF EXISTS "User update notifications" ON public.notifications;
CREATE POLICY "User update notifications" ON public.notifications FOR UPDATE TO authenticated
USING (user_id = (SELECT auth.uid())::text)
WITH CHECK (user_id = (SELECT auth.uid())::text);

-- App Health Policy
DROP POLICY IF EXISTS "Public read app_health" ON public.app_health;
CREATE POLICY "Public read app_health" ON public.app_health FOR SELECT TO anon, authenticated USING (true);

-- ==============================================================================
-- 10. REALTIME PUBLICATIONS
-- ==============================================================================

-- Enable realtime broadcasts for active dashboard and booking tables
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'orders'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'branches'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.branches;
    END IF;
END $$;

-- ==============================================================================
-- 11. SEED DATA FOR CONFIGURATION & DEFAULTS
-- ==============================================================================

INSERT INTO public.platform_settings (key, value, description, is_public) VALUES
('default_commission', '{"percentage": 15.00}'::jsonb, 'Default platform commission percentage charged per completed order', false),
('vat_rate', '{"percentage": 14.00, "enabled": false}'::jsonb, 'Egyptian Value Added Tax (VAT) rate', false),
('booking_rules', '{"lead_time_min": 15, "slot_interval_min": 30, "max_advance_days": 7, "free_cancel_min": 60}'::jsonb, 'System wide booking limits', true)
ON CONFLICT (key) DO NOTHING;
