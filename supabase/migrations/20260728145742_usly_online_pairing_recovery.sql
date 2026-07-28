-- Recovery for pending pairing plus explicit shared vote progress.
-- Applied to project vgmahkbiwxklefxxdsix.

alter table public.weekly_syncs
  add column vote_count smallint not null default 0
  check (vote_count between 0 and 2);

create or replace function app_private.refresh_pairing_code()
returns table (couple_id uuid, pairing_code text, expires_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_couple_id uuid;
  v_code text;
  v_expires_at timestamptz := now() + interval '20 minutes';
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select couple.id
  into v_couple_id
  from public.couples couple
  join public.couple_members member on member.couple_id = couple.id
  where member.user_id = v_user_id
    and member.status = 'active'
    and couple.created_by = v_user_id
    and couple.status = 'pending'
  limit 1;

  if v_couple_id is null then
    raise exception 'pending_pairing_not_found' using errcode = '22023';
  end if;

  update public.pairing_invitations
  set revoked_at = now()
  where public.pairing_invitations.couple_id = v_couple_id
    and accepted_at is null
    and revoked_at is null;

  loop
    v_code := upper(substr(encode(extensions.gen_random_bytes(5), 'hex'), 1, 8));
    begin
      insert into public.pairing_invitations (
        couple_id, inviter_user_id, token_hash, expires_at
      )
      values (
        v_couple_id,
        v_user_id,
        encode(extensions.digest(v_code, 'sha256'), 'hex'),
        v_expires_at
      );
      exit;
    exception when unique_violation then
      null;
    end;
  end loop;

  return query select v_couple_id, v_code, v_expires_at;
end
$$;

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
        vote_count = v_vote_count,
        selected_option_id = v_selected,
        updated_at = now()
    where id = p_weekly_sync_id;
  else
    update public.weekly_syncs
    set status = 'voting',
        vote_count = v_vote_count,
        selected_option_id = null,
        updated_at = now()
    where id = p_weekly_sync_id;
    v_selected := null;
  end if;

  return query select v_selected is not null, v_selected;
end
$$;

create or replace function public.refresh_pairing_code()
returns table (couple_id uuid, pairing_code text, expires_at timestamptz)
language sql
security invoker
set search_path = ''
as $$
  select * from app_private.refresh_pairing_code()
$$;

revoke execute on function app_private.refresh_pairing_code()
  from public, anon;
grant execute on function app_private.refresh_pairing_code()
  to authenticated;

revoke execute on function public.refresh_pairing_code()
  from public, anon;
grant execute on function public.refresh_pairing_code()
  to authenticated;
