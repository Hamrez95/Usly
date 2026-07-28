-- PostgreSQL does not define min(uuid); select the first vote deterministically.
-- This migration preserves the public RPC signature.

create or replace function app_private.vote_weekly_option(
  p_weekly_sync_id uuid,
  p_option_id uuid
)
returns table (matched boolean, selected_option_id uuid)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_couple_id uuid;
  v_vote_count integer;
  v_distinct_options integer;
  v_selected uuid;
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select sync.couple_id
  into v_couple_id
  from public.weekly_syncs sync
  where sync.id = p_weekly_sync_id
  for update;

  if v_couple_id is null
     or not app_private.is_active_member(v_couple_id, v_user_id) then
    raise exception 'weekly_sync_not_accessible' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.weekly_options option
    where option.weekly_sync_id = p_weekly_sync_id
      and option.id = p_option_id
  ) then
    raise exception 'option_not_found' using errcode = '22023';
  end if;

  insert into public.weekly_votes (weekly_sync_id, user_id, option_id)
  values (p_weekly_sync_id, v_user_id, p_option_id)
  on conflict (weekly_sync_id, user_id) do update
    set option_id = excluded.option_id,
        voted_at = now();

  select
    count(*),
    count(distinct vote.option_id),
    (array_agg(vote.option_id order by vote.voted_at))[1]
  into v_vote_count, v_distinct_options, v_selected
  from public.weekly_votes vote
  where vote.weekly_sync_id = p_weekly_sync_id;

  if v_vote_count = 2 and v_distinct_options = 1 then
    update public.weekly_syncs
    set status = 'selected',
        selected_option_id = v_selected,
        updated_at = now()
    where id = p_weekly_sync_id;
  else
    update public.weekly_syncs
    set status = 'voting',
        selected_option_id = null,
        updated_at = now()
    where id = p_weekly_sync_id;
    v_selected := null;
  end if;

  return query select v_selected is not null, v_selected;
end
$$;

revoke execute on function app_private.vote_weekly_option(uuid, uuid)
  from public, anon;
grant execute on function app_private.vote_weekly_option(uuid, uuid)
  to authenticated;
