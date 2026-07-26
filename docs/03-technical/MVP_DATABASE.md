# MVP Database Needs Assessment

## Decision
Use PostgreSQL. The product is relational, consent-heavy, and benefits from transactions, constraints, and auditable ownership. A document database adds little value for MVP.

## Capacity assumption for closed beta
- 1,000 couples / 2,000 users
- 52 weekly syncs per couple per year
- 100–300 curated experience cards
- one or two small memory images per completed experience only after paid beta

This fits comfortably in a small managed PostgreSQL instance.

## Core tables

### users
- id UUID PK
- email_or_phone_normalized unique
- status
- locale
- timezone
- created_at
- deleted_at

### user_profiles
- user_id PK/FK
- display_name
- relationship_stage optional
- city optional
- onboarding_completed_at

### user_preferences
- user_id
- preference_key
- preference_value
- visibility (`private`, `shareable`)

### couples
- id UUID PK
- status (`pending`, `active`, `paused`, `disconnected`)
- started_at
- disconnected_at

### couple_members
- couple_id
- user_id
- joined_at
- consent_version
- status
- unique active membership constraints

### pairing_invitations
- id
- inviter_user_id
- token_hash
- expires_at
- accepted_at
- revoked_at

### weekly_syncs
- id
- couple_id
- week_start_date
- status
- reveal_ready_at
- selected_experience_id nullable
- unique(couple_id, week_start_date)

### weekly_sync_responses
- id
- weekly_sync_id
- user_id
- energy_level
- need_category
- available_duration_band
- budget_band
- location_preference
- submitted_at
- unique(weekly_sync_id, user_id)

Raw free-text should not exist in MVP responses.

### experience_cards
- id
- title
- description
- instructions
- duration_band
- budget_band
- energy_band
- setting_tags
- need_tags
- locale
- safety_status
- active

### recommendation_sets
- id
- weekly_sync_id
- rules_version
- created_at

### recommendations
- recommendation_set_id
- experience_card_id
- option_type (`easy`, `balanced`, `different`)
- explanation_code
- rank

### votes
- weekly_sync_id
- user_id
- experience_card_id
- voted_at

### experience_completions
- id
- couple_id
- weekly_sync_id nullable
- experience_card_id
- scheduled_at nullable
- completed_at nullable
- skipped_reason_code nullable

### experience_feedback
- completion_id
- user_id
- repeat_worthiness smallint
- private_note_ciphertext nullable (not MVP default)

### device_registrations
- id
- user_id
- platform
- push_token_ciphertext
- active
- last_seen_at

### consent_records
- id
- user_id
- consent_type
- version
- accepted_at
- revoked_at

### data_rights_requests
- id
- user_id
- type (`export`, `delete`)
- status
- requested_at
- completed_at

### audit_events
- id
- actor_user_id nullable
- event_type
- target_type
- target_id
- occurred_at
- metadata without sensitive content

## Important constraints
- A user cannot be in two active couples in MVP.
- One response per partner per weekly sync.
- Reveal endpoint must require two submitted responses.
- Unpairing immediately blocks future partner access.
- Deletion workflow defines what shared records remain, become anonymized, or are deleted.

## Data deliberately excluded from MVP
- Chat messages
- Precise location history
- Bank transactions
- Sexual-health details
- Therapy notes
- Relationship scores
- Contact-book upload
- Continuous behavioral tracking

## Storage and backup
- Managed PostgreSQL with daily backups and point-in-time recovery before closed beta.
- No user photos during validation and earliest MVP.
- When photos are added, store object keys in PostgreSQL and files in private object storage with short-lived signed URLs.

## Migration approach
Use EF Core migrations. All schema changes require migration review and rollback notes. Seed only curated experience content; never seed real user data.
