# 04 System Architecture

## Architecture Overview

The app architecture should separate concerns clearly:

1. Mobile Client Layer
- UI and navigation
- View models and state management
- Local persistence and offline queue

2. Domain Layer
- Package management
- Study lifecycle and memorization logic
- Progress aggregation

3. Data Layer
- Remote catalog API client
- Download and install manager
- Local database and file system access

4. Backend Services
- Catalog and metadata API
- Entitlements and account integration (future)
- Artifact file hosting via CDN/object storage

## Recommended Deployment Shape

1. Mobile app binary for iOS and Android.
2. API service for catalog and metadata.
3. Object storage + CDN for package binaries and manifests.
4. Optional admin ingestion pipeline for package publishing.

## Stack Options

### Option A: .NET Mobile + ASP.NET Backend

Frontend:
- .NET MAUI

Backend:
- ASP.NET Core Web API

Pros:
- Single language across client and server
- Strong typing and shared contracts
- Good fit if team is C#-heavy

Cons:
- MAUI ecosystem is smaller than Flutter/React Native for some UI libraries

### Option B: Flutter + ASP.NET Backend

Frontend:
- Flutter

Backend:
- ASP.NET Core Web API

Pros:
- Excellent cross-platform UI control
- Mature mobile dev ecosystem

Cons:
- Two primary languages across stack (Dart and C#)

### Option C: React Native + Node or ASP.NET Backend

Frontend:
- React Native

Backend:
- Node.js or ASP.NET Core

Pros:
- Large ecosystem and talent pool

Cons:
- More architecture discipline needed for long-term maintainability

## Recommendation for This Project

Current decision:

- Frontend: Flutter (Dart)
- Backend: ASP.NET Core Web API
- Hosting: Own VPS for API and package artifacts

Implementation note:
- Keep the API and package contracts framework-agnostic so the mobile app and backend can evolve independently.

## High-Level Component Diagram

1. App UI -> Domain services -> Local DB + File store
2. Domain services -> Catalog API client
3. Download manager -> CDN package files
4. Installer -> Validates manifest and checksum
5. Progress service -> Aggregates local verse states

## Non-Functional Requirements

1. App remains usable offline after package install.
2. Download failures are recoverable without data corruption.
3. Package install is atomic and verifiable.
4. App launch should be fast even with multiple installed packages.
