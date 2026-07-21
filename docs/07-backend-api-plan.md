# 07 Backend API Plan

## Backend Purpose

Provide catalog metadata and support future entitlement-aware store behavior.

## Project Type

Recommended backend project:
- ASP.NET Core Web API

Current decision:
- Confirmed: ASP.NET Core Web API

## API Surface (Phase 1)

1. GET /api/v1/catalog
- Returns list of all available packages

2. GET /api/v1/catalog/packages/{id}
- Returns package details

## API Surface (Phase 2 for Audio)

1. GET /api/v1/entitlements
- Returns owned paid items for signed-in user

2. GET /api/v1/users/me
- Identity and account state

## Response Design Guidelines

1. Stable ids and semantic versions.
2. Explicit enum-like strings for packageType and install compatibility.
3. Include checksum and artifact URLs in package payload.
4. Keep nullable fields explicit for paid-only attributes.

## Example Catalog Response Shape

- catalogVersion
- publishedAt
- packages array

Each package:
- id
- title
- packageType
- language
- version
- sizeBytes
- isFree
- price
- owned
- artifactUrl
- manifestUrl
- checksumSha256
- minAppVersion

## Backend Implementation Approach

1. Start with static JSON-backed repository for fast iteration.
2. Add database-backed catalog later if needed.
3. Keep authentication optional for free-only phase.
4. Do not implement a catalog version endpoint for now; rely on normal HTTP caching headers and occasional full catalog refresh.

Guest-first note:

1. Do not require sign-in for browsing Store, downloading free packages, opening packages, or creating studies.
2. Reserve sign-in flows for future paid purchases and account sync.

## Operational Requirements

1. CDN-backed file URLs.
2. HTTPS only.
3. Basic rate limiting.
4. Structured logging and request tracing.
