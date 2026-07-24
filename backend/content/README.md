# Content packaging process

This document defines, step by step, how we turn raw Bible text into a distributable
package artifact. It is a **living document**: we define one step at a time and only
document a step once we have agreed on it.

## Goal

Turn an authored, human-readable source into the structured files a package needs
(per the schema in [`../../docs/16-package-content-schema.md`](../../docs/16-package-content-schema.md))
and, eventually, into a verified `.zip` artifact served by the API.

## Pipeline overview

```text
source .txt → parse into a reviewable folder → human review & approval → package → wire catalog
  (step 1)          (step 2)                        (step 3)            (step 4)     (step 5)
```

Key rule: **we do not build the `.zip` until the folder content is approved.** The parser
first writes plain, readable JSON files into a folder so they can be inspected. Packaging
(zip + manifest + checksums) only happens after sign-off.

Only the steps marked **Defined** below are final. The rest are placeholders we will
fill in together.

## Tooling

Steps 2 and 4 are implemented by a small .NET console tool at
[`../tools/ContentTool`](../tools/ContentTool) (part of the backend solution, so the whole
repo stays in C#). Each package is registered in the tool's `Packages` list (source file,
id, abbreviation, book title, etc.).

```bash
# from backend/  (the target is the packageId, or "all")
dotnet run --project tools/ContentTool -- parse   cb-daniel-7-12   # step 2: source.txt -> content folder
dotnet run --project tools/ContentTool -- package cb-daniel-7-12   # step 4: content folder -> zip + manifest + sha256
dotnet run --project tools/ContentTool -- build   all             # parse + package for every package
```

The `packageId` is the single identifier — CLI target, source folder, content folder and
artifact folder all use it. The tool is the single source of truth for generation: to fix
or add content, edit `content/{packageId}/source.txt` (and add a `Packages` entry for a new
book), then re-run it.

---

## Step 1 — Single plain-text source file per package · **Defined**

Each package starts life as **one plain-text file** that contains the whole block of
text for that package. We do **not** split it into one file per chapter or per section.

**Why a single file:** chapter and section are two independent groupings. A section can
cross a chapter boundary (e.g. in Daniel, "Visión de Daniel junto al río" spans 10:1–11:1)
or split a chapter in two (Daniel 9 has two sections). Splitting the source by either axis
breaks the other. Keeping one source file preserves all the information; a later parser
step derives both the per-chapter files and the sections from it.

### Location

Each package is identified by its `packageId` (the `cb-`/`bq-` prefix encodes
program + language, so Spanish/English variants never collide). Everything for a
package lives under a folder named after that id:

```text
backend/content/{packageId}/source.txt      # the plain-text source
backend/content/{packageId}/content/        # generated files (step 2)
```

Example: `backend/content/cb-daniel-7-12/source.txt`

### Text format

The source file is written with these conventions so it can be parsed deterministically:

1. **Chapter marker** — a line that contains *only* a number (e.g. `7`) starts a new chapter.
2. **Section marker** — a standalone line of text with no verse numbers is a section title.
3. **Verse marker** — inside the running text, a number glued to the following word marks
   the start of a verse (e.g. `1En el primer año...`, `2Daniel dijo:...`). Multiple verses
   may share a paragraph/line.
4. **Ignored lines** — blank lines and the final source-attribution line are ignored by
   the parser (see Attribution below).

### Attribution (required)

The text is **Reina-Valera Revisada 1960 (RV1960)**. Its use is permitted as long as we
credit it. Every package built from RV1960 text must state that the text is RV1960.

The credit is stored as a single **`attribution`** string in `content/index.json`
(and mirrored into `manifest.json` when the package is built), for example:

```json
"attribution": "REINA-VALERA 1960"
```

We use the same short form already validated on the website (a small `REINA-VALERA 1960`
label shown under the verse).

**Where the app shows it:** the mobile app must display the `attribution` string
wherever the package text is presented, so the credit is always visible with the content:

1. On the **package detail / info** view in the library (before and after download).
2. As a small **credit line in the verse study view**, where the RV1960 text is shown.

The source `.txt` also keeps the attribution line at the end of the file; that line is
ignored by the parser and exists only for traceability of the source.

---

## Step 2 — Parse the source into a reviewable folder · **Defined**

A parser reads the single source `.txt` and writes the structured content as **plain JSON
files inside a folder** (no zip). The folder mirrors the in-package layout so that packaging
later is a straight copy + compress:

```text
backend/content/{packageId}/content/
├─ index.json              # chapterOrder, chapterVerseCounts, availableSections, ...
├─ chapters/
│  ├─ 007.json             # verses for chapter 7 (verseRef, verseNumber, text, sectionId)
│  ├─ 008.json
│  └─ ...
└─ sections.json           # section ranges, including cross-chapter ones
```

Rules:

1. Output is **human-readable** (pretty-printed JSON) so it can be reviewed by eye.
2. **No `.zip`, no manifest, no checksums yet** — those belong to Step 4.
3. We generate and review **incrementally** (e.g. one chapter first) before doing the rest.

## Step 3 — Human review & approval · **Defined**

We inspect the generated folder (chapters, sections, index) and only continue once it is
approved. Nothing is packaged before sign-off.

## Step 4 — Package (zip + manifest + checksums) · **Defined**

Once approved, we build the distributable artifact for `{packageId}/{version}`:

```text
wwwroot/packages/{packageId}/{version}/
├─ package.zip        # contains manifest.json + content/ (index, chapters, sections)
├─ manifest.json      # served copy (same file that is inside the zip)
└─ package.sha256     # SHA-256 of package.zip
```

`manifest.json` carries the package metadata plus a `files[]` list, where every content
file has its own `sizeBytes` and `checksumSha256` (per-file integrity after extraction).

**Checksum model (resolves the circular example in doc 16):**

- The **zip-level** SHA-256 lives in **`package.sha256`** and in the **catalog**
  (`checksumSha256`). This is what the app checks right after download.
- The **per-file** SHA-256 values live inside `manifest.files[]`, checked after extraction.
- The manifest does **not** embed its own zip's hash (impossible: the manifest is inside
  the zip). We omit that circular top-level field.

**Reproducible builds:** the zip is written with a fixed entry order and a fixed timestamp,
and `manifest.createdAt` is fixed, so rebuilding the same content yields the same bytes and
therefore the same checksum.

## Step 5 — Wire the artifact into the catalog · _to be defined_
