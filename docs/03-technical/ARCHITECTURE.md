# Technical Architecture

## Delivery strategy
Start with a modular monolith and one mobile codebase. Do not introduce microservices before product-market fit.

## Recommended stack
- Mobile: Flutter stable channel
- Backend: ASP.NET Core on .NET 10
- Database: PostgreSQL
- Cache/queues: none for MVP; add Redis only after a measured need
- Object storage: S3-compatible storage for optional memory photos
- Notifications: Firebase Cloud Messaging and Apple Push Notification service through a notification provider
- Analytics: privacy-safe product events only; no sensitive answer bodies
- Admin: lightweight web panel after pilot

## Repository structure
```text
Usly/
├── apps/
│   └── mobile/                 # Flutter application (created after validation gate)
├── src/
│   ├── Usly.Api/               # HTTP API and composition root
│   ├── Usly.Application/       # use cases and ports
│   ├── Usly.Domain/            # domain model and rules
│   └── Usly.Infrastructure/    # PostgreSQL, notifications, storage
├── tests/
│   ├── Usly.Domain.Tests/
│   ├── Usly.Application.Tests/
│   └── Usly.Api.IntegrationTests/
├── docs/
└── .github/
```

## Initial bounded modules
- Identity
- Profiles and Preferences
- Couple Pairing and Consent
- Weekly Sync
- Experience Catalog
- Recommendation Rules
- Voting and Selection
- Completion and Feedback
- Notifications
- Privacy and Data Rights

## Architecture rules
- Domain does not depend on infrastructure.
- Pairing and sharing always require explicit consent.
- Private response fields are never returned to the partner directly.
- Shared summaries are derived from approved enums/rules, not raw private text.
- No sensitive free text in logs, analytics, crash reports, or push notifications.
- Every data-sharing transition has automated tests.
- Couple disconnect is a first-class domain workflow.

## MVP API shape
- `POST /auth/register`
- `POST /pairings/invitations`
- `POST /pairings/accept`
- `DELETE /pairings/current`
- `GET /weekly-syncs/current`
- `PUT /weekly-syncs/current/response`
- `GET /weekly-syncs/current/reveal`
- `GET /weekly-syncs/current/recommendations`
- `POST /weekly-syncs/current/votes`
- `POST /weekly-syncs/current/selection`
- `POST /experiences/{id}/completion`
- `POST /experiences/{id}/feedback`
- `DELETE /me`

## Recommendation MVP
Use deterministic rules and curated tags:
- energy level
- available duration
- budget band
- indoor/outdoor
- at-home/outside
- transportation requirement
- desired need category
- mutual exclusions/preferences

Return three options with diversity constraints. Avoid generative AI in MVP.

## Security baseline
- Short-lived access tokens and rotating refresh tokens
- Email/phone verification depending on launch market
- Rate limiting on auth and pairing endpoints
- Encryption in transit and managed encryption at rest
- Secrets outside source control
- Row-level authorization based on user/couple ownership
- Audit records for pairing, unpairing, export, and deletion
- Backups with tested restoration

## Deployment stages
### Local and validation
No production backend required for manual pilot. Use secure survey tooling and pseudonymous IDs.

### Internal alpha
Managed PostgreSQL and one containerized API environment.

### Closed beta
Separate staging and production, object storage, monitoring, automated backup, domain, TLS, and transactional email.

### Scale
Only after measured load: background jobs, Redis, CDN, read replicas, and service extraction.
