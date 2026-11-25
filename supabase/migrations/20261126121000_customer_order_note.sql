-- NOT APPLIED — to be reviewed and applied by the lead
--
-- GAP-035: the booking summary collects a note for the wash ("ring when you arrive"...) and
-- the app silently dropped it: create_order has no note parameter and customers cannot write
-- order_notes. Rather than redefining create_order (its live body was patched in place several
-- times), the app calls this small RPC right after create_order succeeds. The note lands in
-- order_notes with no staff author, where the partner portal and the owner app already list
-- an order's notes.
--
-- Rules: the caller must be an active customer (current_active_customer_id(), migration
-- 20261125140000) who owns the order; the order must still be pending or confirmed; 1-200
-- characters after trimming (the app's field allows 200); at most 3 customer notes per order.
--
-- The app treats a missing function (PostgREST PGRST202) as "notes not supported yet" and
-- tells the customer the note was not sent, so it is safe to ship the app first.
--
-- Idempotent: CREATE OR REPLACE + explicit grants.

create or replace function public.add_customer_order_note(p_order_id text, p_note text)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_customer text := public.current_active_customer_id();
  v_order public.orders%rowtype;
  v_text text := btrim(coalesce(p_note, ''));
begin
  if v_customer is null then
    raise exception 'account_suspended';
  end if;
  if char_length(v_text) = 0 or char_length(v_text) > 200 then
    raise exception 'invalid_note';
  end if;

  select * into v_order from public.orders where id = p_order_id and customer_id = v_customer;
  if not found then
    raise exception 'order_not_found';
  end if;
  if v_order.status not in ('pending', 'confirmed') then
    raise exception 'order_not_editable';
  end if;

  if (select count(*) from public.order_notes n
      where n.order_id = v_order.id and n.author_staff_id is null and n.text like 'ملاحظة العميل%') >= 3 then
    raise exception 'too_many_notes';
  end if;

  -- Marked as the customer's: order_notes has no author type, and a null staff author is
  -- otherwise an admin note (vendor/server/platform-api/pg/admin/orders.ts).
  insert into public.order_notes (order_id, author_staff_id, text)
  values (v_order.id, null, 'ملاحظة العميل / Customer note: ' || v_text);
end;
$function$;

revoke all on function public.add_customer_order_note(text, text) from public, anon;
grant execute on function public.add_customer_order_note(text, text) to authenticated;
