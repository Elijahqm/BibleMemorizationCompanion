# 16 Package Content Schema

This document defines the internal content model inside each package artifact.

## Purpose

The catalog tells the app what to download. This schema tells the app how to read the downloaded package contents.

## Package File Structure

Each package zip should contain:

1. manifest.json
2. content/index.json
3. content/chapters/*.json
4. optional content/sections.json
5. optional audio/index.json (for audio add-ons)
6. assets/thumbnail.png (optional)

Example:

- /manifest.json
- /content/index.json
- /content/chapters/001.json
- /content/chapters/002.json
- /content/sections.json
- /audio/index.json

## manifest.json

Top-level metadata for installation and validation.

Fields:

1. packageId
2. title
3. packageType (book, season, audio_addon)
4. language
5. version
6. schemaVersion
7. minAppVersion
8. createdAt
9. verseCount
10. chapterCount
11. basePackageId (required for audio_addon)
12. files array

files array entry:

1. path
2. sizeBytes
3. checksumSha256
4. required (true or false)

### Integrity model

Integrity is verified at two levels, and the manifest owns only the second one:

1. **Package level** — the SHA-256 of `package.zip` lives in the catalog entry
   (`checksumSha256` in `GET /api/v1/catalog`), and is also published next to the
   artifact as `package.sha256`. The app validates it *before* extracting.
2. **File level** — `manifest.files[].checksumSha256` covers each extracted file. The
   app validates these *after* extracting.

The manifest deliberately has **no** top-level `checksumSha256`. `manifest.json` ships
inside `package.zip`, so it cannot carry the hash of the archive that contains it —
writing the hash in would change the archive, and therefore the hash. The catalog is
the canonical source for package-level integrity precisely because it is served
independently of the artifact it describes.

## content/index.json

Fast lookup metadata to open package quickly.

Fields:

1. packageId
2. abbreviation
3. attribution (optional)
4. chapterOrder array
5. chapterVerseCounts map
6. availableSections boolean
7. availableAudio boolean

### attribution

Optional single string with the required source/text credit (for example, the Bible
translation used). When present, the app must display it wherever the package text is
shown, so the credit stays visible with the content:

1. On the package detail / info view in the library.
2. As a small credit line in the verse study view.

Example: `"REINA-VALERA 1960"`

## content/chapters/{nnn}.json

Chapter-level verse payload.

Fields:

1. chapterNumber
2. verses array

Verse object:

1. verseRef (example: Dan 1:1)
2. verseNumber
3. text (may contain an inline section-title marker — see below)
4. normalizedText (optional for search/matching)

A verse does **not** carry a `sectionId`. Section membership lives entirely in
`content/sections.json` (see below); the verse only carries an inline marker in `text`
when a section *starts* at (or inside) that verse.

### Inline section-title marker

When a section begins at a verse, the section title is embedded **inside** the verse
`text` as a marker, so the client can render it with different formatting (a heading)
right where it belongs:

```text
[[section:{sectionId}|{title}]]
```

- At the **start** of a verse, the marker is the first thing in `text`.
- **Mid-verse** (a title that splits a single verse), the marker sits at the split point
  inside `text`; the text before it is the tail of the previous section and the text after
  it begins the new section — all shown on the same verse card.

Client rendering rules:

1. Split `text` on the marker(s).
2. Render the captured `{title}` as a section heading (distinct style), and use
   `{sectionId}` to link it to the matching entry in `sections.json`.
3. Render the surrounding text as normal verse text.

Example (`Acts 9:19`, whose second half opens a new section):

```json
{
  "verseRef": "Acts 9:19",
  "verseNumber": 19,
  "text": "And when he had received meat, he was strengthened. [[section:saul-preaches-at-damascus|Saul Preaches at Damascus]] Then was Saul certain days with the disciples which were at Damascus."
}
```

## content/sections.json (optional)

Section-based study creation source, and the **single source of truth for section
membership**. Each section lists exactly which whole verses it contains.

section object fields:

1. sectionId
2. title
3. startVerseRef
4. endVerseRef
5. verseRefs array

**Overlap is allowed.** When a section starts mid-verse, that whole verse belongs to
**both** the ending and the starting section, so the same `verseRef` appears in both
`verseRefs` arrays (e.g. `Acts 9:19` is the last verse of "The Conversion of Saul" and the
first verse of "Saul Preaches at Damascus"). Selecting either section studies the complete
verse.

## audio/index.json (audio add-on only)

Maps verse references to audio files and timing.

Fields:

1. packageId
2. basePackageId
3. version
4. tracks array

Track object:

1. verseRef
2. filePath
3. durationMs
4. cueInMs (optional)
5. cueOutMs (optional)

## App Parsing Rules

1. Reject the download if the SHA-256 of `package.zip` does not match the catalog's
   `checksumSha256`. Verify this before extracting anything.
2. Reject package if manifest.schemaVersion is unsupported.
3. Reject package if required files are missing.
4. Reject package if any extracted file does not match its
   `manifest.files[].checksumSha256`.
5. Mark package installed only after all required files parse successfully.

## Schema Versioning

1. Start with schemaVersion 1.
2. Support backward compatibility for at least one previous version where possible.
3. Use migration adapters in app parser when introducing schemaVersion 2.

## Example manifest.json

```json
{
  "packageId": "cb-daniel-1-6",
  "title": "CB Daniel 1-6",
  "packageType": "book",
  "language": "es",
  "version": "1.0.0",
  "schemaVersion": 1,
  "minAppVersion": "1.0.0",
  "createdAt": "2026-07-20T00:00:00Z",
  "verseCount": 120,
  "chapterCount": 6,
  "files": [
    {
      "path": "content/index.json",
      "sizeBytes": 2048,
      "checksumSha256": "<sha256>",
      "required": true
    },
    {
      "path": "content/chapters/001.json",
      "sizeBytes": 5120,
      "checksumSha256": "<sha256>",
      "required": true
    }
  ]
}
```

## Notes for Current MVP

1. Keep text packages simple and immutable by version.
2. Audio can be modeled now but shipped later.
3. Keep verseRef format consistent across all files and APIs.
