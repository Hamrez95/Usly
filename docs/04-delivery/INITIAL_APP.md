# Initial Usly App — v0.1

This branch contains the first executable product slice for validating Usly's core loop.

## Included

- Mobile-first Persian web interface
- Separate private weekly responses for two demo partners
- Neutral reveal after both responses are complete
- Three deterministic experience recommendations
- Independent voting and shared match
- Final selection
- Resettable demo state
- Health and status endpoints

## Deliberate limitations

This version is for product validation, not public production use.

- Demo-only in-memory state
- No authentication or real pairing
- No PostgreSQL persistence
- No notifications or calendar integration
- One shared demo session per running API instance

## Run locally

From the repository root:

```bash
dotnet run --project src/Usly.Api/Usly.Api.csproj
```

Open the HTTPS or HTTP address printed by ASP.NET Core. The app is served from the API root.

Useful endpoints:

- `/` — initial application
- `/api/status` — version and service status
- `/api/demo` — current demo state
- `/health` — health check

## Validation script

1. Complete the weekly response as partner one.
2. Switch to partner two and complete the response.
3. Confirm that raw private answers are not shown in the reveal.
4. Review the three generated options.
5. Vote once as each partner.
6. Confirm or manually select the matched experience.
7. Reset and repeat with low-energy and at-home constraints.

## Next vertical slice

Replace the demo store with authenticated users, consent-based pairing, PostgreSQL persistence, and row-level authorization while keeping the same user flow.