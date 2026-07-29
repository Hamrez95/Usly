# Usly Master Roadmap

This roadmap is organized by gates. Dates are relative because development must stop if validation fails.

## Current delivery ladder — July 2026

Status legend: `[x]` implemented in the current candidate, `[~]` implemented
but not yet proven by CI/device/integration evidence, `[ ]` not implemented.

### v0.3.1 — Security and Auth stabilization

- [~] Deterministic account creation outcome.
- [~] Confirmation-required screen, resend cooldown and actionable errors.
- [~] Temporary guest warning and no silent account-loss expectation.
- [ ] Remove recommendation text that permits partner-answer inference.
- [ ] Serialize concurrent weekly submissions and prove option generation.
- [ ] Increase pairing-code entropy and add attempt throttling/audit.
- [ ] Add database/RLS/replay/expiry/concurrency integration tests.
- [ ] Prove real email Auth and the two-device pairing/sync/vote/match path.

### v0.4.0 — Internal Alpha and complete value loop

- [~] Bundled Persian typography and phone-first responsive tokens.
- [~] Original app icon, in-app mark and non-judgmental companion system.
- [~] Consistent Auth, Pairing, Weekly, Waiting and Match states.
- [ ] Complete password recovery with verified deep links and new-password state.
- [ ] Add timezone-aware ritual weeks and separate staging/production config.
- [ ] Add 30 curated, privacy-safe experience cards with neutral reasons.
- [ ] Complete Match → schedule → complete/skip → feedback → history.
- [ ] Add safe pending-cancel, pause and unpair flows.
- [ ] Complete loading/error/offline/recovery states and durable local drafts.
- [~] 360dp / 200% text / Light-Dark / RTL baseline; expand it to every journey.
- [ ] Reproducible Android runner, hashed APK and stability report.

### v0.5.0 — Closed Beta

- [ ] Expand to 60–100 reviewed experience cards.
- [ ] Add onboarding, consent/privacy versioning and safe reminder controls.
- [ ] Add account export/delete, immediate unpair revocation and support entry.
- [ ] Add privacy-safe analytics for activation, selection, completion and retention.
- [ ] Add monitoring with sensitive-data scrubbing and backup/restore rehearsal.
- [ ] Run a controlled 5–10-couple beta with zero P0/P1.

### v0.6.0 — Validation Beta

- [ ] Run a four-week pilot with 20 couples.
- [ ] Target invitation acceptance >= 70%, completion >= 40% and week-four
      couple retention >= 50%.
- [ ] Investigate every pressure/privacy report; target harm reports < 10%.

### v0.7.0 — Delight Beta

- [ ] Shared companion space that celebrates completion without streak pressure.
- [ ] Privacy-safe home widget for the selected experience.
- [ ] Limited wishlist/sparks and optional memory cards.
- [ ] Keep each feature only when it improves completion or retention without pressure.

### v1.0.0 — Stable Android Persian

- [ ] External security/privacy review, production signing and proven rollback.
- [ ] Incident response, monitoring, support and staged rollout.
- [ ] Stable Persian Android release; iOS and English follow evidence, not the version number.

Only a candidate with zero P0/P1, all applicable hard gates and a Foundry score
of at least 90/100 can merge through `dev` to `main`.

## Phase 0 — Foundation and naming (Week 0)
- [ ] Confirm working product name and alternatives.
- [ ] Run app-store, domain, social-handle, and trademark checks.
- [ ] Reserve an affordable primary domain after the first legal/name pass.
- [ ] Finalize product principles and safety boundaries.
- [ ] Prepare research consent and privacy notice.
- [ ] Create pilot recruitment page.

**Exit:** name is usable for pilot; research materials are ready.

## Phase 1 — Problem validation (Weeks 1–2)
- [ ] Interview at least 15 individuals from the target segment.
- [ ] Interview partners separately where possible.
- [ ] Document current weekend/date planning behavior.
- [ ] Test willingness to invite a partner.
- [ ] Test willingness to pay for subscription, packs, and bookable experiences.
- [ ] Identify language that feels fun versus therapeutic.
- [ ] Recruit 20 pilot couples.

**Exit:** recurring problem and target segment are confirmed.

## Phase 2 — Manual concierge pilot (Weeks 3–6)
- [ ] Run four weekly sync cycles manually.
- [ ] Maintain a curated library of at least 100 experience cards.
- [ ] Provide three recommendations per couple each week.
- [ ] Measure invitation, completion, bilateral participation, and harm signals.
- [ ] Conduct week-two and week-four interviews.
- [ ] Ask for a real pre-purchase or deposit, not hypothetical interest.

