# 08 Data Models and Storage

## Local Data Domains

1. Catalog cache
2. Installed packages
3. Download jobs
4. Studies
5. Verse states
6. User settings

## Core Entities

## PackageCatalogItem

- id
- title
- packageType
- language
- version
- sizeBytes
- isFree
- priceAmount
- priceCurrency
- owned
- artifactUrl
- manifestUrl
- checksumSha256
- minAppVersion
- basePackageId

## InstalledPackage

- packageId
- version
- installedAt
- installPath
- isActive
- packageType
- basePackageId

## DownloadJob

- jobId
- packageId
- status
- progressPercent
- bytesDownloaded
- bytesTotal
- retries
- lastError
- startedAt
- updatedAt

## Study

- studyId
- packageId
- name
- mode (chapter, section, custom)
- verseRefs
- createdAt
- updatedAt

## VerseState

- packageId
- verseRef
- isLearned
- isDifficult
- lastReviewedAt
- reviewCount

## Settings

- theme
- textScale
- fontFamily
- autoplayAudio
- loopAudio

## Persistence Choices

Option A:
- SQLite for structured data
- Local file storage for package assets

Option B:
- NoSQL local store plus file system

Recommendation:
- SQLite + file storage for strong querying and migrations.

## Data Migration Strategy

1. Keep schema version table.
2. Write forward-only migrations.
3. Test migration from N-2 versions minimum.
4. Backup critical user progress before destructive changes.
