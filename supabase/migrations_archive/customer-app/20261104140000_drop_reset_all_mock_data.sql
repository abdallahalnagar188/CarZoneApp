-- reset_all_mock_data() truncated every production table (orders, customers,
-- washes, payments). Nothing calls it, and the portals' service role could run
-- it, so it goes.
DROP FUNCTION public.reset_all_mock_data();
