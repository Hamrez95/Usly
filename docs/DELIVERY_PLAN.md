# Usly Delivery Plan

## Delivery strategy

Build the smallest secure vertical slice that proves the weekly ritual end to end. Avoid implementing isolated modules that cannot be exercised by a real couple.

## Milestone 0 — Foundation

Exit criteria:

- Repository conventions and branch policy documented
- Backend and Flutter workspaces bootstrapped
- Local PostgreSQL available through Docker Compose
- CI runs formatting, static analysis, tests, dependency checks, and secret scanning
- Configuration uses environment variables and local developer secrets
- Health endpoints and structured logging exist
- Architecture tests protect module boundaries

## Milestone 1 — Pairing vertical slice

User outcome: two users can create accounts and consent to becoming a couple.

Scope:

- Account registration and authentication
- Minimal profile
- Invite link/code with hashed token and expiration
- Accept, reject, cancel, and revoke invitation
- One active couple per user
- Pause and unpair
- Authorization tests for every shared resource

Exit criteria:

- Pairing works through API and Flutter UI
- Replayed or expired invitations fail safely
- Unpair revokes shared access immediately
- Security and audit events are emitted without sensitive payloads

## Milestone 2 — Weekly sync vertical slice

User outcome: both partners can independently submit a private weekly check-in.

Scope:

- Weekly-cycle creation using couple time zone
- Energy, need, budget, duration, setting, and practical constraints
- Draft/submit/skip states
- Partner status without revealing answers
- Pause for a busy week
- Privacy-safe reminders

Exit criteria:

- Each partner can see only their own response before reveal
- Duplicate submissions are idempotent
- Time-zone and week-boundary tests pass
- Sensitive answers do not enter logs or notifications

## Milestone 3 — Recommendation and voting slice

User outcome: the couple receives three relevant options and reaches a mutual selection.

Scope:

- Curated experience catalog and seed data
- Deterministic candidate filtering
- Comfortable, Balanced, and Different ranking
- Neutral explanation templates
- Independent votes: preferred, acceptable, reject
- Match resolution and fallback options
- Manual selection

Exit criteria:

- Every recommendation records rule version and reasons
- Results are reproducible from the same inputs/catalog version
- Votes remain private until resolution
- No relationship score or blame language exists

## Milestone 4 — Real-world completion slice

User outcome: the selected experience gets scheduled, completed, and learned from.

Scope:

- Schedule and reschedule
- ICS calendar export first; native integrations later
- Reminder intent and delivery
- Completed, skipped, changed, and moved states
- Private lightweight feedback
- Four-week activity history

Exit criteria:

- Core loop is measurable from pairing through completion
- Feedback updates allowed preference signals
- Skipping never causes punitive UI or notifications
- Calendar output contains no unnecessary sensitive context

## Milestone 5 — Closed beta readiness

Scope:

- Analytics dashboard for activation, weekly retention, selection, and completion
- Safety and privacy event review
- Data export and deletion
- Backup restore rehearsal
- Rate limiting and abuse controls
- Support runbook
- Store-ready privacy disclosures
- Production deployment and rollback rehearsal

Exit criteria:

- 50–100 couples can be onboarded safely
- Critical journeys have automated end-to-end coverage
- Restore, deletion, unpair, and session revocation are manually verified
- Known risks have owners and mitigation dates

## First implementation backlog

1. Bootstrap solution structure and CI.
2. Define domain primitives, clock abstraction, IDs, and result/error conventions.
3. Implement Identity and session lifecycle.
4. Implement Couple, CoupleMember, Invitation, and consent rules.
5. Add authorization integration tests, especially cross-couple access attempts.
6. Implement WeeklyCycle scheduling and private WeeklyResponse storage.
7. Seed an initial curated catalog of at least 100 experience cards.
8. Implement versioned recommendation rules and golden test cases.
9. Implement voting/match resolution.
10. Implement SelectedExperience lifecycle, ICS export, and feedback.
11. Add minimal funnel analytics with a privacy review.
12. Deploy staging and run a two-couple dogfood test.

## Definition of done

A product increment is done only when:

- Acceptance criteria are automated where practical
- Authorization and privacy failure cases are tested
- Database migration and rollback impact are documented
- Logs and analytics have been checked for sensitive data
- User-facing copy is neutral and non-judgmental
- Monitoring exists for the new failure mode
- Documentation and API contracts are updated
- The increment is usable through the real client, not only Swagger

## Deferred until evidence

- AI-generated recommendations
- Full calendar synchronization
- Memories and media uploads
- Paid subscriptions
- Money Date and shared goals
- Marketplace and booking
- Long-distance and parenting modes
- Microservices, Kubernetes, Redis cluster, and event streaming