-- DRAFT ONLY. Do not apply directly to production.
-- Convert to a CLI-generated migration after the exact Usly project is connected,
-- then run security/performance advisors and integration tests.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) between 1 and 40),
  locale text not null default 'fa',
  created_at timestamptz not null default now()
);

create table if not exists public.couples (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'pending'
    check (status in ('pending', 'active', 'paused', 'disconnected')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  disconnected_at timestamptz
);

create table if not exists public.couple_members (
  couple_id uuid not null references public.couples(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  consented_at timestamptz not null default now(),
  status text not null default 'active' check (status in ('active', 'left')),
  primary key (couple_id, user_id)
);

create unique index if not exists one_active_couple_per_user
  on public.couple_members(user_id)
  where status = 'active';

create table if not exists public.pairing_invitations (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  inviter_user_id uuid not null references auth.users(id),
  token_hash text not null unique,
  expires_at timestamptz not null,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.weekly_syncs (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null references public.couples(id) on delete cascade,
  week_start date not null,
  status text not null default 'collecting'
    check (status in ('collecting', 'revealed', 'selected', 'completed', 'skipped')),
  response_count smallint not null default 0 check (response_count between 0 and 2),
  reveal_ready_at timestamptz,
  selected_experience_id bigint,
  created_at timestamptz not null default now(),
  unique (couple_id, week_start)
);

create table if not exists public.weekly_sync_responses (
  weekly_sync_id uuid not null references public.weekly_syncs(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  energy_level smallint not null check (energy_level between 1 and 5),
  need_category text not null,
  duration_band text not null,
  budget_band text not null,
  setting_band text not null,
  submitted_at timestamptz not null default now(),
  primary key (weekly_sync_id, user_id)
);

alter table public.profiles enable row level security;
alter table public.couples enable row level security;
alter table public.couple_members enable row level security;
alter table public.pairing_invitations enable row level security;
alter table public.weekly_syncs enable row level security;
alter table public.weekly_sync_responses enable row level security;

grant select, insert, update on public.profiles to authenticated;
grant select on public.couples, public.couple_members, public.weekly_syncs to authenticated;
grant select, insert, update on public.weekly_sync_responses to authenticated;

create policy "profiles_owner_select"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "profiles_owner_insert"
  on public.profiles for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "profiles_owner_update"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "members_read_own_membership"
  on public.couple_members for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "couples_read_as_active_member"
  on public.couples for select to authenticated
  using (
    exists (
      select 1 from public.couple_members member
      where member.couple_id = couples.id
        and member.user_id = (select auth.uid())
        and member.status = 'active'
    )
  );

create policy "syncs_read_as_active_member"
  on public.weekly_syncs for select to authenticated
  using (
    exists (
      select 1 from public.couple_members member
      where member.couple_id = weekly_syncs.couple_id
        and member.user_id = (select auth.uid())
        and member.status = 'active'
    )
  );

create policy "responses_owner_select"
  on public.weekly_sync_responses for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "responses_owner_insert"
  on public.weekly_sync_responses for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1
      from public.weekly_syncs sync
      join public.couple_members member on member.couple_id = sync.couple_id
      where sync.id = weekly_sync_responses.weekly_sync_id
        and member.user_id = (select auth.uid())
        and member.status = 'active'
    )
  );

create policy "responses_owner_update"
  on public.weekly_sync_responses for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Invitation creation/acceptance, reveal derivation, disconnect, and response_count
-- changes must be implemented as narrowly granted functions in a non-exposed schema.
-- SECURITY DEFINER is not added in this draft until explicit auth.uid(), search_path,
-- execute grants, replay protection, and pgTAP tests are reviewed together.
