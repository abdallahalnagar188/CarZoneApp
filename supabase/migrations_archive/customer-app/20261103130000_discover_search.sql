-- discover_branches also searches by branch or area name (Arabic or English),
-- so search covers every wash, not only the ones the app has loaded.
DROP FUNCTION IF EXISTS public.discover_branches(double precision, double precision, text, text, double precision, integer, integer);

CREATE OR REPLACE FUNCTION public.discover_branches(
  p_lat double precision,
  p_lng double precision,
  p_country text DEFAULT NULL,
  p_category text DEFAULT NULL,
  p_max_km double precision DEFAULT NULL,
  p_limit integer DEFAULT 20,
  p_offset integer DEFAULT 0,
  p_query text DEFAULT NULL
)
 RETURNS TABLE(branch jsonb, km double precision, from_price numeric, country_code text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  WITH q AS (SELECT nullif(trim(p_query), '') AS text),
  b AS (
    SELECT br.*, a.country_code AS area_country,
      6371 * 2 * asin(sqrt(
        power(sin(radians(br.lat - p_lat) / 2), 2)
        + cos(radians(p_lat)) * cos(radians(br.lat)) * power(sin(radians(br.lng - p_lng) / 2), 2)
      )) AS dist
    FROM public.branches br
    JOIN public.areas a ON a.id = br.area_id
    CROSS JOIN q
    WHERE br.active
      AND (p_country IS NULL OR a.country_code = p_country)
      AND (q.text IS NULL
        OR br.name ->> 'ar' ILIKE '%' || q.text || '%' OR br.name ->> 'en' ILIKE '%' || q.text || '%'
        OR a.name ->> 'ar' ILIKE '%' || q.text || '%' OR a.name ->> 'en' ILIKE '%' || q.text || '%')
  ),
  priced AS (
    SELECT b.*, (
      SELECT min(s.price) FROM public.services s
      WHERE s.branch_id = b.id AND s.active AND s.type = 'primary'
        AND (p_category IS NULL OR s.category_id = p_category)
    ) AS price
    FROM b
  )
  SELECT to_jsonb(p) - 'area_country' - 'dist' - 'price', p.dist, p.price, p.area_country
  FROM priced p
  WHERE (p_max_km IS NULL OR p.dist <= p_max_km)
    AND (p_category IS NULL OR p.price IS NOT NULL)
  ORDER BY p.dist
  LIMIT greatest(least(p_limit, 50), 1) OFFSET greatest(p_offset, 0);
$function$;
GRANT EXECUTE ON FUNCTION public.discover_branches(double precision, double precision, text, text, double precision, integer, integer, text) TO anon, authenticated;
