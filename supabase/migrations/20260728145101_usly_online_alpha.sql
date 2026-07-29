-- Usly online alpha schema.
-- Target project: vgmahkbiwxklefxxdsix (Usly).
-- Raw weekly answers and votes are owner-readable only. Shared suggestions and
-- match state are derived server-side without exposing either partner's input.

create extension if not exists pgcrypto;
create schema if not exists app_private;

revoke all on schema app_private from public, anon, authenticated;
grant usage on schema app_private to authenticated;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (
    display_name is null
    or char_length(btrim(display_name)) between 1 and 40
  ),
  locale text not null default 'fa' check (locale in ('fa', 'en')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.couples (
  id uuid primary key default extensions.gen_random_uuid(),
  status text not null default 'pending'
    check (status in ('pending', 'active', 'paused', 'disconnected')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  disconnected_at timestamptz
);

create table public.couple_members (
  couple_id uuid not null references public.couples(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'left')),
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (couple_id, user_id)
);

create unique index one_active_couple_per_user
  on public.couple_members(user_id)
  where status = 'active';

create table public.pairing_invitations (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  inviter_user_id uuid not null references auth.users(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index pairing_invitations_active_lookup
  on public.pairing_invitations(token_hash, expires_at)
  where accepted_at is null and revoked_at is null;

create table public.weekly_syncs (
  id uuid primary key default extensions.gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  week_start date not null,
  status text not null default 'collecting'
    check (status in ('collecting', 'ready', 'voting', 'selected', 'completed', 'skipped')),
  response_count smallint not null default 0 check (response_count between 0 and 2),
  selected_option_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (couple_id, week_start)
);

create table public.weekly_sync_responses (
  weekly_sync_id uuid not null references public.weekly_syncs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  energy_level smallint not null check (energy_level between 1 and 5),
  need_category text not null
    check (need_category in ('calm', 'fun', 'conversation', 'novelty', 'support', 'play')),
  duration_band text not null check (duration_band in ('short', 'medium', 'long')),
  budget_band text not null check (budget_band in ('free', 'low', 'medium')),
  setting_band text not null check (setting_band in ('home', 'outside', 'either')),
  submitted_at timestamptz not null default now(),
  primary key (weekly_sync_id, user_id)
);

create table public.weekly_options (
  id uuid primary key default extensions.gen_random_uuid(),
  weekly_sync_id uuid not null references public.weekly_syncs(id) on delete cascade,
  rank smallint not null check (rank between 1 and 3),
  kind text not null check (kind in ('easy', 'balanced', 'different')),
  title_fa text not null,
  duration_fa text not null,
  budget_fa text not null,
  setting_fa text not null,
  reason_fa text not null,
  instructions_fa text not null,
  created_at timestamptz not null default now(),
  unique (weekly_sync_id, rank),
  unique (weekly_sync_id, id)
);

alter table public.weekly_syncs
  add constraint weekly_syncs_selected_option_fk
  foreign key (id, selected_option_id)
  references public.weekly_options(weekly_sync_id, id)
  deferrable initially deferred;

create table public.weekly_votes (
  weekly_sync_id uuid not null references public.weekly_syncs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  option_id uuid not null,
  voted_at timestamptz not null default now(),
  primary key (weekly_sync_id, user_id),
  foreign key (weekly_sync_id, option_id)
    references public.weekly_options(weekly_sync_id, id)
    on delete cascade
);

create or replace function app_private.current_user_id()
returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select auth.uid()
$$;

create or replace function app_private.is_active_member(
  p_couple_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.couple_members member
    where member.couple_id = p_couple_id
      and member.user_id = p_user_id
      and member.status = 'active'
  )
$$;

create or replace function app_private.shares_active_couple(
  p_target_user_id uuid,
  p_viewer_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_target_user_id = p_viewer_user_id
    or exists (
      select 1
      from public.couple_members viewer
      join public.couple_members target
        on target.couple_id = viewer.couple_id
      where viewer.user_id = p_viewer_user_id
        and target.user_id = p_target_user_id
        and viewer.status = 'active'
        and target.status = 'active'
    )
$$;

create or replace function app_private.generate_weekly_options(p_sync_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_low_energy boolean;
  v_free boolean;
  v_home boolean;
  v_talk boolean;
  v_play boolean;
begin
  if auth.uid() is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.weekly_syncs sync
    where sync.id = p_sync_id
      and app_private.is_active_member(sync.couple_id, auth.uid())
  ) then
    raise exception 'weekly_sync_not_accessible' using errcode = '42501';
  end if;

  if (select count(*) from public.weekly_sync_responses response
      where response.weekly_sync_id = p_sync_id) <> 2 then
    return;
  end if;

  select
    bool_or(response.energy_level <= 2),
    bool_or(response.budget_band = 'free'),
    bool_or(response.setting_band = 'home'),
    bool_or(response.need_category = 'conversation'),
    bool_or(response.need_category = 'play')
  into v_low_energy, v_free, v_home, v_talk, v_play
  from public.weekly_sync_responses response
  where response.weekly_sync_id = p_sync_id;

  update public.weekly_syncs
  set selected_option_id = null,
      updated_at = now()
  where id = p_sync_id;

  delete from public.weekly_options where weekly_sync_id = p_sync_id;

  insert into public.weekly_options (
    weekly_sync_id, rank, kind, title_fa, duration_fa, budget_fa,
    setting_fa, reason_fa, instructions_fa
  )
  values
    (
      p_sync_id,
      1,
      'easy',
      case when v_low_energy then 'پناه کوچک دونفره' else 'نوشیدنی و یک سؤال تازه' end,
      '۳۰ دقیقه',
      case when v_free then 'رایگان' else 'کم' end,
      'خانه',
      case
        when v_low_energy then 'چون انرژی یکی از شما پایین‌تر است.'
        else 'شروع ساده و بدون برنامه‌ریزی برای هر دوی شما مناسب است.'
      end,
      case
        when v_talk then 'موبایل‌ها را کنار بگذارید و هر نفر فقط از بهترین لحظه هفته بگوید.'
        else 'یک نوشیدنی آماده کنید و سه آهنگ انتخاب کنید که حال این هفته‌تان را بهتر می‌کند.'
      end
    ),
    (
      p_sync_id,
      2,
      'balanced',
      case when v_home then 'آشپزی دونفره با انتخاب تصادفی' else 'قدم‌زدن با مسیر ناشناخته' end,
      '۶۰ دقیقه',
      case when v_free then 'رایگان' else 'کم' end,
      case when v_home then 'خانه' else 'بیرون' end,
      case
        when v_play then 'چون بازی و تنوع در انتخاب هر دو دیده شده است.'
        else 'بین آرامش و تازگی تعادل دارد.'
      end,
      case
        when v_home then 'غذا، آهنگ و نوشیدنی را با قرعه بین خودتان تقسیم کنید.'
        else 'یک مسیر نزدیک اما نرفته را انتخاب کنید و وسط راه برای یک خوراکی کوچک توقف کنید.'
      end
    ),
    (
      p_sync_id,
      3,
      'different',
      'ماموریت عکس بدون انتشار',
      '۹۰ دقیقه',
      case when v_free then 'رایگان' else 'متوسط' end,
      'فرقی ندارد',
      'برای شکستن تکرار، بدون بالا بردن فشار یا هزینه.',
      'هر نفر سه عکس از جزئیات زیبای اطراف بگیرد؛ در پایان فقط برای هم تعریفشان کنید.'
    );

  update public.weekly_syncs
  set status = 'ready',
      response_count = 2,
      selected_option_id = null,
      updated_at = now()
  where id = p_sync_id;
end
$$;

create or replace function app_private.start_pairing(p_display_name text default null)
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

  if exists (
    select 1 from public.couple_members
    where user_id = v_user_id and status = 'active'
  ) then
    raise exception 'already_paired' using errcode = '23505';
  end if;

  insert into public.profiles (user_id, display_name)
  values (v_user_id, nullif(btrim(p_display_name), ''))
  on conflict (user_id) do update
    set display_name = coalesce(excluded.display_name, public.profiles.display_name),
        updated_at = now();

  insert into public.couples (created_by)
  values (v_user_id)
  returning id into v_couple_id;

  insert into public.couple_members (couple_id, user_id)
  values (v_couple_id, v_user_id);

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

create or replace function app_private.accept_pairing(
  p_pairing_code text,
  p_display_name text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_invitation public.pairing_invitations%rowtype;
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  if exists (
    select 1 from public.couple_members
    where user_id = v_user_id and status = 'active'
  ) then
    raise exception 'already_paired' using errcode = '23505';
  end if;

  select invitation.*
  into v_invitation
  from public.pairing_invitations invitation
  where invitation.token_hash = encode(
      extensions.digest(upper(btrim(p_pairing_code)), 'sha256'),
      'hex'
    )
    and invitation.accepted_at is null
    and invitation.revoked_at is null
    and invitation.expires_at > now()
  for update;

  if not found then
    raise exception 'pairing_code_invalid_or_expired' using errcode = '22023';
  end if;

  if v_invitation.inviter_user_id = v_user_id then
    raise exception 'cannot_pair_with_self' using errcode = '22023';
  end if;

  insert into public.profiles (user_id, display_name)
  values (v_user_id, nullif(btrim(p_display_name), ''))
  on conflict (user_id) do update
    set display_name = coalesce(excluded.display_name, public.profiles.display_name),
        updated_at = now();

  insert into public.couple_members (couple_id, user_id)
  values (v_invitation.couple_id, v_user_id);

  update public.pairing_invitations
  set accepted_at = now()
  where id = v_invitation.id;

  update public.couples
  set status = 'active'
  where id = v_invitation.couple_id and status = 'pending';

  return v_invitation.couple_id;
end
$$;

create or replace function app_private.submit_weekly_response(
  p_energy_level smallint,
  p_need_category text,
  p_duration_band text,
  p_budget_band text,
  p_setting_band text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_couple_id uuid;
  v_sync_id uuid;
  v_response_count smallint;
  v_week_start date := date_trunc('week', timezone('UTC', now()))::date;
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select member.couple_id
  into v_couple_id
  from public.couple_members member
  join public.couples couple on couple.id = member.couple_id
  where member.user_id = v_user_id
    and member.status = 'active'
    and couple.status = 'active'
  limit 1;

  if v_couple_id is null then
    raise exception 'active_couple_required' using errcode = '42501';
  end if;

  insert into public.weekly_syncs (couple_id, week_start)
  values (v_couple_id, v_week_start)
  on conflict (couple_id, week_start) do update
    set updated_at = now()
  returning id into v_sync_id;

  insert into public.weekly_sync_responses (
    weekly_sync_id, user_id, energy_level, need_category,
    duration_band, budget_band, setting_band
  )
  values (
    v_sync_id, v_user_id, p_energy_level, p_need_category,
    p_duration_band, p_budget_band, p_setting_band
  )
  on conflict (weekly_sync_id, user_id) do update
    set energy_level = excluded.energy_level,
        need_category = excluded.need_category,
        duration_band = excluded.duration_band,
        budget_band = excluded.budget_band,
        setting_band = excluded.setting_band,
        submitted_at = now();

  select count(*)::smallint
  into v_response_count
  from public.weekly_sync_responses
  where weekly_sync_id = v_sync_id;

  update public.weekly_syncs
  set response_count = v_response_count,
      status = case when v_response_count = 2 then status else 'collecting' end,
      updated_at = now()
  where id = v_sync_id;

  if v_response_count = 2 then
    perform app_private.generate_weekly_options(v_sync_id);
  end if;

  return v_sync_id;
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

  select count(*), count(distinct vote.option_id), min(vote.option_id)
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

create or replace function public.start_pairing(p_display_name text default null)
returns table (couple_id uuid, pairing_code text, expires_at timestamptz)
language sql
security invoker
set search_path = ''
as $$
  select * from app_private.start_pairing(p_display_name)
$$;

create or replace function public.accept_pairing(
  p_pairing_code text,
  p_display_name text default null
)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select app_private.accept_pairing(p_pairing_code, p_display_name)
$$;

create or replace function public.submit_weekly_response(
  p_energy_level smallint,
  p_need_category text,
  p_duration_band text,
  p_budget_band text,
  p_setting_band text
)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select app_private.submit_weekly_response(
    p_energy_level,
    p_need_category,
    p_duration_band,
    p_budget_band,
    p_setting_band
  )
$$;

create or replace function public.vote_weekly_option(
  p_weekly_sync_id uuid,
  p_option_id uuid
)
returns table (matched boolean, selected_option_id uuid)
language sql
security invoker
set search_path = ''
as $$
  select * from app_private.vote_weekly_option(p_weekly_sync_id, p_option_id)
$$;

alter table public.profiles enable row level security;
alter table public.couples enable row level security;
alter table public.couple_members enable row level security;
alter table public.pairing_invitations enable row level security;
alter table public.weekly_syncs enable row level security;
alter table public.weekly_sync_responses enable row level security;
alter table public.weekly_options enable row level security;
alter table public.weekly_votes enable row level security;

revoke all on table
  public.profiles,
  public.couples,
  public.couple_members,
  public.pairing_invitations,
  public.weekly_syncs,
  public.weekly_sync_responses,
  public.weekly_options,
  public.weekly_votes
from anon, authenticated;

revoke execute on function app_private.current_user_id() from public, anon, authenticated;
revoke execute on function app_private.is_active_member(uuid, uuid) from public, anon, authenticated;
revoke execute on function app_private.shares_active_couple(uuid, uuid) from public, anon, authenticated;
revoke execute on function app_private.generate_weekly_options(uuid) from public, anon, authenticated;
revoke execute on function app_private.start_pairing(text) from public, anon, authenticated;
revoke execute on function app_private.accept_pairing(text, text) from public, anon, authenticated;
revoke execute on function app_private.submit_weekly_response(
  smallint, text, text, text, text
) from public, anon, authenticated;
revoke execute on function app_private.vote_weekly_option(uuid, uuid)
  from public, anon, authenticated;

revoke execute on function public.start_pairing(text) from public, anon, authenticated;
revoke execute on function public.accept_pairing(text, text) from public, anon, authenticated;
revoke execute on function public.submit_weekly_response(
  smallint, text, text, text, text
) from public, anon, authenticated;
revoke execute on function public.vote_weekly_option(uuid, uuid)
  from public, anon, authenticated;

grant select, insert, update on public.profiles to authenticated;
grant select on public.couples, public.couple_members to authenticated;
grant select on public.weekly_syncs, public.weekly_options to authenticated;
grant select on public.weekly_sync_responses, public.weekly_votes to authenticated;

grant execute on function app_private.start_pairing(text) to authenticated;
grant execute on function app_private.accept_pairing(text, text) to authenticated;
grant execute on function app_private.is_active_member(uuid, uuid) to authenticated;
grant execute on function app_private.shares_active_couple(uuid, uuid) to authenticated;
grant execute on function app_private.submit_weekly_response(
  smallint, text, text, text, text
) to authenticated;
grant execute on function app_private.vote_weekly_option(uuid, uuid) to authenticated;

grant execute on function public.start_pairing(text) to authenticated;
grant execute on function public.accept_pairing(text, text) to authenticated;
grant execute on function public.submit_weekly_response(
  smallint, text, text, text, text
) to authenticated;
grant execute on function public.vote_weekly_option(uuid, uuid) to authenticated;

create policy profiles_shared_couple_select
  on public.profiles for select to authenticated
  using (app_private.shares_active_couple(user_id, (select auth.uid())));

create policy profiles_owner_insert
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy profiles_owner_update
  on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy couples_active_member_select
  on public.couples for select to authenticated
  using (app_private.is_active_member(id, (select auth.uid())));

create policy couple_members_shared_couple_select
  on public.couple_members for select to authenticated
  using (app_private.is_active_member(couple_id, (select auth.uid())));

create policy weekly_syncs_active_member_select
  on public.weekly_syncs for select to authenticated
  using (app_private.is_active_member(couple_id, (select auth.uid())));

create policy weekly_responses_owner_select
  on public.weekly_sync_responses for select to authenticated
  using ((select auth.uid()) = user_id);

create policy weekly_options_active_member_select
  on public.weekly_options for select to authenticated
  using (
    exists (
      select 1
      from public.weekly_syncs sync
      where sync.id = weekly_options.weekly_sync_id
        and app_private.is_active_member(sync.couple_id, (select auth.uid()))
    )
  );

create policy weekly_votes_owner_select
  on public.weekly_votes for select to authenticated
  using ((select auth.uid()) = user_id);

comment on table public.weekly_sync_responses is
  'Owner-readable raw answers. Never expose partner rows or include them in analytics.';
comment on table public.weekly_votes is
  'Owner-readable private votes. Shared match state lives on weekly_syncs.';
