# 06 Store and Content Delivery

## Store Scope for Phase 1

Build free package flow first, but keep paid audio-ready architecture.

Current decision:

1. Free packages are fully functional in v1.
2. Paid audio appears as UI stubs (Buy and Owned states), without full purchase backend.

## Functional Requirements

1. List catalog items in Store tab.
2. Download free package.
3. Show active download progress.
4. Install package after verification.
5. Move installed item to Downloads tab.
6. Open installed package.
7. Delete installed package with confirmation.

## Catalog Item Model

Required fields:

1. id
2. title
3. packageType (book, season, audio_addon)
4. language
5. version
6. sizeBytes
7. isFree
8. priceAmount
9. priceCurrency
10. owned
11. installState
12. basePackageId (for audio add-on dependency)
13. artifactUrl
14. manifestUrl
15. checksumSha256

## CTA Rules

1. isInstalled -> Open
2. free and notInstalled -> Download
3. paid and notOwned -> Buy
4. paid and owned and notInstalled -> Download
5. downloading -> Progress + cancel/pause action (optional first version)

## Package Hosting Layout

Recommended path pattern:

1. catalog endpoint
2. immutable package versions
3. manifest and checksum per version

Example hierarchy:

- /catalog/catalog.v1.json
- /packages/gospel-john/1.0.0/manifest.json
- /packages/gospel-john/1.0.0/package.zip
- /packages/gospel-john/1.0.0/package.sha256
- /addons/gospel-john-audio/1.0.0/manifest.json

## Hosting Decision

Current decision:

1. Use own VPS for hosting API and package artifacts in the initial phase.
2. Keep package paths immutable by version.
3. Add CDN in front of VPS later if traffic increases.

## Download and Install State Machine

States:

1. idle
2. queued
3. downloading
4. verifying
5. installing
6. installed
7. failed

Rules:
- Never mark installed before verification and install complete.
- Keep idempotent install step.
- Preserve failure reason for user-friendly retry.

## Error Handling

1. Network timeout -> Retry with backoff.
2. Checksum mismatch -> Fail hard and redownload.
3. Low storage -> Show storage guidance and stop.
4. Corrupt zip -> Discard temp files and retry.

## Free Now, Paid Later Strategy

Implement paid fields now in model and UI resolver, but hide purchase entry points until payment and entitlement service is ready.
