-- Advisor follow-up for migration 20260728145101.

create index couples_created_by_idx
  on public.couples(created_by);

create index pairing_invitations_couple_id_idx
  on public.pairing_invitations(couple_id);

create index pairing_invitations_inviter_user_id_idx
  on public.pairing_invitations(inviter_user_id);

create index weekly_sync_responses_user_id_idx
  on public.weekly_sync_responses(user_id);

create index weekly_syncs_selected_option_idx
  on public.weekly_syncs(id, selected_option_id);

create index weekly_votes_user_id_idx
  on public.weekly_votes(user_id);

create index weekly_votes_option_idx
  on public.weekly_votes(weekly_sync_id, option_id);

create policy pairing_invitations_no_direct_access
  on public.pairing_invitations
  for all
  to authenticated
  using (false)
  with check (false);
