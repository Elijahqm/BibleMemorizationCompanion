# 17 Package Example - Book of Jude

This is an original template example for a Jude package. It follows the package content schema but keeps the sample content compact so you can adapt it for your real text source.

## Package Overview

- packageId: jude
- title: Jude
- packageType: book
- language: en
- version: 1.0.0
- schemaVersion: 1
- minAppVersion: 1.0.0
- verseCount: 25
- chapterCount: 1

## Suggested Folder Layout

```text
/jude/1.0.0/
  manifest.json
  content/index.json
  content/chapters/001.json
  assets/thumbnail.png
```

## manifest.json

```json
{
  "packageId": "jude",
  "title": "Jude",
  "packageType": "book",
  "language": "en",
  "version": "1.0.0",
  "schemaVersion": 1,
  "minAppVersion": "1.0.0",
  "checksumSha256": "REPLACE_WITH_PACKAGE_ZIP_HASH",
  "createdAt": "2026-07-20T00:00:00Z",
  "verseCount": 25,
  "chapterCount": 1,
  "files": [
    {
      "path": "content/index.json",
      "sizeBytes": 312,
      "checksumSha256": "REPLACE_WITH_INDEX_HASH",
      "required": true
    },
    {
      "path": "content/chapters/001.json",
      "sizeBytes": 2810,
      "checksumSha256": "REPLACE_WITH_CHAPTER_HASH",
      "required": true
    }
  ]
}
```

## content/index.json

```json
{
  "packageId": "jude",
  "abbreviation": "Jude",
  "chapterOrder": [1],
  "chapterVerseCounts": {
    "1": 25
  },
  "availableSections": false,
  "availableAudio": false
}
```

## content/chapters/001.json

The sample below keeps the structure real, but the verse text is shortened so you can swap in your preferred translation or source later.

```json
{
  "chapterNumber": 1,
  "verses": [
    {
      "verseRef": "Jude 1",
      "verseNumber": 1,
      "text": "Jude, a servant of Jesus Christ and brother of James, to those called, loved, and kept."
    },
    {
      "verseRef": "Jude 2",
      "verseNumber": 2,
      "text": "May mercy, peace, and love be multiplied to you."
    },
    {
      "verseRef": "Jude 3",
      "verseNumber": 3,
      "text": "Contend for the faith once delivered to the saints."
    },
    {
      "verseRef": "Jude 4",
      "verseNumber": 4,
      "text": "Certain people have slipped in unnoticed and distort grace into license."
    },
    {
      "verseRef": "Jude 5",
      "verseNumber": 5,
      "text": "The Lord saves a people, even after warnings are given repeatedly."
    },
    {
      "verseRef": "Jude 6",
      "verseNumber": 6,
      "text": "Some did not keep their proper place and are held for judgment."
    },
    {
      "verseRef": "Jude 7",
      "verseNumber": 7,
      "text": "Examples of moral collapse stand as warnings about rebellion."
    },
    {
      "verseRef": "Jude 8",
      "verseNumber": 8,
      "text": "These dreamers defile the body, reject authority, and speak arrogantly."
    },
    {
      "verseRef": "Jude 9",
      "verseNumber": 9,
      "text": "Even Michael did not bring a slanderous accusation, but said, The Lord rebuke you."
    },
    {
      "verseRef": "Jude 10",
      "verseNumber": 10,
      "text": "They speak against what they do not understand and ruin themselves."
    },
    {
      "verseRef": "Jude 11",
      "verseNumber": 11,
      "text": "Woe to those who follow the path of greed, rebellion, and empty gain."
    },
    {
      "verseRef": "Jude 12",
      "verseNumber": 12,
      "text": "They are hidden reefs at your feasts, feeding only themselves."
    },
    {
      "verseRef": "Jude 13",
      "verseNumber": 13,
      "text": "They are like wild waves and wandering stars reserved for darkness."
    },
    {
      "verseRef": "Jude 14",
      "verseNumber": 14,
      "text": "Enoch spoke of the Lord coming with thousands of holy ones."
    },
    {
      "verseRef": "Jude 15",
      "verseNumber": 15,
      "text": "The Lord will judge all and expose every harsh word spoken against him."
    },
    {
      "verseRef": "Jude 16",
      "verseNumber": 16,
      "text": "These people grumble, follow desires, and flatter others for advantage."
    },
    {
      "verseRef": "Jude 17",
      "verseNumber": 17,
      "text": "Remember the words spoken beforehand by the apostles of the Lord."
    },
    {
      "verseRef": "Jude 18",
      "verseNumber": 18,
      "text": "In the last time there will be mockers who follow ungodly desires."
    },
    {
      "verseRef": "Jude 19",
      "verseNumber": 19,
      "text": "They cause division and are guided only by natural instincts."
    },
    {
      "verseRef": "Jude 20",
      "verseNumber": 20,
      "text": "Build yourselves up in faith and pray in the Holy Spirit."
    },
    {
      "verseRef": "Jude 21",
      "verseNumber": 21,
      "text": "Keep yourselves in God's love while waiting for mercy."
    },
    {
      "verseRef": "Jude 22",
      "verseNumber": 22,
      "text": "Show mercy to those who doubt."
    },
    {
      "verseRef": "Jude 23",
      "verseNumber": 23,
      "text": "Save others with caution, and hate even the garment stained by sin."
    },
    {
      "verseRef": "Jude 24",
      "verseNumber": 24,
      "text": "To him who is able to keep you from stumbling and present you blameless."
    },
    {
      "verseRef": "Jude 25",
      "verseNumber": 25,
      "text": "To the only God, be glory, majesty, dominion, and authority forever."
    }
  ]
}
```

## Notes For Real Content

1. Replace the shortened verse text with your chosen translation source.
2. Keep verseRef values stable and consistent across study, progress, and audio files.
3. If you later add audio, create a matching audio/index.json file that maps each verseRef to a track.
4. If you want custom study sections for Jude, add content/sections.json with thematic groupings such as warnings, mercy, and doxology.

## Example Study Section Ideas

1. Jude 1-4: Greeting and purpose
2. Jude 5-10: Warnings from examples
3. Jude 11-16: Character of false teachers
4. Jude 17-23: Call to build and show mercy
5. Jude 24-25: Doxology
