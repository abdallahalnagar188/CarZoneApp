-- Plate search ignores digit style and Arabic letter forms, as the app does:
-- "ب ع ج ٧٧٨٨" and "ب ع ج 7788" are the same plate. The stored
-- plate_normalized columns are rebuilt (drop and re-add) so existing rows use
-- the new spelling without firing the orders triggers.
CREATE OR REPLACE FUNCTION public.normalize_plate(plate text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  -- One spelling per plate: no spaces, dashes, dots or underscores; Arabic-Indic
  -- and Persian digits as 0-9; أ إ آ → ا, ى → ي, ة → ه; Latin in capitals.
  -- Matches FormatHelper.normalizePlate in the customer app.
  select upper(translate(
    regexp_replace(coalesce(plate, ''), '[\s\-_.]', '', 'g'),
    '٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹أإآىة',
    '01234567890123456789اااية'
  ));
$function$;

ALTER TABLE public.vehicles DROP COLUMN plate_normalized;
ALTER TABLE public.vehicles ADD COLUMN plate_normalized text GENERATED ALWAYS AS (public.normalize_plate(plate)) STORED;
CREATE UNIQUE INDEX vehicles_customer_plate_unique ON public.vehicles USING btree (customer_id, plate_normalized);
CREATE INDEX vehicles_plate_idx ON public.vehicles USING btree (plate_normalized);

ALTER TABLE public.orders DROP COLUMN plate_normalized;
ALTER TABLE public.orders ADD COLUMN plate_normalized text GENERATED ALWAYS AS (public.normalize_plate(plate)) STORED;
CREATE INDEX orders_plate_idx ON public.orders USING btree (plate_normalized);
