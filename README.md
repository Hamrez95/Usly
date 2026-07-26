# Usly

**Usly turns a short weekly check-in into one real shared experience for a couple.**

The product is intentionally positioned as a lifestyle and planning tool—not therapy, diagnosis, surveillance, or relationship scoring.

## Current stage

Pre-MVP validation and technical foundation. All active work lives on the `dev` branch.

## Product loop

1. Both partners privately share energy, need, time, and budget.
2. Usly reveals neutral shared context.
3. The couple receives three curated options: easy, balanced, and different.
4. Both vote and schedule one shared experience.
5. They complete it and provide lightweight feedback.

## Repository map

- `docs/01-product` — idea, positioning, strategy, and feature priority
- `docs/02-business` — pitch narrative and business model
- `docs/03-technical` — architecture, database, hosting, and domain timing
- `docs/04-delivery` — roadmap from validation to advanced product
- `docs/05-safety` — privacy, consent, and ethical boundaries
- `src` — .NET 10 modular-monolith backend foundation
- `apps/mobile` — Flutter app placeholder, created after the validation gate

## Most important gate

Do not build the full product until a four-week pilot with 20 couples demonstrates bilateral participation, completed shared experiences, low pressure/harm signals, and real payment intent.

## Documents

- [Idea](docs/01-product/IDEA.md)
- [Product strategy](docs/01-product/PRODUCT_STRATEGY.md)
- [Feature priority](docs/01-product/FEATURE_PRIORITY.md)
- [Pitch deck narrative](docs/02-business/PITCH_DECK.md)
- [Architecture](docs/03-technical/ARCHITECTURE.md)
- [MVP database assessment](docs/03-technical/MVP_DATABASE.md)
- [Hosting and domain timeline](docs/03-technical/HOSTING_DOMAIN_TIMELINE.md)
- [Master roadmap](docs/04-delivery/MASTER_ROADMAP.md)
- [Privacy and safety](docs/05-safety/PRIVACY_AND_SAFETY.md)

## Technology direction

- Flutter stable for mobile after validation
- ASP.NET Core on .NET 10
- PostgreSQL
- Modular monolith before microservices
- Deterministic, curated recommendation rules before generative AI

## Branch policy

- `main`: stable approved baseline
- `dev`: active product and implementation work
- `feature/*`: scoped implementation branches later
