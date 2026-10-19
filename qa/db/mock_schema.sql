-- Minimal stand-in for the live CarZone schema, built from supabase/database.types.ts,
-- so migrations can be tested in PGlite before they reach Supabase.
-- Only what the customer-app migrations touch is modelled. Not a source of truth.

-- Supabase roles and auth -----------------------------------------------------
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE SCHEMA auth;
GRANT USAGE ON SCHEMA auth TO anon, authenticated;
CREATE TABLE auth.users (id uuid PRIMARY KEY, phone text, email text);
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
  $$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
GRANT EXECUTE ON FUNCTION auth.uid() TO anon, authenticated;

-- Enums -------------------------------------------------------------------------
CREATE TYPE account_status AS ENUM ('active', 'suspended');
CREATE TYPE actor_type AS ENUM ('customer', 'staff', 'admin', 'system');
CREATE TYPE business_status AS ENUM ('pending', 'approved', 'active', 'suspended', 'rejected');
CREATE TYPE discount_type AS ENUM ('percent', 'fixed');
CREATE TYPE offer_scope AS ENUM ('platform', 'wash');
CREATE TYPE offer_status AS ENUM ('draft', 'scheduled', 'active', 'expired', 'disabled');
CREATE TYPE order_payment_status AS ENUM ('pending', 'paid', 'refunded');
CREATE TYPE order_source AS ENUM ('app', 'walk_in', 'phone');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'waiting', 'in_service', 'completed', 'cancelled', 'no_show');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'online');
CREATE TYPE review_status AS ENUM ('visible', 'hidden');
CREATE TYPE service_type AS ENUM ('primary', 'addon');

-- Helper functions that exist live ---------------------------------------------
CREATE FUNCTION public.gen_id(prefix text) RETURNS text LANGUAGE sql VOLATILE AS
  $$ SELECT prefix || '_' || substr(md5(random()::text || clock_timestamp()::text), 1, 12) $$;
CREATE FUNCTION public.gen_check_in_code() RETURNS text LANGUAGE sql VOLATILE AS
  $$ SELECT upper(substr(md5(random()::text), 1, 5)) $$;
CREATE FUNCTION public.normalize_plate(plate text) RETURNS text LANGUAGE sql IMMUTABLE AS
  $$ SELECT upper(regexp_replace(plate, '\s', '', 'g')) $$;
CREATE FUNCTION public.is_localized(value jsonb) RETURNS boolean LANGUAGE sql IMMUTABLE AS
  $$ SELECT value ? 'ar' AND value ? 'en' $$;
CREATE SEQUENCE public.order_number_seq START 20001;
CREATE FUNCTION public.next_order_number(src order_source) RETURNS text LANGUAGE sql VOLATILE AS
  $$ SELECT 'CZ-' || nextval('public.order_number_seq') $$;
CREATE SEQUENCE public.complaint_ticket_seq START 1001;
CREATE FUNCTION public.next_complaint_ticket() RETURNS text LANGUAGE sql VOLATILE AS
  $$ SELECT 'TK-' || nextval('public.complaint_ticket_seq') $$;

