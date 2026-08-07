/// Metadata from `content/index.json`.
class PackageIndex {
  const PackageIndex({
    required this.packageId,
    required this.abbreviation,
    required this.attribution,
    required this.chapterOrder,
    required this.chapterVerseCounts,
    required this.availableSections,
  });

  factory PackageIndex.fromJson(Map<String, dynamic> json) {
    final order = json['chapterOrder'];
    final counts = json['chapterVerseCounts'];
    return PackageIndex(
      packageId: json['packageId'] as String? ?? '',
      abbreviation: json['abbreviation'] as String? ?? '',
      attribution: json['attribution'] as String? ?? '',
      chapterOrder: order is List
          ? order.whereType<num>().map((n) => n.toInt()).toList(growable: false)
          : const <int>[],
      chapterVerseCounts: counts is Map<String, dynamic>
          ? counts.map(
              (key, value) =>
                  MapEntry(int.tryParse(key) ?? 0, (value as num?)?.toInt() ?? 0),
            )
          : const <int, int>{},
      availableSections: json['availableSections'] as bool? ?? false,
    );
  }

  final String packageId;
  final String abbreviation;
  final String attribution;
  final List<int> chapterOrder;
  final Map<int, int> chapterVerseCounts;
  final bool availableSections;

  int get verseCount =>
      chapterVerseCounts.values.fold(0, (total, count) => total + count);
}

/// A study section from `content/sections.json`.
class ContentSection {
  const ContentSection({
    required this.sectionId,
    required this.title,
    required this.startVerseRef,
    required this.endVerseRef,
    required this.verseRefs,
  });

  factory ContentSection.fromJson(Map<String, dynamic> json) {
    final refs = json['verseRefs'];
    return ContentSection(
      sectionId: json['sectionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startVerseRef: json['startVerseRef'] as String? ?? '',
      endVerseRef: json['endVerseRef'] as String? ?? '',
      verseRefs: refs is List
          ? refs.whereType<String>().toList(growable: false)
          : const <String>[],
    );
  }

  final String sectionId;
  final String title;
  final String startVerseRef;
  final String endVerseRef;
  final List<String> verseRefs;

  String get rangeLabel => startVerseRef == endVerseRef
      ? startVerseRef
      : '$startVerseRef – $endVerseRef';
}

/// One piece of a verse: either scripture text or an inline section heading.
class VerseSegment {
  const VerseSegment.text(this.text) : sectionId = null;
  const VerseSegment.heading(this.text, this.sectionId);

  final String text;
  final String? sectionId;

  bool get isHeading => sectionId != null;
}

/// A verse from `content/chapters/{n}.json`.
class Verse {
  const Verse({
    required this.verseRef,
    required this.verseNumber,
    required this.text,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      verseRef: json['verseRef'] as String? ?? '',
      verseNumber: (json['verseNumber'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
    );
  }

  static final _markerPattern = RegExp(r'\[\[section:([^\]|]+)\|([^\]]*)\]\]');

  final String verseRef;
  final int verseNumber;
  final String text;

  /// Splits [text] on inline `[[section:id|Title]]` markers so headings can be
  /// rendered differently from the scripture around them.
  List<VerseSegment> get segments {
    final segments = <VerseSegment>[];
    var cursor = 0;

    for (final match in _markerPattern.allMatches(text)) {
      final before = text.substring(cursor, match.start).trim();
      if (before.isNotEmpty) segments.add(VerseSegment.text(before));
      segments.add(
        VerseSegment.heading(match.group(2)!.trim(), match.group(1)!),
      );
      cursor = match.end;
    }

    final tail = text.substring(cursor).trim();
    if (tail.isNotEmpty) segments.add(VerseSegment.text(tail));
    return segments;
  }

  /// The verse without section markers, for compact previews.
  String get plainText => text.replaceAll(_markerPattern, ' ').trim();
}

/// Everything the study flow needs from one installed package.
class PackageContent {
  const PackageContent({
    required this.packageId,
    required this.title,
    required this.index,
    required this.sections,
    required this.versesByRef,
    required this.versesByChapter,
  });

  final String packageId;
  final String title;
  final PackageIndex index;
  final List<ContentSection> sections;
  final Map<String, Verse> versesByRef;

  /// Verses grouped by chapter, in on-disk order — used to build "by
  /// chapter" studies and the Custom tab's chapter-grouped checklist.
  final Map<int, List<Verse>> versesByChapter;

  String get attribution => index.attribution;

  List<Verse> versesFor(ContentSection section) => [
    for (final ref in section.verseRefs)
      if (versesByRef[ref] != null) versesByRef[ref]!,
  ];
}
