-- ==============================================================================
-- Migration: 20261015140200_realtime_and_indexes.sql
-- Description: Adds covering indexes on foreign keys and ordering columns,
--              and enables Supabase Realtime broadcast for dashboards.
-- DO NOT APPLY DIRECTLY - REVIEW FIRST.
-- ==============================================================================

-- 1. COVERING INDEXES (Addressed from Supabase Performance Advisories)
CREATE INDEX IF NOT EXISTS idx_branch_shares_branch_id ON public.branch_shares(branch_id);
CREATE INDEX IF NOT EXISTS idx_favorites_branch_id ON public.favorites(branch_id);

-- 2. QUERY & ORDERING PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_orders_scheduled_at ON public.orders(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_number ON public.orders(number);

CREATE INDEX IF NOT EXISTS idx_reviews_order_id ON public.reviews(order_id);

CREATE INDEX IF NOT EXISTS idx_complaints_order_id ON public.complaints(order_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_complaints_ticket_number ON public.complaints(ticket_number);

CREATE INDEX IF NOT EXISTS idx_services_type_active ON public.services(type, active);

-- 3. ENABLE SUPABASE REALTIME BROADCASTS
-- Grants real-time websocket pushes for incoming orders, notifications, and branch status changes
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
