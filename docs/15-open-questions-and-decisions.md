# 15 Open Questions and Decisions

Use this document as a living decision log.

## Pending Product Questions

1. What is the initial launch audience: individual learners, program participants, or both?
2. Which Bible translations and languages are in the first package set?
3. Should first release require account creation for anything, or remain fully guest-friendly?
4. Will audio ship in MVP or immediately after MVP?

## Pending Technical Questions

1. Preferred mobile stack: .NET MAUI, Flutter, or React Native?
2. Preferred backend stack: ASP.NET Core API confirmed?
3. Do we use direct CDN links in catalog, signed URLs, or proxy download through API?
4. What package archive format should be canonical?
5. Do we need delta updates for package versions in v1?

## Pending Operations Questions

1. Where will package artifacts be hosted (Azure Blob, S3, other)?
2. Who publishes catalog updates and how is approval handled?
3. What is the release cadence for new packages?

## Recommended Decision Sequence

1. Confirm product scope and launch audience.
2. Confirm stack and hosting choices.
3. Freeze package schema and API contract.
4. Build Milestone 1 with free packages.
5. Add entitlement and paid audio.

## Suggested Next Workshop Agenda

1. 30 minutes: Product scope and MVP boundaries.
2. 30 minutes: Architecture and stack finalization.
3. 30 minutes: Store and package contract review.
4. 30 minutes: Backlog and milestone assignments.

## Decision Log

### Decision Template

- Date:
- Decision:
- Context:
- Options considered:
- Chosen option:
- Consequences:
- Owner:

### Entries

- Date: 2026-07-20
- Decision: Mobile stack set to Flutter
- Context: Fast cross-platform UI delivery for MVP
- Options considered: .NET MAUI, Flutter, React Native
- Chosen option: Flutter
- Consequences: Dart-based frontend and Flutter ecosystem tooling
- Owner: Product and engineering

- Date: 2026-07-20
- Decision: Store backend set to ASP.NET Core Web API
- Context: Need stable catalog API and future entitlement support
- Options considered: ASP.NET Core, no backend in phase 1
- Chosen option: ASP.NET Core Web API
- Consequences: C# backend contracts and deployment pipeline
- Owner: Product and engineering

- Date: 2026-07-20
- Decision: Initial hosting uses own VPS
- Context: Control cost and infrastructure during early phase
- Options considered: Azure Blob + CDN, S3 + CloudFront, own VPS
- Chosen option: Own VPS
- Consequences: Need to manage reliability, storage, and TLS operations directly
- Owner: Product and engineering

- Date: 2026-07-20
- Decision: MVP Store supports free downloads with paid audio UI stubs
- Context: Prioritize front-end flow while preparing future monetization
- Options considered: Free only, free plus audio stubs, full paid audio
- Chosen option: Free plus paid audio UI stubs
- Consequences: CTA logic supports Buy and Owned states before commerce integration
- Owner: Product and engineering

- Date: 2026-07-20
- Decision: Guest-first app behavior
- Context: Reduce onboarding friction and maximize early usage
- Options considered: Guest-first, mandatory sign-in, sign-in for purchases only
- Chosen option: Guest-first
- Consequences: Free workflows available without account, sign-in deferred to paid purchases and sync
- Owner: Product and engineering

- Date: 2026-07-20
- Decision: Initial launch package set defined
- Context: Need concrete content targets for Milestone 1
- Options considered: Multiple draft package sets
- Chosen option: CB Daniel 1-6, CB Daniel 7-12, CB Hechos 1-9, BQ Daniel 7-12, BQ Acts 1-9
- Consequences: Catalog and package publishing plan can proceed with fixed identifiers
- Owner: Product and engineering

- Date: 2026-07-20
- Decision: Skip GET /api/v1/catalog/version endpoint
- Context: Users will rarely visit Store (typically once or twice per year)
- Options considered: Separate version check endpoint versus direct catalog fetch
- Chosen option: Direct catalog fetch with HTTP caching headers
- Consequences: Simpler backend API in MVP, fewer endpoints to maintain
- Owner: Product and engineering
