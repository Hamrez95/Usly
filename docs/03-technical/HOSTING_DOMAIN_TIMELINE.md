# Hosting and Domain Timeline

## Principle
Do not spend heavily on infrastructure before validating bilateral usage. Reserve naming assets early, but buy production infrastructure only when the product needs it.

## Stage 0 — Immediately
### Domain
- Check availability for `usly.app`, `usly.ir`, `getusly.com`, and defensive spelling variants.
- Reserve the best affordable primary domain as soon as naming checks and trademark search are acceptable.
- Do not delay customer validation because the ideal `.com` is unavailable.

### Brand checks
- Search app stores, Iranian trademark records, major social handles, and international marks for confusingly similar relationship products.
- Treat Usly as a working name until this task is complete.

### Hosting
- No production hosting required.
- Use a simple landing page host only if needed to recruit pilot couples.

## Stage 1 — Manual pilot, weeks 1–4
- Landing page on a low-cost static host.
- Secure survey/forms; use participant codes rather than full names where possible.
- No permanent sensitive production database.
- Create privacy notice and informed pilot consent before collecting responses.

## Stage 2 — MVP development, weeks 5–12 after validation gate
Buy/provision:
- primary domain and DNS
- managed PostgreSQL development instance
- staging API host
- transactional email provider
- secret manager or protected environment variables

Do not yet buy:
- large VPS
- Redis
- Kubernetes
- CDN beyond platform default
- premium observability suite
- multiple production regions

## Stage 3 — Internal alpha
- Separate development and staging databases.
- Automated deployment from `dev` to staging.
- TLS and domain subdomains such as `api-staging`.
- Error monitoring with sensitive-data scrubbing.

## Stage 4 — Closed beta
Provision before inviting external beta users:
- separate production environment and database
- daily backups and tested restore
- production object storage only if photos exist
- uptime monitoring
- privacy and terms pages on the primary domain
- support email and incident-response contact
- transactional email domain authentication
- Android closed-testing release; iOS beta when feasible

## Stage 5 — Paid launch
Before accepting payment:
- stable production domain
- payment provider and reconciliation
- subscription entitlement service
- refund and cancellation policy
- invoice/receipt handling appropriate to launch market
- production analytics and funnel monitoring
- security review and deletion/export test

## Stage 6 — Scale
Trigger infrastructure upgrades by metrics, not ambition:
- background job system when notifications/recommendations need durable scheduling
- Redis when measured caching/locking needs appear
- CDN when media delivery becomes material
- read replicas when database load demonstrates need
- multi-region only when geography, regulation, or availability requires it

## Recommendation for MVP hosting shape
- One containerized ASP.NET Core API
- One managed PostgreSQL database
- Static landing page
- Flutter mobile app distributed through test channels
- S3-compatible private storage only after memory photos are enabled

## Domain purchase decision
Purchase the primary domain after the first naming/trademark pass, ideally before public pilot recruitment. This protects the brand at low cost without committing to full product development.