**Exit gate:** meet documented validation thresholds. Otherwise stop, narrow segment, or pivot.

## Phase 3 — UX prototype (Weeks 7–8)
- [ ] Map solo, pending invitation, active couple, paused, and unpaired states.
- [ ] Design consent and sharing boundaries.
- [ ] Prototype the three-question sync.
- [ ] Prototype simultaneous reveal and neutral language.
- [ ] Prototype recommendation voting and selection.
- [ ] Test with 8–10 pilot couples.
- [ ] Validate accessible RTL design and non-gendered visual identity.

**Exit:** users complete the core flow without explanation.

## Phase 4 — Technical foundation (Weeks 9–10)
- [ ] Create Flutter app after validation gate.
- [ ] Establish .NET 10 modular-monolith solution.
- [ ] Provision development PostgreSQL.
- [ ] Implement CI for backend tests and static analysis.
- [ ] Define environment/secrets strategy.
- [ ] Add threat model and privacy test cases.
- [ ] Create staging environment and DNS only now.

**Exit:** deployable empty vertical slice and secure environment baseline.

## Phase 5 — MVP build (Weeks 11–16)
### Sprint A — Identity and pairing
- [ ] Registration/sign-in.
- [ ] Profile and basic preferences.
- [ ] Invitation token lifecycle.
- [ ] Mutual consent and pairing.
- [ ] Pause/unpair/delete workflows.

### Sprint B — Weekly sync
- [ ] Weekly-cycle generation.
- [ ] Three private inputs.
- [ ] Reveal readiness and neutral summary.
- [ ] Privacy and authorization tests.

### Sprint C — Experiences
- [ ] Curated experience catalog.
- [ ] Deterministic recommendation engine.
- [ ] Three diverse options.
- [ ] Voting and shared selection.
- [ ] Calendar export.

### Sprint D — Completion and feedback
- [ ] Completion/skip tracking.
- [ ] Repeat-worthiness feedback.
- [ ] Four-week history.
- [ ] Privacy-safe reminders.
- [ ] Analytics events.

**Exit:** two partners can complete the entire core loop in staging.

## Phase 6 — Internal alpha (Weeks 17–18)
- [ ] Test with founder and 5–10 trusted couples.
- [ ] Run permission and unpairing abuse tests.
- [ ] Verify push notifications do not expose sensitive content.
- [ ] Test database backup and restore.
- [ ] Fix onboarding, crash, and reliability issues.

**Exit:** no critical privacy/security defects and core flow is reliable.

## Phase 7 — Closed beta (Weeks 19–24)
- [ ] Provision separate production environment.
- [ ] Publish privacy policy, terms, support channel, and deletion path.
- [ ] Enroll 50–100 couples in controlled cohorts.
- [ ] Instrument week-1 and week-4 retention.
- [ ] Compare reminder schedules.
- [ ] Track one-sided participation.
- [ ] Add hidden-answer question only if core retention is healthy.

**Exit:** at least 50% week-four couple retention and meaningful experience completion.

## Phase 8 — Paid beta (Months 7–9)
- [ ] Implement Couple Plus entitlements.
- [ ] Add annual subscription and cancellation flow.
- [ ] Launch 2–3 one-time themed packs.
- [ ] Test pricing and couple-level packaging.
- [ ] Add admin content management.
- [ ] Add simple memory cards if users request them.

**Exit:** repeatable paid conversion without harming retention.

## Phase 9 — Product-market fit (Months 10–15)
- [ ] Expand Persian experience catalog.
- [ ] Add city-aware curated activities.
- [ ] Add referral and gifting.
- [ ] Add lightweight shared goals, not money custody.
- [ ] Build lifecycle communication and support operations.
- [ ] Conduct external privacy/security review.

**Exit:** stable acquisition, retention, and monetization for a defined segment.

## Phase 10 — Marketplace pilot (Months 16–20)
- [ ] Select one city and two experience categories.
- [ ] Recruit local partners.
- [ ] Build offer, voucher, and redemption workflows.
- [ ] Track booking quality and customer support cost.
- [ ] Avoid broad marketplace expansion until supply quality is proven.

## Phase 11 — Advanced product (Months 21+)
- [ ] Optional constrained AI recommendations over curated inventory.
- [ ] Explainable recommendation reasons.
- [ ] Privacy-preserving personalization.
- [ ] English localization and international market tests.
- [ ] Multi-region architecture only when required.

## Permanent stop conditions
Stop or pivot if:
- participation is consistently one-sided;
- week-four retention stays below 30%;
- users describe the app as “cute but unnecessary”;
- suggestions are selected but rarely completed;
- users report pressure, conflict, surveillance, or coercion;
- revenue depends on exploiting sensitive data.