-- Tables --------------------------------------------------------------------------
CREATE TABLE public.areas (id text PRIMARY KEY, name jsonb NOT NULL DEFAULT '{}', active boolean NOT NULL DEFAULT true);
CREATE TABLE public.businesses (
  id text PRIMARY KEY, name jsonb NOT NULL DEFAULT '{}', status business_status NOT NULL DEFAULT 'active',
  commission_rate numeric, owner_staff_id text, rating numeric NOT NULL DEFAULT 0, status_reason text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.branches (
  id text PRIMARY KEY, business_id text NOT NULL REFERENCES public.businesses(id), name jsonb NOT NULL DEFAULT '{}',
  area_id text NOT NULL DEFAULT 'nasr', address jsonb NOT NULL DEFAULT '{}', lat numeric NOT NULL DEFAULT 30, lng numeric NOT NULL DEFAULT 31,
  phone text NOT NULL DEFAULT '', capacity int NOT NULL DEFAULT 2, active boolean NOT NULL DEFAULT true, featured boolean NOT NULL DEFAULT false,
  auto_confirm boolean NOT NULL DEFAULT false, slot_interval_min int NOT NULL DEFAULT 30, lead_time_min int NOT NULL DEFAULT 15,
  max_advance_days int NOT NULL DEFAULT 7, free_cancel_min int NOT NULL DEFAULT 60, no_show_grace_min int NOT NULL DEFAULT 15,
  reminder_min int NOT NULL DEFAULT 45, rating numeric NOT NULL DEFAULT 0, review_count int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.branch_photos (id text PRIMARY KEY, branch_id text NOT NULL, storage_path text, position int DEFAULT 0);
CREATE TABLE public.amenities (id text PRIMARY KEY, name jsonb DEFAULT '{}', active boolean NOT NULL DEFAULT true);
CREATE TABLE public.branch_amenities (branch_id text NOT NULL, amenity_id text NOT NULL);
CREATE TABLE public.branch_working_hours (
  branch_id text NOT NULL REFERENCES public.branches(id), weekday int NOT NULL,
  opens_at time NOT NULL, closes_at time NOT NULL, closed boolean NOT NULL DEFAULT false,
  PRIMARY KEY (branch_id, weekday)
);
CREATE TABLE public.branch_blocked_slots (
  id text PRIMARY KEY DEFAULT public.gen_id('blk'), branch_id text NOT NULL, starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL, reason text NOT NULL DEFAULT '', created_by text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.service_categories (id text PRIMARY KEY, name jsonb DEFAULT '{}', active boolean NOT NULL DEFAULT true);
CREATE TABLE public.services (
  id text PRIMARY KEY, branch_id text NOT NULL REFERENCES public.branches(id), type service_type NOT NULL,
  category_id text NOT NULL, name jsonb NOT NULL DEFAULT '{"ar":"","en":""}', description jsonb,
  price numeric(10,2) NOT NULL, duration_min int NOT NULL, active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.offers (
  id text PRIMARY KEY, scope offer_scope NOT NULL DEFAULT 'wash', business_id text, title jsonb NOT NULL DEFAULT '{}',
  description jsonb NOT NULL DEFAULT '{}', discount_type discount_type NOT NULL, discount_value numeric NOT NULL,
  starts_at timestamptz NOT NULL, ends_at timestamptz NOT NULL, status offer_status NOT NULL DEFAULT 'active',
  featured boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.offer_branches (offer_id text NOT NULL, branch_id text NOT NULL);
CREATE TABLE public.offer_categories (offer_id text NOT NULL, category_id text NOT NULL);
CREATE TABLE public.customers (
  id text PRIMARY KEY DEFAULT public.gen_id('cu'), user_id uuid, name text NOT NULL, phone text NOT NULL,
  locale text NOT NULL DEFAULT 'ar', status account_status NOT NULL DEFAULT 'active', status_reason text,
  last_active_at timestamptz NOT NULL DEFAULT now(), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.vehicles (
  id text PRIMARY KEY DEFAULT public.gen_id('veh'), customer_id text NOT NULL REFERENCES public.customers(id),
  make text NOT NULL, model text NOT NULL, year int, color text NOT NULL, plate text NOT NULL, plate_normalized text,
  is_default boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.orders (
  id text PRIMARY KEY DEFAULT public.gen_id('ord'), number text NOT NULL UNIQUE, code text NOT NULL DEFAULT public.gen_check_in_code(),
  source order_source NOT NULL, customer_id text, vehicle_id text, plate text NOT NULL, plate_normalized text,
  business_id text NOT NULL, branch_id text NOT NULL REFERENCES public.branches(id), offer_id text,
  subtotal numeric(10,2) NOT NULL, discount_amount numeric(10,2), discount_pct numeric, discount_reason text, total numeric(10,2) NOT NULL,
  duration_min int NOT NULL, scheduled_at timestamptz NOT NULL, status order_status NOT NULL DEFAULT 'pending',
  payment_status order_payment_status NOT NULL DEFAULT 'pending', payment_method payment_method,
  cancel_reason text, cancelled_at timestamptz, cancelled_by_id text, cancelled_by_type actor_type,
  assigned_staff_id text, closed_in_day_id text, flag text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.order_items (
  id text PRIMARY KEY DEFAULT public.gen_id('oi'), order_id text NOT NULL REFERENCES public.orders(id), service_id text,
  name jsonb NOT NULL, type service_type NOT NULL, price numeric(10,2) NOT NULL, duration_min int NOT NULL, position int NOT NULL DEFAULT 0
);
CREATE TABLE public.order_events (
  id text PRIMARY KEY DEFAULT public.gen_id('oev'), order_id text NOT NULL REFERENCES public.orders(id),
  status order_status NOT NULL, actor_type actor_type NOT NULL, actor_id text NOT NULL, at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.reviews (id text PRIMARY KEY, customer_id text, branch_id text, status review_status NOT NULL DEFAULT 'visible');
CREATE TABLE public.customer_favorites (customer_id text NOT NULL, branch_id text NOT NULL, PRIMARY KEY (customer_id, branch_id));
CREATE TABLE public.customer_notifications (id text PRIMARY KEY, customer_id text NOT NULL, read boolean NOT NULL DEFAULT false);
CREATE TABLE public.complaints (id text PRIMARY KEY, customer_id text);
CREATE TABLE public.push_devices (id text PRIMARY KEY DEFAULT public.gen_id('pd'), user_id uuid NOT NULL, token text NOT NULL);
CREATE TABLE public.legacy_branch_shares (id uuid PRIMARY KEY, branch_id text, user_id text, platform text, created_at timestamptz DEFAULT now());
CREATE TABLE public.staff (id text PRIMARY KEY, user_id uuid, branch_id text, business_id text, role text DEFAULT 'employee');
CREATE TABLE public.admin_users (id text PRIMARY KEY, user_id uuid, email text);

DO $$
DECLARE t text;
BEGIN
  FOR t IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

-- What the vendor panel relies on today (simulated): staff read/update their branch orders.
GRANT SELECT ON public.staff, public.admin_users TO authenticated;
CREATE POLICY "Staff read self" ON public.staff FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Staff read branch orders" ON public.orders FOR SELECT TO authenticated
  USING (branch_id IN (SELECT branch_id FROM public.staff WHERE user_id = auth.uid()));
CREATE POLICY "Staff update branch orders" ON public.orders FOR UPDATE TO authenticated
  USING (branch_id IN (SELECT branch_id FROM public.staff WHERE user_id = auth.uid()))
  WITH CHECK (branch_id IN (SELECT branch_id FROM public.staff WHERE user_id = auth.uid()));

-- A leftover permissive policy like the one in migration 20261015140100, in case it was applied live.
CREATE POLICY "Staff and Admin update orders" ON public.orders FOR UPDATE TO authenticated
  USING (customer_id = (SELECT auth.uid())::text);
