-- ==============================================================================
-- Migration: 20261015140100_security_and_rls_hardening.sql
-- Description: Hardens Row-Level Security (RLS) by revoking wide-open
--              "ALL: true" policies and implementing role-based access control.
-- DO NOT APPLY DIRECTLY - REVIEW FIRST.
-- ==============================================================================

-- 1. HELPER FUNCTIONS FOR RLS
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

CREATE OR REPLACE FUNCTION auth.user_business_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.businesses WHERE owner_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION auth.user_branch_ids()
RETURNS TABLE(branch_id text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT b.id FROM public.branches b
  JOIN public.businesses biz ON b.business_id = biz.id
  WHERE biz.owner_id = auth.uid()
  UNION
  SELECT s.branch_id FROM public.branch_staff s
  WHERE s.user_id = auth.uid() AND s.active = true;
$$;

-- 2. AUTOMATIC COMMISSION GENERATION TRIGGER
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
    IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed') THEN
        SELECT business_id INTO v_business_id
        FROM public.branches
        WHERE id = NEW.branch_id;

        SELECT commission_rate INTO v_rate
        FROM public.businesses
        WHERE id = v_business_id;

        IF v_rate IS NULL THEN
            SELECT (value->>'percentage')::numeric INTO v_rate
            FROM public.platform_settings
            WHERE key = 'default_commission';
            
            IF v_rate IS NULL THEN
                v_rate := 15.00;
            END IF;
        END IF;

        v_commission_amount := ROUND((NEW.total * v_rate) / 100.0);
        v_net_payout := NEW.total - v_commission_amount;

        NEW.commission_amount := v_commission_amount;

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

-- 3. REVOKE INSECURE "ALL: TRUE" POLICIES
DROP POLICY IF EXISTS "Public write areas" ON public.areas;
DROP POLICY IF EXISTS "Public write branches" ON public.branches;
DROP POLICY IF EXISTS "Public write services" ON public.services;
DROP POLICY IF EXISTS "Public write offers" ON public.offers;
DROP POLICY IF EXISTS "Public write customers" ON public.customers;
DROP POLICY IF EXISTS "Public write vehicles" ON public.vehicles;
DROP POLICY IF EXISTS "Public write orders" ON public.orders;
DROP POLICY IF EXISTS "Public write reviews" ON public.reviews;
DROP POLICY IF EXISTS "Public write notifications" ON public.notifications;
DROP POLICY IF EXISTS "Public write favorites" ON public.favorites;
DROP POLICY IF EXISTS "Public write complaints" ON public.complaints;

-- 4. INSTALL HARDENED PRODUCTION POLICIES

-- BRANCHES
DROP POLICY IF EXISTS "Public read branches" ON public.branches;
CREATE POLICY "Public read branches" ON public.branches FOR SELECT TO anon, authenticated
USING (approval_status = 'approved' OR auth.user_role() = 'admin' OR id IN (SELECT auth.user_branch_ids()));

DROP POLICY IF EXISTS "Owner update branches" ON public.branches;
CREATE POLICY "Owner update branches" ON public.branches FOR UPDATE TO authenticated
USING (id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin')
WITH CHECK (id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

-- SERVICES
DROP POLICY IF EXISTS "Public read services" ON public.services;
CREATE POLICY "Public read services" ON public.services FOR SELECT TO anon, authenticated
USING (active = true OR auth.user_role() = 'admin' OR branch_id IN (SELECT auth.user_branch_ids()));

DROP POLICY IF EXISTS "Owner write services" ON public.services;
CREATE POLICY "Owner write services" ON public.services FOR ALL TO authenticated
USING (branch_id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

-- ORDERS
DROP POLICY IF EXISTS "Customer read own orders" ON public.orders;
CREATE POLICY "Customer read own orders" ON public.orders FOR SELECT TO authenticated
USING (customer_id = (SELECT auth.uid())::text OR branch_id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

DROP POLICY IF EXISTS "Customer insert orders" ON public.orders;
CREATE POLICY "Customer insert orders" ON public.orders FOR INSERT TO authenticated
WITH CHECK (customer_id = (SELECT auth.uid())::text);

DROP POLICY IF EXISTS "Staff and Admin update orders" ON public.orders;
CREATE POLICY "Staff and Admin update orders" ON public.orders FOR UPDATE TO authenticated
USING (customer_id = (SELECT auth.uid())::text OR branch_id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');

-- VEHICLES
DROP POLICY IF EXISTS "Customer read own vehicles" ON public.vehicles;
CREATE POLICY "Customer read own vehicles" ON public.vehicles FOR SELECT TO authenticated
USING (customer_id = (SELECT auth.uid())::text OR auth.user_role() = 'admin');

DROP POLICY IF EXISTS "Customer write own vehicles" ON public.vehicles;
CREATE POLICY "Customer write own vehicles" ON public.vehicles FOR ALL TO authenticated
USING (customer_id = (SELECT auth.uid())::text OR auth.user_role() = 'admin')
WITH CHECK (customer_id = (SELECT auth.uid())::text OR auth.user_role() = 'admin');

-- REVIEWS
DROP POLICY IF EXISTS "Public read reviews" ON public.reviews;
CREATE POLICY "Public read reviews" ON public.reviews FOR SELECT TO anon, authenticated
USING (status = 'published' OR auth.user_role() = 'admin');

DROP POLICY IF EXISTS "Staff reply reviews" ON public.reviews;
CREATE POLICY "Staff reply reviews" ON public.reviews FOR UPDATE TO authenticated
USING (branch_id IN (SELECT auth.user_branch_ids()) OR auth.user_role() = 'admin');
