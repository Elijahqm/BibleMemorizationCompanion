import 'package:flutter/foundation.dart';

import 'data/active_package_store.dart';
import 'data/models/study.dart';
import 'data/models/verse_state.dart';
import 'data/study_store.dart';
import 'data/verse_state_store.dart';
import 'data/models/package_content.dart';

/// Owns user-created studies, per-verse learned/difficult state, and which
/// package is currently "active" (last opened) — the data the wireframe's
/// Create-study flow and My Studies screen are built on. Studies are never
/// generated automatically; they only exist once created here.
class StudyController extends ChangeNotifier {
  StudyController({
    StudyStore? studyStore,
    VerseStateStore? verseStateStore,
    ActivePackageStore? activePackageStore,
  }) : _studyStore = studyStore ?? StudyStore(),
       _verseStateStore = verseStateStore ?? VerseStateStore(),
       _activePackageStore = activePackageStore ?? ActivePackageStore();

  final StudyStore _studyStore;
  final VerseStateStore _verseStateStore;
  final ActivePackageStore _activePackageStore;

  List<Study> _studies = const [];
  Map<String, VerseState> _verseStates = const {};
  String? _activePackageId;
  bool _disposed = false;

  String? get activePackageId => _activePackageId;

  Future<void> load() async {
    _studies = await _studyStore.load();
    _verseStates = await _verseStateStore.load();
    _activePackageId = await _activePackageStore.load();
    _notify();
  }

  Future<void> setActivePackage(String packageId) async {
    _activePackageId = packageId;
    await _activePackageStore.save(packageId);
    _notify();
  }

  /// Studies for [packageId], most-recently-opened first — the top entry is
  /// the one the user was last studying.
  List<Study> studiesFor(String packageId) {
    final studies = _studies.where((s) => s.packageId == packageId).toList();
    studies.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    return studies;
  }

  /// Bumps [study] to the front of `studiesFor` — call whenever it's opened.
  Future<void> markOpened(Study study) async {
    _studies = [
      for (final existing in _studies)
        if (existing.id == study.id)
          existing.copyWith(lastOpenedAt: DateTime.now())
        else
          existing,
    ];
    await _studyStore.save(_studies);
    _notify();
  }

  Future<Study> createChapterStudy(PackageContent content, int chapter) {
    final verses = content.versesByChapter[chapter] ?? const [];
    return _createStudy(
      packageId: content.packageId,
      title: '${content.title} Chapter $chapter',
      mode: StudyMode.chapter,
      verseRefs: verses.map((v) => v.verseRef).toList(growable: false),
    );
  }

  Future<Study> createSectionStudy(PackageContent content, ContentSection section) {
    return _createStudy(
      packageId: content.packageId,
      title: section.title,
      mode: StudyMode.section,
      verseRefs: section.verseRefs,
    );
  }

  Future<Study> createCustomStudy({
    required String packageId,
    required String title,
    required List<String> verseRefs,
  }) {
    return _createStudy(
      packageId: packageId,
      title: title,
      mode: StudyMode.custom,
      verseRefs: verseRefs,
    );
  }

  Future<Study> _createStudy({
    required String packageId,
    required String title,
    required StudyMode mode,
    required List<String> verseRefs,
  }) async {
    final study = Study(
      id: '$packageId-${DateTime.now().microsecondsSinceEpoch}',
      packageId: packageId,
      title: title,
      mode: mode,
      verseRefs: verseRefs,
      createdAt: DateTime.now(),
    );
    _studies = [..._studies, study];
    await _studyStore.save(_studies);
    _notify();
    return study;
  }

  Future<void> deleteStudy(Study study) async {
    _studies = _studies.where((s) => s.id != study.id).toList(growable: false);
    await _studyStore.save(_studies);
    _notify();
  }

  Future<void> updateResumeIndex(Study study, int index) async {
    _studies = [
      for (final existing in _studies)
        if (existing.id == study.id)
          existing.copyWith(lastVerseIndex: index)
        else
          existing,
    ];
    await _studyStore.save(_studies);
    _notify();
  }

  VerseState stateFor(String packageId, String verseRef) {
    return _verseStates['$packageId::$verseRef'] ??
        VerseState(packageId: packageId, verseRef: verseRef);
  }

  Future<void> toggleLearned(String packageId, String verseRef) {
    return _updateVerseState(
      packageId,
      verseRef,
      (state) => state.copyWith(isLearned: !state.isLearned),
    );
  }

  Future<void> toggleDifficult(String packageId, String verseRef) {
    return _updateVerseState(
      packageId,
      verseRef,
      (state) => state.copyWith(isDifficult: !state.isDifficult),
    );
  }

  Future<void> _updateVerseState(
    String packageId,
    String verseRef,
    VerseState Function(VerseState current) update,
  ) async {
    final current = stateFor(packageId, verseRef);
    final updated = update(current).copyWith(
      lastReviewedAt: DateTime.now(),
      reviewCount: current.reviewCount + 1,
    );
    _verseStates = {..._verseStates, updated.key: updated};
    await _verseStateStore.save(_verseStates);
    _notify();
  }

  /// `(learned, total)` for one study, derived from the package's verse
  /// states — learned/difficult marks are shared across every study that
  /// includes a given verse.
  (int, int) progressFor(Study study) {
    final learned = study.verseRefs
        .where((ref) => stateFor(study.packageId, ref).isLearned)
        .length;
    return (learned, study.verseRefs.length);
  }

  /// `(learned, total)` aggregate for the Progress tab.
  (int, int) packageProgress(String packageId, int totalVerses) {
    final learned = _verseStates.values
        .where((state) => state.packageId == packageId && state.isLearned)
        .length;
    return (learned, totalVerses);
  }

  /// Cascades a package uninstall: its studies and verse states no longer
  /// make sense once the content is gone.
  Future<void> onPackageUninstalled(String packageId) async {
    _studies = _studies
        .where((s) => s.packageId != packageId)
        .toList(growable: false);
    _verseStates = {
      for (final entry in _verseStates.entries)
        if (entry.value.packageId != packageId) entry.key: entry.value,
    };
    if (_activePackageId == packageId) _activePackageId = null;
    await _studyStore.save(_studies);
    await _verseStateStore.save(_verseStates);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
