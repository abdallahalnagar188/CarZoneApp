-- ==============================================================================
-- Migration: 20261015140000_multi_tenant_and_roles_schema.sql
-- Description: Introduces multi-tenancy, partner business entities, branch staff,
--              financial commissions, payouts, and platform settings.
-- DO NOT APPLY DIRECTLY - REVIEW FIRST.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. USER ROLES [NEW]
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer', 'carwash_owner', 'carwash_staff', 'admin')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_roles_user UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role);

-- 3. BUSINESSES [NEW] (Parent legal entity for car wash branches)
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

-- 4. BRANCH STAFF [NEW]
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

-- 5. BUSINESS BANK ACCOUNTS [NEW]
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

-- 6. PAYOUTS [NEW]
CREATE TABLE IF NOT EXISTS public.payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id TEXT NOT NULL,
    amount INTEGER NOT NULL CHECK (amount > 0),
    bank_account_id UUID REFERENCES public.business_bank_accounts(id),
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

-- 7. COMMISSIONS [NEW]
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

-- 8. PLATFORM SETTINGS [NEW]
CREATE TABLE IF NOT EXISTS public.platform_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN NOT NULL DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 9. USER PUSH TOKENS [NEW] (For Firebase Cloud Messaging)
CREATE TABLE IF NOT EXISTS public.user_push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'android' CHECK (platform IN ('ios', 'android', 'web')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_user_push_token UNIQUE (user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_user_push_tokens_user_id ON public.user_push_tokens(user_id);

-- 10. AUDIT LOGS [NEW]
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

-- 11. MODIFY EXISTING TABLES (NON-DESTRUCTIVE ADDITIONS)
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended'));
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS avatar_url TEXT;

ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS approval_status TEXT NOT NULL DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected'));
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.branches ADD COLUMN IF NOT EXISTS cover_image_url TEXT;

ALTER TABLE public.vehicles ADD COLUMN IF NOT EXISTS vehicle_size TEXT NOT NULL DEFAULT 'sedan' CHECK (vehicle_size IN ('sedan', 'suv', 'truck', 'van', 'motorcycle'));

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'card_machine', 'online'));
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS commission_amount INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payout_id UUID REFERENCES public.payouts(id) ON DELETE SET NULL;

ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'hidden'));

ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS resolution_notes TEXT;
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS resolved_by UUID REFERENCES auth.users(id);
ALTER TABLE public.complaints ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;
