-- Live order updates: when a wash changes a booking (vendor dashboard), the
-- customer app and its live booking widget update without a refresh.
-- 20261015140200 meant to enable this but never reached the remote database.
-- Realtime applies each table's RLS, so customers only receive their own rows.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'customer_notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.customer_notifications;
  END IF;
END $$;
