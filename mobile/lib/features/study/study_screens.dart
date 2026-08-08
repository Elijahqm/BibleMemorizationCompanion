import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/errors/app_error.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/widgets/info_panel.dart';
import '../downloads/data/installed_package.dart';
import 'data/models/package_content.dart';
import 'data/models/study.dart';
import 'data/package_content_repository.dart';
import 'study_controller.dart';

enum _VerseFilter { all, difficult, learned }

/// Create study — By chapter / By section / Custom, matching the Round-4
/// wireframe (docs/MVP-Round-4.html, screens 4f/4f2/4f3). Each mode builds a
/// [Study] immediately and replaces this screen with [VerseStudyScreen].
class CreateStudyScreen extends StatefulWidget {
  const CreateStudyScreen({
    super.key,
    required this.package,
    required this.contentRepository,
    required this.studies,
  });

  final InstalledPackage package;
  final PackageContentRepository contentRepository;
  final StudyController studies;

  @override
  State<CreateStudyScreen> createState() => _CreateStudyScreenState();
}

class _CreateStudyScreenState extends State<CreateStudyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 3,
    vsync: this,
  );
  late final Future<PackageContent> _contentFuture = widget.contentRepository
      .load(widget.package);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.createStudy),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.l10n.studyByChapter),
            Tab(text: context.l10n.studyBySection),
            Tab(text: context.l10n.studyCustom),
          ],
        ),
      ),
      body: FutureBuilder<PackageContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: InfoPanel(
                title: context.l10n.studyOpenErrorTitle(widget.package.title),
                body: localizedAppError(context.l10n, error!),
              ),
            );
          }

          final content = snapshot.requireData;
          return TabBarView(
            controller: _tabController,
            children: [
              _ByChapterTab(
                content: content,
                onSelected: (chapter) => _createAndOpen(
                  content,
                  () => widget.studies.createChapterStudy(content, chapter),
                ),
              ),
              _BySectionTab(
                content: content,
                onSelected: (section) => _createAndOpen(
                  content,
                  () => widget.studies.createSectionStudy(content, section),
                ),
              ),
              _CustomTab(
                content: content,
                studies: widget.studies,
                defaultName: context.l10n.defaultStudyName(
                  widget.studies.studiesFor(content.packageId).length + 1,
                ),
                onCreate: (name, verseRefs) => _createAndOpen(
                  content,
                  () => widget.studies.createCustomStudy(
                    packageId: content.packageId,
                    title: name,
                    verseRefs: verseRefs,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createAndOpen(
    PackageContent content,
    Future<Study> Function() create,
  ) async {
    final study = await create();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VerseStudyScreen(
          content: content,
          study: study,
          studies: widget.studies,
        ),
      ),
    );
  }
}

class _ByChapterTab extends StatelessWidget {
  const _ByChapterTab({required this.content, required this.onSelected});

  final PackageContent content;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final chapters = content.index.chapterOrder;
    if (chapters.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: InfoPanel(
          title: context.l10n.noChaptersTitle,
          body: context.l10n.noChaptersBody,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          context.l10n.byChapterHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final chapter in chapters) ...[
          Card(
            child: ListTile(
              title: Text(context.l10n.chapterWithNumber(chapter)),
              subtitle: Text(
                context.l10n.versesCount(
                  content.index.chapterVerseCounts[chapter] ?? 0,
                ),
              ),
              trailing: const Icon(PhosphorIconsRegular.caretRight),
              onTap: () => onSelected(chapter),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BySectionTab extends StatelessWidget {
  const _BySectionTab({required this.content, required this.onSelected});

  final PackageContent content;
  final ValueChanged<ContentSection> onSelected;

  @override
  Widget build(BuildContext context) {
    if (content.sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: InfoPanel(
          title: context.l10n.noSectionsTitle,
          body: context.l10n.noSectionsBody,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          context.l10n.bySectionHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final section in content.sections) ...[
          Card(
            child: ListTile(
              title: Text(section.title),
              subtitle: Text(
                context.l10n.sectionSubtitle(
                  section.rangeLabel,
                  section.verseRefs.length,
                ),
              ),
              trailing: const Icon(PhosphorIconsRegular.caretRight),
              onTap: () => onSelected(section),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CustomTab extends StatefulWidget {
  const _CustomTab({
    required this.content,
    required this.studies,
    required this.defaultName,
    required this.onCreate,
  });

  final PackageContent content;
  final StudyController studies;
  final String defaultName;
  final void Function(String name, List<String> verseRefs) onCreate;

  @override
  State<_CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends State<_CustomTab> {
  final Set<String> _selected = {};
  late final TextEditingController _nameController = TextEditingController(
    text: widget.defaultName,
  );
  _VerseFilter _filter = _VerseFilter.all;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _matchesFilter(String verseRef) {
    final state = widget.studies.stateFor(widget.content.packageId, verseRef);
    return switch (_filter) {
      _VerseFilter.all => true,
      _VerseFilter.difficult => state.isDifficult,
      _VerseFilter.learned => state.isLearned,
    };
  }

  void _toggleChapter(List<String> verseRefs, bool select) {
    setState(() {
      if (select) {
        _selected.addAll(verseRefs);
      } else {
        _selected.removeAll(verseRefs);
      }
    });
  }

  List<String> _orderedSelection() {
    return [
      for (final chapter in widget.content.index.chapterOrder)
        for (final verse in widget.content.versesByChapter[chapter] ?? const [])
          if (_selected.contains(verse.verseRef)) verse.verseRef,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chapters = widget.content.index.chapterOrder;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.filterHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              SegmentedButton<_VerseFilter>(
                segments: [
                  ButtonSegment(
                    value: _VerseFilter.all,
                    label: Text(context.l10n.filterAll),
                  ),
                  ButtonSegment(
                    value: _VerseFilter.difficult,
                    label: Text(context.l10n.filterDifficult),
                  ),
                  ButtonSegment(
                    value: _VerseFilter.learned,
                    label: Text(context.l10n.filterLearned),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) =>
                    setState(() => _filter = selection.first),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final chapter in chapters)
                _buildChapterGroup(context, chapter),
            ],
          ),
        ),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildChapterGroup(BuildContext context, int chapter) {
    final verses = widget.content.versesByChapter[chapter] ?? const [];
    final visible = verses
        .where((v) => _matchesFilter(v.verseRef))
        .toList(growable: false);
    if (visible.isEmpty) return const SizedBox.shrink();

    final allSelected = verses.every((v) => _selected.contains(v.verseRef));

    return ExpansionTile(
      title: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: (value) => _toggleChapter(
              verses.map((v) => v.verseRef).toList(growable: false),
              value ?? false,
            ),
          ),
          Text(context.l10n.chapterWithNumber(chapter)),
        ],
      ),
      children: [
        for (final verse in visible)
          CheckboxListTile(
            value: _selected.contains(verse.verseRef),
            onChanged: (value) => setState(() {
              if (value ?? false) {
                _selected.add(verse.verseRef);
              } else {
                _selected.remove(verse.verseRef);
              }
            }),
            title: Text(verse.verseRef),
            subtitle: Text(
              verse.plainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.l10n.studyNameField,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.versesSelected(_selected.length),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                FilledButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () {
                          final name = _nameController.text.trim();
                          widget.onCreate(
                            name.isEmpty ? widget.defaultName : name,
                            _orderedSelection(),
                          );
                        },
                  child: Text(context.l10n.go),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Verse-by-verse review of one study: tap to reveal, mark Learned/Difficult,
/// resume where you left off. Learned/Difficult are package-scoped, so
/// toggling here is reflected in any other study containing the same verse.
class VerseStudyScreen extends StatefulWidget {
  const VerseStudyScreen({
    super.key,
    required this.content,
    required this.study,
    required this.studies,
  });

  final PackageContent content;
  final Study study;
  final StudyController studies;

  @override
  State<VerseStudyScreen> createState() => _VerseStudyScreenState();
}

class _VerseStudyScreenState extends State<VerseStudyScreen> {
  late final List<Verse> _verses = [
    for (final ref in widget.study.verseRefs)
      if (widget.content.versesByRef[ref] != null)
        widget.content.versesByRef[ref]!,
  ];

  late int _verseIndex = widget.study.lastVerseIndex.clamp(
    0,
    _verses.isEmpty ? 0 : _verses.length - 1,
  );
  bool _revealed = false;

  void _goTo(int index) {
    setState(() {
      _verseIndex = index;
      _revealed = false;
    });
    widget.studies.updateResumeIndex(widget.study, index);
  }

  @override
  Widget build(BuildContext context) {
    if (_verses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.study.title)),
        body: Center(child: Text(context.l10n.studyEmptyBody)),
      );
    }

    final verse = _verses[_verseIndex];
    final progress = (_verseIndex + 1) / _verses.length;
    final state = widget.studies.stateFor(
      widget.study.packageId,
      verse.verseRef,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.study.title),
        actions: [
          IconButton(
            icon: Icon(
              state.isLearned ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.checkCircle,
            ),
            tooltip: context.l10n.filterLearned,
            onPressed: () => setState(() {
              widget.studies.toggleLearned(
                widget.study.packageId,
                verse.verseRef,
              );
            }),
          ),
          IconButton(
            icon: Icon(
              state.isDifficult ? PhosphorIconsFill.flag : PhosphorIconsRegular.flag,
            ),
            tooltip: context.l10n.filterDifficult,
            onPressed: () => setState(() {
              widget.studies.toggleDifficult(
                widget.study.packageId,
                verse.verseRef,
              );
            }),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.content.title} · '
              '${context.l10n.verseProgress(_verseIndex + 1, _verses.length)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _revealed = !_revealed),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verse.verseRef,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _revealed
                                ? _VerseBody(verse: verse)
                                : Text(
                                    context.l10n.revealHint,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontSize: 20, height: 1.6),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (widget.content.attribution.isNotEmpty)
                          Text(
                            context.l10n.creditAttribution(
                              widget.content.attribution,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _verseIndex == 0
                        ? null
                        : () => _goTo(_verseIndex - 1),
                    child: Text(context.l10n.previous),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _verseIndex == _verses.length - 1
                        ? null
                        : () => _goTo(_verseIndex + 1),
                    child: Text(context.l10n.next),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a verse, showing inline section markers as headings.
class _VerseBody extends StatelessWidget {
  const _VerseBody({required this.verse});

  final Verse verse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final segment in verse.segments) ...[
          if (segment.isHeading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(segment.text, style: theme.textTheme.titleMedium),
            )
          else
            Text(
              segment.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                height: 1.6,
              ),
            ),
        ],
      ],
    );
  }
}
