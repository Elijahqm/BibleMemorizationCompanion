/// Learned/difficult status for one verse of one package.
///
/// Scoped to the package (not to any single study), so marking a verse
/// learned is reflected everywhere that verse appears — including in other
/// studies that happen to include it.
class VerseState {
  const VerseState({
    required this.packageId,
    required this.verseRef,
    this.isLearned = false,
    this.isDifficult = false,
    this.lastReviewedAt,
    this.reviewCount = 0,
  });

  factory VerseState.fromJson(Map<String, dynamic> json) {
    return VerseState(
      packageId: json['packageId'] as String? ?? '',
      verseRef: json['verseRef'] as String? ?? '',
      isLearned: json['isLearned'] as bool? ?? false,
      isDifficult: json['isDifficult'] as bool? ?? false,
      lastReviewedAt: DateTime.tryParse(
        json['lastReviewedAt'] as String? ?? '',
      ),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String packageId;
  final String verseRef;
  final bool isLearned;
  final bool isDifficult;
  final DateTime? lastReviewedAt;
  final int reviewCount;

  String get key => '$packageId::$verseRef';

  VerseState copyWith({
    bool? isLearned,
    bool? isDifficult,
    DateTime? lastReviewedAt,
    int? reviewCount,
  }) => VerseState(
    packageId: packageId,
    verseRef: verseRef,
    isLearned: isLearned ?? this.isLearned,
    isDifficult: isDifficult ?? this.isDifficult,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    reviewCount: reviewCount ?? this.reviewCount,
  );

  Map<String, dynamic> toJson() => {
    'packageId': packageId,
    'verseRef': verseRef,
    'isLearned': isLearned,
    'isDifficult': isDifficult,
    if (lastReviewedAt != null)
      'lastReviewedAt': lastReviewedAt!.toIso8601String(),
    'reviewCount': reviewCount,
  };
}
