insert into public.payouts (id, business_id, period_start, period_end, amount_due, amount_paid, status, reference, paid_at) values
  ('po_1', 'biz_carzen', '2026-09-14', '2026-09-28', 4200, 4200, 'paid', 'TRX-88421', '2026-10-01T09:00:00.000Z'),
  ('po_2', 'biz_pyramid', '2026-09-29', '2026-10-13', 1800, 0, 'due', null, null),
  ('po_3', 'biz_nile', '2026-09-29', '2026-10-13', 2650, 0, 'due', null, null),
  ('po_4', 'biz_palm', '2026-09-14', '2026-09-28', 3120, 3120, 'paid', 'TRX-88437', '2026-10-02T12:00:00.000Z'),
  ('po_5', 'biz_oasis', '2026-09-29', '2026-10-13', 1975, 0, 'due', null, null);

-- reviews: 120 rows