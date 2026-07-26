# Privacy, Safety, and Ethical Boundaries

## Product classification
Usly is a lifestyle and shared-experience planning product. It is not therapy, diagnosis, crisis support, or a medical device.

## Three data spaces
1. **Private space:** visible only to one user.
2. **Shared space:** explicitly approved for the couple.
3. **Derived neutral context:** generated from constrained fields and safe rules.

Private answers must never be copied directly into shared space without explicit user action.

## Prohibited product behavior
- Scoring relationship quality
- Ranking partner effort
- Naming a winner or assigning blame
- Diagnosing attachment style, abuse, mental illness, or compatibility
- Revealing private answers through inference, notifications, analytics, or support tooling
- Punitive streaks or shame-based reminders
- Hidden tracking, contact scraping, or precise location surveillance
- Sensitive-data advertising

## Consent requirements
- Both users explicitly accept pairing.
- Sensitive topic packs require separate mutual opt-in.
- Users can skip any question without explanation.
- Either user can pause or disconnect independently.
- Unpairing must be easy and must immediately revoke access.

## Abuse-resistant design
- Do not expose last seen, response timestamps, read receipts, or ignored-notification status to the partner.
- Do not tell one partner that the other declined a sensitive question.
- Notification text should remain generic on lock screens.
- Provide a quiet exit and account-protection guidance.
- Include links to trusted crisis and domestic-violence resources by launch geography without claiming Usly can intervene.

## Data minimization
MVP should use bounded enums rather than sensitive free text. Do not collect:
- precise location history
- bank data
- contact books
- therapy notes
- sexual details
- background audio
- partner-device activity

## Analytics rules
Allowed analytics examples:
- onboarding step completed
- invitation accepted
- weekly sync submitted
- recommendation selected
- experience marked completed

Forbidden analytics:
- raw answers
- private notes
- relationship conflicts
- sensitive topic selection tied to ad profiles

## Deletion and separation
Before beta, define and test:
- account export
- individual account deletion
- couple disconnection
- retention of genuinely shared memories
- removal/anonymization of audit and analytics data
- deletion SLA and backup-expiry behavior

## Human review
Any content involving finance, family conflict, intimacy, mental health, or safety requires review by a qualified domain advisor before release.

## Incident priorities
1. Unauthorized partner access
2. Pairing-token abuse
3. Data exposure in notifications/logs
4. Account takeover
5. Improper deletion
6. Harmful or coercive content

Security and privacy defects in these categories block release.
