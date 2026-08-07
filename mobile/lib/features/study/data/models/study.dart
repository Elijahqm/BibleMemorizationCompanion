/// How a study's verse list was assembled.
enum StudyMode {
  chapter,
  section,
  custom;

  static StudyMode parse(String? value) {
    switch (value) {
      case 'chapter':
        return StudyMode.chapter;
      case 'section':
        return StudyMode.section;
      default:
        return StudyMode.custom;
    }
  }
}

/// A user-created study: a named, ordered list of verses from one installed
/// package, built via the Create study flow (by chapter, by section, or by
/// hand-picking verses). Studies are never generated automatically.
class Study {
  const Study({
    required this.id,
    required this.packageId,
    required this.title,
    required this.mode,
    required this.verseRefs,
    required this.createdAt,
    this.lastVerseIndex = 0,
    DateTime? lastOpenedAt,
  }) : lastOpenedAt = lastOpenedAt ?? createdAt;

  factory Study.fromJson(Map<String, dynamic> json) {
    final refs = json['verseRefs'];
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return Study(
      id: json['id'] as String? ?? '',
      packageId: json['packageId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      mode: StudyMode.parse(json['mode'] as String?),
      verseRefs: refs is List
          ? refs.whereType<String>().toList(growable: false)
          : const <String>[],
      createdAt: createdAt,
      lastVerseIndex: (json['lastVerseIndex'] as num?)?.toInt() ?? 0,
      lastOpenedAt: DateTime.tryParse(json['lastOpenedAt'] as String? ?? ''),
    );
  }

  final String id;
  final String packageId;
  final String title;
  final StudyMode mode;
  final List<String> verseRefs;
  final DateTime createdAt;
  final int lastVerseIndex;
  final DateTime lastOpenedAt;

  Study copyWith({int? lastVerseIndex, DateTime? lastOpenedAt}) => Study(
    id: id,
    packageId: packageId,
    title: title,
    mode: mode,
    verseRefs: verseRefs,
    createdAt: createdAt,
    lastVerseIndex: lastVerseIndex ?? this.lastVerseIndex,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'packageId': packageId,
    'title': title,
    'mode': mode.name,
    'verseRefs': verseRefs,
    'createdAt': createdAt.toIso8601String(),
    'lastVerseIndex': lastVerseIndex,
    'lastOpenedAt': lastOpenedAt.toIso8601String(),
  };
}
