# 03 Scope and Roadmap

## Product Scope Strategy

Use phased delivery with strict boundaries:

1. Foundation: Store, Downloads, package lifecycle.
2. Core Learning Loop: Study creation and verse review.
3. Insight and Retention: Progress and settings polish.
4. Commerce Expansion: Paid audio and entitlements.

## Milestone Plan

## Milestone 0 - Planning and Technical Baseline (1-2 weeks)

Deliverables:
- Finalized app scope and user stories
- Chosen stack and architecture
- Data models and API contracts draft
- Initial UX review and design tokens

Exit criteria:
- Architecture decision record approved
- P0 backlog estimated

## Milestone 1 - Library Store and Downloads (2-4 weeks)

Deliverables:
- Store tab with free packages
- Downloads tab with installed packages
- Download, install, open, delete lifecycle
- Empty states and error states

Exit criteria:
- User can download and open at least one free package end-to-end

## Milestone 2 - Study Creation and Session (3-5 weeks)

Deliverables:
- Create study (chapter, section, custom)
- Verse card front and revealed states
- Learned and difficult markers
- Session progress and resume state

Exit criteria:
- User can complete a full study session and resume later

## Milestone 3 - Progress and Reading Settings (2-3 weeks)

Deliverables:
- Package progress list
- Verse-level progress detail
- Text size, theme, and font settings

Exit criteria:
- Progress view matches study actions with data consistency

## Milestone 4 - Paid Audio Readiness (2-4 weeks)

Deliverables:
- Entitlement-aware store CTAs (Buy, Owned, Download)
- Audio package dependency handling
- Sign-in trigger points and entitlement sync hooks

Exit criteria:
- Paid content model integrated without redesigning store architecture

## Roadmap Risks

1. Package format instability.
2. Offline edge cases in interrupted downloads.
3. Scope creep from non-MVP feature requests.
4. Platform-specific behavior differences (iOS/Android).

## Scope Guardrails

1. If a feature does not improve memorization loop, postpone it.
2. No backend-heavy features without clear MVP need.
3. Prefer hardening existing flows over adding new screens.
