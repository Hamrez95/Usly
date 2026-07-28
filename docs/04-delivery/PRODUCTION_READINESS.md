# Production Readiness Checklist

This checklist turns the Usly product strategy into explicit release gates. A milestone is not production-ready because it works locally; it is ready only when security, privacy, operability, and rollback are covered.

## Gate 1 — Repository and CI

- Protected `main` and `dev` branches
- Pull requests required for changes
- Build, formatting, static analysis, and tests run in CI
- Dependency and secret scanning enabled
- Reproducible local environment documented
- Versioned database migrations checked in

## Gate 2 — Runtime baseline

- API and worker are containerized
- Configuration comes from environment variables or a secrets manager
- Liveness and readiness endpoints exist
- Structured logs include correlation IDs but no sensitive answers
- Error monitoring is configured for staging and production
- UTC is used in storage; IANA time zones drive weekly boundaries

## Gate 3 — Privacy and authorization

- Every query verifies authenticated user, couple membership, resource ownership, and resource state
- Cross-couple access integration tests exist
- Private weekly answers are never returned to the partner
- Invite tokens are stored only as hashes and expire
- Push notifications reveal no sensitive content on lock screens
- Unpair immediately revokes access to shared resources
- Account export and deletion are tested end to end
- Analytics payloads have an explicit privacy review

## Gate 4 — Core-loop reliability

- Pairing mutations are idempotent
- Weekly response submission is idempotent
- Recommendation results record rule and catalog versions
- Voting remains private until result resolution
- Scheduling, completion, skip, change, and reschedule states are covered
- Calendar exports contain only necessary information
- Core flow has automated end-to-end coverage from invite to feedback

## Gate 5 — Data and operations

- Daily backups are enabled
- A restore rehearsal has succeeded
- Migration rollback notes exist for every production migration
- Retention rules for private and shared data are documented
- Session revocation and logout-all-devices are verified
- Rate limits protect authentication and invitation endpoints
- Incident severity, ownership, and escalation paths are documented

## Gate 6 — Closed beta launch

- Staging mirrors production configuration where practical
- Production deployment and rollback have been rehearsed
- Privacy policy and consent versions match implemented behavior
- Support can resolve invite, pairing, unpair, export, and deletion problems
- Product analytics measure activation, match, scheduling, completion, and week-four retention
- Safety metrics track pressure reports, privacy complaints, and unauthorized-access incidents

## Required automated test suites

1. Domain tests for couple, invitation, weekly-cycle, voting, and selection invariants.
2. Application tests for use-case orchestration and idempotency.
3. Integration tests using PostgreSQL for persistence and authorization boundaries.
4. API contract tests for Problem Details, authentication, and concurrency failures.
5. End-to-end tests for the complete bilateral product loop.
6. Security regression tests for replayed invites, expired tokens, revoked sessions, and cross-couple IDs.

## Release decision

A release is blocked when any critical privacy or authorization scenario is untested, backup restoration has not been verified, sensitive data appears in logs or notifications, or the bilateral core loop cannot be completed through the real client.