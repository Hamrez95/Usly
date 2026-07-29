# Foundry review — 2026-07-29

Independent technical and product reviews were consolidated here. This is a
severity-ranked execution backlog, not a release claim.

## Current evidence

- Implemented locally on `fix/17-auth-brand-beta`: deterministic Auth UI,
  confirmation/resend state, guest warning, responsive design tokens, bundled
  Vazirmatn, original icon/mark, companion illustration and improved
  Auth/Pairing/Weekly/Waiting/Match screens.
- Previously proven on commit `5b3e2a7`: Flutter analysis/tests and Android APK
  build in GitHub Actions for the earlier online alpha.
- Not yet proven for the current candidate: compile, tests, APK, SMTP delivery,
  real two-device flow, complete accessibility matrix and live database state.

## P0/P1 — release blockers

1. Replace recommendation reasons that allow either partner to infer the
   other's private answer.
2. Serialize concurrent weekly response submission so two simultaneous writes
   always produce three options.
3. Increase pairing-code entropy and add throttling/audit against guessing.
4. Add executable database tests for RLS, cross-couple access, invite
   replay/expiry, concurrent submission and private voting.
5. Make CI a required gate for both `dev` and `main`; keep formatting
   check-only and make the Android runner reproducible.
6. Verify two real accounts on two physical devices from sign-up through Match.
7. Before external beta, add consent/versioning, pause/unpair, export/delete,
   monitoring scrubbing and backup/restore evidence.

## P2 — highest-value product work

1. Complete Match → schedule → complete/skip → feedback → history.
2. Replace the three hard-coded experiences with a reviewed curated catalog.
3. Make ritual weeks timezone-aware and persist the user's selected timezone.
4. Add password recovery/deep links, anonymous-account upgrade and safe startup
   recovery.
5. Replace aggressive polling with lifecycle-aware synchronization/backoff.
6. Add privacy-safe reminders and outcome analytics.

## Deferred until validation

- Companion space, widget, wishlist/sparks and optional memory cards.
- Subscriptions, marketplace, referrals, gifting and city-aware commerce.
- iOS/English expansion and AI-assisted recommendations.

## Permanent exclusions

- Relationship/effort scores, therapy or diagnosis.
- Location, sleep, battery, last-seen or read-receipt surveillance.
- Punitive streaks, hungry pets, guilt notifications or coercive rewards.
- Open chat/social feed and sensitive free-text analytics.

## Human inputs, deferred to their actual gates

- Hamidreza and Reyhaneh: install and complete the two-device smoke script.
- Product owner: configure SMTP/redirect URLs and securely retain the Android
  signing key before public distribution.
- Pilot stage: recruit 5–10 trusted couples, then 20 four-week pilot couples.
- Content stage: review 60–100 Persian activities for realism, cost and tone.

Daily technical, UI and prioritization decisions do not wait for user approval.
Production publication, paid services, irreversible data operations, legal copy
and public commitments still require their specific release gate.
