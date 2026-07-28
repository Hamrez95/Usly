# Usly MVP Architecture

## Architecture style

Use a modular monolith for the backend and a single Flutter application for mobile clients. The goal is clear module ownership, simple deployment, strong transactional consistency, and a low operational burden during validation.

## Technology baseline

- Client: Flutter
- API: ASP.NET Core
- Database: PostgreSQL
- File storage: S3-compatible object storage
- Background processing: hosted worker plus transactional outbox
- Observability: structured logs, traces, error monitoring, health checks
- Deployment: containerized API and worker with managed PostgreSQL

Versions must be pinned when implementation starts. Production dependencies require an explicit reason and an owner.

## Backend modules

### Identity

Registration, authentication, contact verification, recovery, sessions, account deletion, and data export requests.

### Profiles

Display name, language, time zone, city, calendar type, general interests, dietary restrictions, and novelty preference.

### Couples

Couple aggregate, membership, consent versions, pause, and unpair lifecycle.

### Pairing

Invite creation, hashed invite tokens, expiration, acceptance, rejection, cancellation, and abuse controls.

### WeeklySync

Weekly cycle creation, private response submission, skip/pause behavior, reveal readiness, and response access rules.

### Experiences

Curated experience cards, tags, constraints, activation state, and content versioning.

### Recommendations

Deterministic scoring, rule versioning, candidate filtering, Comfortable/Balanced/Different selection, and explanation templates.

### Voting

Independent votes, match calculation, fallback generation, and manual selection.

### Activities

Selected experience, scheduling, calendar export, completion, skip, change, and reschedule states.

### Feedback

Private post-experience feedback and preference signals.

### Notifications

Notification intents, privacy-safe templates, device token lifecycle, delivery attempts, and user preferences.

### Analytics

Minimal event contracts, consent boundaries, funnel events, safety events, and deletion propagation.

## Core domain invariants

- A user can belong to at most one active couple in the MVP.
- A couple is active only after both members have explicitly accepted pairing.
- A weekly response is readable only by its author and authorized server-side recommendation logic.
- Reveal cannot be created until both members complete or explicitly skip according to product rules.
- Votes remain private until a result is resolved.
- Unpair revokes authorization to shared resources immediately.
- Historical shared data follows a documented retention policy; private data remains owned by the individual.
- Recommendation output records the rule version and selected reason template.

## Data protection model

Every query must authorize against the authenticated user, couple membership, resource ownership, resource state, and consent state. Relying only on route IDs or client-side hiding is forbidden.

Sensitive values must not appear in application logs, analytics payloads, exception metadata, notification bodies, or support dashboards. Invite tokens are stored only as hashes. Device tokens are revocable and scoped to a user session/device record.

## Suggested persistence tables

- users
- user_profiles
- sessions
- couples
- couple_members
- invitations
- weekly_cycles
- weekly_responses
- experience_cards
- experience_tags
- recommendation_sets
- recommendation_items
- votes
- selected_experiences
- feedback
- consent_records
- device_tokens
- notification_outbox
- data_requests
- audit_events

Use UTC timestamps in storage. Store the user's IANA time zone separately for weekly-cycle boundaries and notifications.

## API conventions

- Versioned REST endpoints under `/api/v1`
- Problem Details for errors
- Idempotency keys for invite acceptance, response submission, voting, scheduling, and completion mutations
- Optimistic concurrency for lifecycle aggregates
- Cursor pagination for catalogs and histories
- Correlation IDs propagated through API, worker, and logs
- No sensitive response fields unless required by the current user action

## Initial deployment topology

- One API container
- One background worker container
- One managed PostgreSQL instance
- One object-storage bucket
- One secrets manager
- One monitoring/error-reporting service

Redis, Kubernetes, event streaming, microservices, multi-region deployment, and an LLM are intentionally excluded until measured load or product evidence justifies them.

## Production readiness baseline

Before closed beta:

- Automated database migrations with rollback notes
- Daily backups and a tested restore procedure
- Liveness and readiness checks
- Rate limits on authentication and invitations
- Dependency and secret scanning
- Unit, integration, authorization, and core-loop end-to-end tests
- Staging environment using production-like configuration
- Data deletion and export runbooks
- Incident contacts and severity definitions
- Privacy review of every analytics and notification payload