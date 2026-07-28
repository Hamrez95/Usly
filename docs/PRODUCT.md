# Usly Product Contract

## Product promise

Usly helps a couple create one realistic shared experience each week in under five minutes, based on both partners' mood, needs, time, energy, and budget.

**Product philosophy:** less time in the app, more time together.

## Initial target user

Working couples aged 25–38 who are not in acute relationship crisis, but struggle to consistently plan quality time because of work, fatigue, financial constraints, and decision overload.

## MVP core loop

1. A user signs up and invites a partner.
2. Both partners independently complete a private weekly sync.
3. The system derives neutral shared constraints and alignment points.
4. A deterministic rule engine produces three curated options: Comfortable, Balanced, and Different.
5. Both partners vote independently.
6. A mutually acceptable experience is selected and scheduled.
7. The couple marks it completed, skipped, changed, or rescheduled.
8. Each partner can privately submit lightweight feedback.
9. Future recommendations use explicit and behavioral preferences without exposing sensitive answers.

## P0 scope

- Authentication and account lifecycle
- Individual profile and locale preferences
- Consent-based pairing, pause, invite cancellation, and unpair
- Weekly cycles and private responses
- Neutral shared reveal
- Curated experience catalog
- Rule-based recommendation engine
- Independent voting and match resolution
- Scheduling and calendar export
- Completion state and private feedback
- Privacy-safe notifications
- Minimal product analytics and safety events

## Explicit non-goals

The MVP is not a messenger, social network, therapy product, relationship score, surveillance tool, location tracker, financial account, household project manager, or AI relationship adviser.

## Product guardrails

- No partner scoring, blame, comparison, or relationship-health percentage.
- Private data never becomes shared without a documented rule and explicit consent.
- Unpair must immediately revoke shared access.
- Push notifications must not expose sensitive content on a lock screen.
- Skipping and rescheduling must never trigger shame-based language or punitive streaks.
- Recommendation explanations must be neutral and traceable to structured inputs.
- AI is excluded from the MVP recommendation path.

## North-star metric

**Monthly count of mutually selected experiences that couples report as completed.**

## Activation definition

A couple is activated after both members are paired, both complete one weekly sync, and one experience is mutually selected.

## Initial validation gates

Proceed toward paid beta when evidence trends toward:

- 70% invitation acceptance
- 50% week-four couple retention
- 40% completion of selected experiences
- 30% of interviewed couples saying they would miss Usly
- At least 15% demonstrating real payment intent
- Fewer than 10% reporting pressure or negative relationship impact

## MVP release principle

Every feature must improve one of these steps: complete sync, reach a mutual selection, complete the experience, or return next week. Features that do not improve this loop remain outside P0.