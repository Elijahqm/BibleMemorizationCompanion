# 13 Analytics and Product Metrics

## Analytics Philosophy

Measure behavior that improves memorization outcomes and product reliability, not vanity events.

## Key Product Questions

1. Do users reach first successful study quickly?
2. Do users return for repeated sessions?
3. Which steps cause drop-off?
4. Does audio improve retention behavior?

## Event Taxonomy (Initial)

Acquisition and setup:
- app_opened
- first_run_seen
- library_opened

Store and packages:
- store_viewed
- package_download_started
- package_download_completed
- package_install_failed
- package_opened
- package_deleted

Study lifecycle:
- study_created
- study_resumed
- verse_flipped
- verse_marked_learned
- verse_marked_difficult
- study_session_completed

Progress and settings:
- progress_opened
- settings_changed

## Core KPIs

1. Time to first package open
2. Download completion rate
3. Time to first study completion
4. Weekly active learners
5. Session frequency per active learner
6. Learned verse growth per week

## Data Governance

1. Event schema versioning
2. PII minimization
3. Analytics opt-out strategy if required
