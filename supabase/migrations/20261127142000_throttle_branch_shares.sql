-- GAP-062 (system audit), part 1: anonymous share events were unthrottled.
--
-- The customer app records a row in branch_shares each time someone shares a wash (fire-and-forget, errors only
-- logged). anon and authenticated may insert directly, so a script could fill the table. Now:
--   * a BEFORE INSERT trigger silently drops (returns NULL, the client still gets a success) a row beyond
--     60 guest shares per branch per hour, or 20 shares per signed-in user per branch per hour
--     (production on 2026-11-26: 10 rows in total, at most 4 per branch per hour);
--   * "platform" is limited to 32 characters (today only 'native_share' is used).
-- The trigger function is SECURITY DEFINER because anon cannot read the table it counts.
--
-- Verify (rolled back): 61 guest inserts for one branch as anon → 60 rows.

create or replace function public.branch_shares_throttle()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
begin
  if new.user_id is null then
    if (select count(*) from public.branch_shares s
        where s.branch_id = new.branch_id and s.user_id is null and s.created_at > now() - interval '1 hour') >= 60 then
      return null;
    end if;
  elsif (select count(*) from public.branch_shares s
         where s.branch_id = new.branch_id and s.user_id = new.user_id and s.created_at > now() - interval '1 hour') >= 20 then
    return null;
  end if;
  return new;
end;
$function$;

revoke all on function public.branch_shares_throttle() from public, anon, authenticated, service_role, washup_vendor_panel;

create index if not exists branch_shares_branch_created_idx on public.branch_shares (branch_id, created_at);

drop trigger if exists trg_branch_shares_throttle on public.branch_shares;
create trigger trg_branch_shares_throttle
  before insert on public.branch_shares
  for each row execute function public.branch_shares_throttle();

alter table public.branch_shares
  add constraint branch_shares_platform_length check (platform is null or char_length(platform) <= 32);
