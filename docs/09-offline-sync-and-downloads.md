# 09 Offline, Sync, and Downloads

## Offline-First Principles

1. App remains useful without network after at least one package install.
2. Core memorization features never require live backend calls.
3. Network operations are retriable and resumable.

## Data Availability Matrix

Online required:
- Fresh Store catalog
- Purchase and entitlement validation (future)

Offline available:
- Installed packages
- Existing studies
- Verse review and progress updates
- Settings

## Download Workflow

1. Request package download.
2. Create download job in local DB.
3. Stream file to temp path.
4. Verify checksum.
5. Install package files atomically.
6. Mark package installed.
7. Remove from Store list and show in Downloads.

## Resilience Requirements

1. Interrupted app session resumes pending downloads.
2. Corrupt temp files are cleaned safely.
3. Duplicate download requests collapse to single job.
4. Install step is transactional from user perspective.

## Sync Strategy (Future)

1. Keep local-first progress.
2. Add optional account sync for backup and cross-device use.
3. Resolve conflicts by latest review timestamp and deterministic rules.

## Failure States to Design in UI

1. No internet
2. Download paused or interrupted
3. Verification failed
4. Insufficient storage
5. Package incompatible with app version
