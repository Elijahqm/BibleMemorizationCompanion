import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/errors/app_error.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/app_locale.dart';
import '../../core/l10n/presentation.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/info_panel.dart';
import '../catalog/catalog_controller.dart';
import '../catalog/data/catalog_repository.dart';
import '../catalog/data/models/catalog_package.dart';
import '../catalog/data/models/package_manifest.dart';
import '../downloads/data/installed_package.dart';
import '../downloads/data/package_downloader.dart';
import '../downloads/download_controller.dart';
import '../study/data/models/package_content.dart';
import '../study/data/models/study.dart';
import '../study/data/models/verse_state.dart';
import '../study/data/package_content_repository.dart';
import '../study/study_controller.dart';
import '../study/study_screens.dart';

enum LibraryPane { downloads, store }

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.catalogController,
    this.downloadController,
    this.contentRepository,
    this.studyController,
  });

  /// Injectable for tests; defaults to controllers backed by the real API.
  final CatalogController? catalogController;
  final DownloadController? downloadController;
  final PackageContentRepository? contentRepository;
  final StudyController? studyController;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PackageContentRepository _content =
      widget.contentRepository ?? PackageContentRepository();

  late final CatalogController _catalog;
  late final DownloadController _downloads;
  late final StudyController _studies;
  late final bool _ownsCatalog;
  late final bool _ownsDownloads;
  late final bool _ownsStudies;

  int _currentIndex = 0;
  LibraryPane _libraryPane = LibraryPane.store;

  @override
  void initState() {
    super.initState();
    _ownsCatalog = widget.catalogController == null;
    _ownsDownloads = widget.downloadController == null;
    _ownsStudies = widget.studyController == null;
    _catalog = widget.catalogController ?? CatalogController();
    _downloads = widget.downloadController ?? DownloadController();
    _studies = widget.studyController ?? StudyController();
    _catalog.load();
    _downloads.loadInstalled();
    _studies.load();
  }

  @override
  void dispose() {
    if (_ownsCatalog) _catalog.dispose();
    if (_ownsDownloads) _downloads.dispose();
    if (_ownsStudies) _studies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(context)),
        actions: [
          IconButton(
            onPressed: () => _showSignInPrompt(context),
            icon: const Icon(PhosphorIconsRegular.user),
            tooltip: context.l10n.account,
          ),
        ],
      ),
      drawer: _AppDrawer(
        catalogCount: _catalog.packages.length,
        installedCount: _downloads.installedPackages.length,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([_catalog, _downloads, _studies]),
          builder: (context, _) => _buildPage(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.bookOpen),
            selectedIcon: Icon(PhosphorIconsFill.bookOpen),
            label: context.l10n.navStudies,
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.books),
            selectedIcon: Icon(PhosphorIconsFill.books),
            label: context.l10n.navLibrary,
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.chartBar),
            selectedIcon: Icon(PhosphorIconsFill.chartBar),
            label: context.l10n.navProgress,
          ),
          NavigationDestination(
            icon: Icon(PhosphorIconsRegular.fadersHorizontal),
            selectedIcon: Icon(PhosphorIconsFill.fadersHorizontal),
            label: context.l10n.navSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return MyStudiesScreen(
          activePackage: _activeInstalledPackage(),
          studies: _studies,
          onGoToLibrary: () => setState(() => _currentIndex = 1),
          onCreateStudy: (package) => _openCreateStudy(context, package),
          onOpenStudy: (package, study) => _openStudy(context, package, study),
          onDeleteStudy: _studies.deleteStudy,
        );
      case 1:
        return LibraryScreen(
          pane: _libraryPane,
          catalog: _catalog,
          onPaneChanged: (pane) {
            setState(() {
              _libraryPane = pane;
            });
          },
          onRetry: () => _catalog.load(refresh: true),
          downloads: _downloads,
          onOpenPackage: (package) => _openPackage(context, package),
          onPrimaryAction: (package) => _handlePackageAction(context, package),
          onCancelDownload: _downloads.cancel,
          onOpenInstalled: _openInstalledPackage,
          onDeleteInstalled: (package) async {
            _content.evict(package);
            await _downloads.uninstall(package);
            await _studies.onPackageUninstalled(package.id);
          },
        );
      case 2:
        return ProgressScreen(
          installed: _downloads.installedPackages,
          studies: _studies,
          onOpenPackage: (package) => _openPackageProgress(context, package),
        );
      case 3:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  String _titleForIndex(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return _activeInstalledPackage()?.title ?? context.l10n.shellMyStudies;
      case 1:
        return context.l10n.navLibrary;
      case 2:
        return context.l10n.navProgress;
      case 3:
        return context.l10n.navSettings;
      default:
        return context.l10n.appName;
    }
  }

  InstalledPackage? _activeInstalledPackage() {
    final id = _studies.activePackageId;
    if (id == null) return null;
    for (final package in _downloads.installedPackages) {
      if (package.id == id) return package;
    }
    return null;
  }

  void _openPackage(BuildContext context, CatalogPackage package) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => PackageDetailScreen(
          package: package,
          repository: _catalog.repository,
          downloads: _downloads,
          onPrimaryAction: () => _handlePackageAction(routeContext, package),
          onCancelDownload: () => _downloads.cancel(package),
        ),
      ),
    );
  }

  void _openInstalledPackage(InstalledPackage package) {
    // Reachable from a pushed route (the Store's package detail screen) as
    // well as inline from the Downloads list; pop back to the shell first so
    // switching to the Studies tab is actually visible either way.
    Navigator.of(context).popUntil((route) => route.isFirst);
    _studies.setActivePackage(package.id);
    setState(() => _currentIndex = 0);
  }

  void _openPackageProgress(BuildContext context, InstalledPackage package) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PackageProgressScreen(
          package: package,
          contentRepository: _content,
          studies: _studies,
        ),
      ),
    );
  }

  void _openCreateStudy(BuildContext context, InstalledPackage package) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateStudyScreen(
          package: package,
          contentRepository: _content,
          studies: _studies,
        ),
      ),
    );
  }

  Future<void> _openStudy(
    BuildContext context,
    InstalledPackage package,
    Study study,
  ) async {
    try {
      final content = await _content.load(package);
      await _studies.markOpened(study);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              VerseStudyScreen(content: content, study: study, studies: _studies),
        ),
      );
    } on ContentException catch (error) {
      // The package's files are gone (e.g. an interrupted uninstall left a
      // stale install-index entry) — reconcile so this doesn't keep
      // reappearing as a dead-end every time it's tapped.
      _content.evict(package);
      await _downloads.uninstall(package);
      await _studies.onPackageUninstalled(package.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedAppError(context.l10n, error))),
      );
    }
  }

  void _handlePackageAction(BuildContext context, CatalogPackage package) {
    if (!package.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.updateRequiredForPackage(package.minAppVersion),
          ),
        ),
      );
      return;
    }
    if (!package.isDownloadable) {
      _showSignInPrompt(context);
      return;
    }

    final status = _downloads.statusFor(package);
    if (status.state == DownloadState.installed && !_downloads.hasUpdate(package)) {
      final installed = _downloads.installedPackages.firstWhere(
        (installed) => installed.id == package.id,
      );
      _openInstalledPackage(installed);
      return;
    }

    _downloads.start(package);
  }

  Future<void> _showSignInPrompt(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.signInTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.signInBody,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.continueAsGuest),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.previewSignInLater),
            ),
          ],
        ),
      ),
    );
  }
}

/// "My Studies" — scoped to the last-opened ("active") package. Studies are
/// never auto-generated; this only ever shows what the user created via the
/// Create study flow.
class MyStudiesScreen extends StatelessWidget {
  const MyStudiesScreen({
    super.key,
    required this.activePackage,
    required this.studies,
    required this.onGoToLibrary,
    required this.onCreateStudy,
    required this.onOpenStudy,
    required this.onDeleteStudy,
  });

  final InstalledPackage? activePackage;
  final StudyController studies;
  final VoidCallback onGoToLibrary;
  final ValueChanged<InstalledPackage> onCreateStudy;
  final void Function(InstalledPackage, Study) onOpenStudy;
  final ValueChanged<Study> onDeleteStudy;

  @override
  Widget build(BuildContext context) {
    final package = activePackage;
    if (package == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          InfoPanel(
            title: context.l10n.studiesGetStartedTitle,
            body: context.l10n.studiesGetStartedBody,
            action: FilledButton(
              onPressed: onGoToLibrary,
              child: Text(context.l10n.goToLibrary),
            ),
          ),
        ],
      );
    }

    final studyList = studies.studiesFor(package.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        FilledButton.icon(
          onPressed: () => onCreateStudy(package),
          icon: const Icon(PhosphorIconsRegular.plus),
          label: Text(context.l10n.createStudy),
        ),
        const SizedBox(height: 18),
        if (studyList.isEmpty)
          InfoPanel(
            title: context.l10n.studiesNoStudiesTitle,
            body: context.l10n.studiesNoStudiesBody,
          )
        else
          for (final (index, study) in studyList.indexed) ...[
            _StudyCard(
              study: study,
              studies: studies,
              isLastStudied: index == 0,
              onOpen: () => onOpenStudy(package, study),
              onDelete: () async {
                final confirmed = await showConfirmationDialog(
                  context,
                  title: context.l10n.deleteStudyTitle,
                  message: context.l10n.deleteStudyMessage(study.title),
                  confirmLabel: context.l10n.commonDelete,
                  cancelLabel: context.l10n.cancel,
                );
                if (confirmed) onDeleteStudy(study);
              },
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({
    required this.study,
    required this.studies,
    required this.onOpen,
    required this.onDelete,
    this.isLastStudied = false,
  });

  final Study study;
  final StudyController studies;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final bool isLastStudied;

  @override
  Widget build(BuildContext context) {
    final (learned, total) = studies.progressFor(study);
    final started = learned > 0 || study.lastVerseIndex > 0;
    final progressLabel = learned > 0
        ? context.l10n.progressOf(learned, total)
        : context.l10n.notStarted;
    final scheme = Theme.of(context).colorScheme;

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: isLastStudied ? Colors.white : null,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isLastStudied ? Colors.white.withValues(alpha: 0.85) : null,
    );

    final card = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLastStudied) ...[
                const Icon(
                  PhosphorIconsFill.bookOpen,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(study.title, style: titleStyle)),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  PhosphorIconsRegular.trash,
                  color: isLastStudied ? Colors.white : null,
                ),
                tooltip: context.l10n.deleteStudyTooltip,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(progressLabel, style: bodyStyle),
          const SizedBox(height: 12),
          isLastStudied
              ? FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.primary,
                  ),
                  onPressed: onOpen,
                  child: Text(started ? context.l10n.resume : context.l10n.start),
                )
              : FilledButton(
                  onPressed: onOpen,
                  child: Text(started ? context.l10n.resume : context.l10n.start),
                ),
        ],
      ),
    );

    if (!isLastStudied) return Card(child: card);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: card,
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.pane,
    required this.catalog,
    required this.onPaneChanged,
    required this.onRetry,
    required this.downloads,
    required this.onOpenPackage,
    required this.onPrimaryAction,
    required this.onCancelDownload,
    required this.onOpenInstalled,
    required this.onDeleteInstalled,
  });

  final LibraryPane pane;
  final CatalogController catalog;
  final ValueChanged<LibraryPane> onPaneChanged;
  final Future<void> Function() onRetry;
  final DownloadController downloads;
  final ValueChanged<CatalogPackage> onOpenPackage;
  final ValueChanged<CatalogPackage> onPrimaryAction;
  final ValueChanged<CatalogPackage> onCancelDownload;
  final ValueChanged<InstalledPackage> onOpenInstalled;
  final ValueChanged<InstalledPackage> onDeleteInstalled;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SegmentedButton<LibraryPane>(
            segments: [
              ButtonSegment(
                value: LibraryPane.downloads,
                label: Text(context.l10n.libraryPaneDownloads),
              ),
              ButtonSegment(value: LibraryPane.store, label: Text(context.l10n.navStore)),
            ],
            selected: {pane},
            onSelectionChanged: (selection) => onPaneChanged(selection.first),
          ),
          const SizedBox(height: 18),
          _StoreStatusBanner(pane: pane),
          const SizedBox(height: 18),
          ..._buildPaneContent(context),
        ],
      ),
    );
  }

  List<Widget> _buildPaneContent(BuildContext context) {
    if (pane == LibraryPane.downloads) {
      final installed = downloads.installedPackages;
      if (installed.isEmpty) {
        return [
          InfoPanel(
            title: context.l10n.libraryNoDownloadsTitle,
            body: context.l10n.libraryNoDownloadsBody,
          ),
        ];
      }
      return [
        for (final package in installed) ...[
          _InstalledPackageCard(
            package: package,
            onOpen: () => onOpenInstalled(package),
            onDelete: () => onDeleteInstalled(package),
          ),
          const SizedBox(height: 14),
        ],
      ];
    }

    switch (catalog.status) {
      case CatalogStatus.idle:
      case CatalogStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case CatalogStatus.error:
        return [
          InfoPanel(
            title: context.l10n.libraryErrorTitle,
            body: catalog.error == null
                ? context.l10n.tryAgain
                : localizedAppError(context.l10n, catalog.error!),
            action: FilledButton(
              onPressed: () => onRetry(),
              child: Text(context.l10n.retry),
            ),
          ),
        ];
      case CatalogStatus.ready:
        if (catalog.packages.isEmpty) {
          return [
            InfoPanel(
              title: context.l10n.libraryEmptyTitle,
              body: context.l10n.libraryEmptyBody,
            ),
          ];
        }
        return [
          if (catalog.isStale || catalog.lastUpdated != null) ...[
            _CatalogFreshnessBanner(
              isStale: catalog.isStale,
              lastUpdated: catalog.lastUpdated,
            ),
            const SizedBox(height: 14),
          ],
          for (final package in catalog.packages) ...[
            _PackageCard(
              package: package,
              download: downloads.statusFor(package),
              hasUpdate: downloads.hasUpdate(package),
              onTap: () => onOpenPackage(package),
              onPrimaryAction: () => onPrimaryAction(package),
              onCancelDownload: () => onCancelDownload(package),
            ),
            const SizedBox(height: 14),
          ],
        ];
    }
  }
}

/// Tells the user whether the Store list is fresh or just what was last
/// cached — shown once a catalog (cached or live) is actually on screen.
class _CatalogFreshnessBanner extends StatelessWidget {
  const _CatalogFreshnessBanner({required this.isStale, required this.lastUpdated});

  final bool isStale;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    if (!isStale && lastUpdated == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final label = lastUpdated == null
        ? context.l10n.catalogFresh
        : context.l10n.catalogLastUpdated(
            _relativeLabel(context.l10n, lastUpdated!),
          );

    return Row(
      children: [
        Icon(
          isStale ? PhosphorIconsRegular.cloudSlash : PhosphorIconsRegular.cloudCheck,
          size: 16,
          color: isStale ? theme.colorScheme.error : theme.colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isStale ? '$label ${context.l10n.catalogStaleSuffix}' : label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isStale ? theme.colorScheme.error : theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  String _relativeLabel(AppLocalizations l10n, DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    return l10n.timeDaysAgo(diff.inDays);
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({
    super.key,
    required this.installed,
    required this.studies,
    required this.onOpenPackage,
  });

  final List<InstalledPackage> installed;
  final StudyController studies;
  final ValueChanged<InstalledPackage> onOpenPackage;

  @override
  Widget build(BuildContext context) {
    final totalVerses = installed.fold<int>(
      0,
      (total, package) => total + package.verseCount,
    );
    final totalLearned = installed.fold<int>(
      0,
      (total, package) =>
          total + studies.packageProgress(package.id, package.verseCount).$1,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: context.l10n.progressPackagesInstalled,
                value: '${installed.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: context.l10n.progressVersesLearned,
                value: '$totalLearned / $totalVerses',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (installed.isEmpty)
          InfoPanel(
            title: context.l10n.progressEmptyTitle,
            body: context.l10n.progressEmptyBody,
          )
        else ...[
          Text(context.l10n.progressByPackage,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final package in installed) ...[
            _ProgressRow(
              package: package,
              progress: studies.packageProgress(package.id, package.verseCount),
              onTap: () => onOpenPackage(package),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _SettingTile(
          icon: PhosphorIconsRegular.textAa,
          title: context.l10n.settingsTextSize,
          subtitle: context.l10n.settingsTextSizeSubtitle,
          trailing: context.l10n.settingStandard,
        ),
        const SizedBox(height: 12),
        _SettingTile(
          icon: PhosphorIconsRegular.palette,
          title: context.l10n.settingsThemeTone,
          subtitle: context.l10n.settingsThemeToneSubtitle,
          trailing: context.l10n.settingLight,
        ),
        const SizedBox(height: 12),
        _SettingTile(
          icon: PhosphorIconsRegular.globe,
          title: context.l10n.settingsAppLanguage,
          subtitle: context.l10n.settingsAppLanguageSubtitle,
          trailing: context.l10n.settingAuto,
        ),
        const SizedBox(height: 12),
        _SettingTile(
          icon: PhosphorIconsRegular.speakerHigh,
          title: context.l10n.settingsAudioTeaser,
          subtitle: context.l10n.settingsAudioTeaserSubtitle,
          trailing: context.l10n.settingOff,
        ),
      ],
    );
  }
}

class PackageDetailScreen extends StatefulWidget {
  const PackageDetailScreen({
    super.key,
    required this.package,
    required this.repository,
    required this.downloads,
    required this.onPrimaryAction,
    required this.onCancelDownload,
  });

  final CatalogPackage package;
  final CatalogRepository repository;
  final DownloadController downloads;
  final VoidCallback onPrimaryAction;
  final VoidCallback onCancelDownload;

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  late Future<PackageManifest> _manifestFuture;

  @override
  void initState() {
    super.initState();
    _manifestFuture = widget.repository.fetchManifest(widget.package);
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.package;

    return Scaffold(
      appBar: AppBar(title: Text(package.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(package.packageType.label(context.l10n))),
                      Chip(label: Text(package.language.toUpperCase())),
                      Chip(label: Text(package.sizeLabel(context.l10n))),
                      Chip(label: Text('v${package.version}')),
                      Chip(label: Text(package.statusLabel(context.l10n))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!package.isSupported)
                    Text(
                      context.l10n.requiresAppVersion(package.minAppVersion),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: widget.downloads,
                    builder: (context, _) => _DownloadAction(
                      package: package,
                      download: widget.downloads.statusFor(package),
                      onPrimaryAction: widget.onPrimaryAction,
                      onCancelDownload: widget.onCancelDownload,
                      hasUpdate: widget.downloads.hasUpdate(package),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(context.l10n.packageContents,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          FutureBuilder<PackageManifest>(
            future: _manifestFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                final error = snapshot.error;
                return InfoPanel(
                  title: context.l10n.manifestErrorTitle,
                  body: localizedAppError(context.l10n, error!),
                  action: FilledButton(
                    onPressed: () => setState(() {
                      _manifestFuture = widget.repository.fetchManifest(
                        package,
                      );
                    }),
                    child: Text(context.l10n.retry),
                  ),
                );
              }

              final manifest = snapshot.requireData;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Chip(label: Text(context.l10n.chaptersCount(manifest.chapterCount))),
                          Chip(label: Text(context.l10n.versesCount(manifest.verseCount))),
                          Chip(label: Text(context.l10n.filesCount(manifest.files.length))),
                        ],
                      ),
                      if (manifest.attribution.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.creditAttribution(manifest.attribution),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.download,
    required this.onTap,
    required this.onPrimaryAction,
    required this.onCancelDownload,
    this.hasUpdate = false,
  });

  final CatalogPackage package;
  final PackageDownload download;
  final VoidCallback onTap;
  final VoidCallback onPrimaryAction;
  final VoidCallback onCancelDownload;
  final bool hasUpdate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          package.listSubtitle(context.l10n),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Chip(label: Text(package.statusLabel(context.l10n))),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(package.language.toUpperCase())),
                  Chip(label: Text(package.packageType.label(context.l10n))),
                  Chip(label: Text(package.sizeLabel(context.l10n))),
                ],
              ),
              const SizedBox(height: 16),
              _DownloadAction(
                package: package,
                download: download,
                onPrimaryAction: onPrimaryAction,
                onCancelDownload: onCancelDownload,
                hasUpdate: hasUpdate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card for a package that is installed on the device.
class _InstalledPackageCard extends StatelessWidget {
  const _InstalledPackageCard({
    required this.package,
    required this.onOpen,
    required this.onDelete,
  });

  final InstalledPackage package;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: context.l10n.removeDownloadTitle,
                      message: context.l10n.removeDownloadMessage(package.title),
                      confirmLabel: context.l10n.remove,
                      cancelLabel: context.l10n.cancel,
                    );
                    if (confirmed) onDelete();
                  },
                  icon: const Icon(PhosphorIconsRegular.trash),
                  tooltip: context.l10n.removeDownloadTooltip,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(package.language.toUpperCase())),
                Chip(label: Text('v${package.version}')),
                Chip(label: Text(context.l10n.chaptersCount(package.chapterCount))),
                Chip(label: Text(context.l10n.versesCount(package.verseCount))),
              ],
            ),
            if (package.attribution.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.creditAttribution(package.attribution),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onOpen,
              child: Text(context.l10n.open),
            ),
          ],
        ),
      ),
    );
  }
}

/// Download button plus progress / error state, shared by the package card and
/// the package detail screen.
class _DownloadAction extends StatelessWidget {
  const _DownloadAction({
    required this.package,
    required this.download,
    required this.onPrimaryAction,
    required this.onCancelDownload,
    this.hasUpdate = false,
  });

  final CatalogPackage package;
  final PackageDownload download;
  final VoidCallback onPrimaryAction;
  final VoidCallback onCancelDownload;
  final bool hasUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (download.state) {
      case DownloadState.downloading:
      case DownloadState.verifying:
      case DownloadState.installing:
        final progress = download.progress;
        final isDownloading = download.state == DownloadState.downloading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: isDownloading ? progress?.fraction : null,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    switch (download.state) {
                      DownloadState.verifying =>
                        context.l10n.downloadingVerifying,
                      DownloadState.installing =>
                        context.l10n.downloadingInstalling,
                      _ => _progressLabel(context.l10n, progress),
                    },
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (isDownloading)
                  TextButton(
                    onPressed: onCancelDownload,
                    child: Text(context.l10n.cancel),
                  ),
              ],
            ),
          ],
        );
      case DownloadState.installed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasUpdate ? PhosphorIconsFill.cloudArrowUp : PhosphorIconsFill.checkCircle,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasUpdate
                        ? context.l10n.updateAvailable(package.version)
                        : context.l10n.downloadInstalled,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onPrimaryAction,
              child: Text(hasUpdate ? context.l10n.update : context.l10n.open),
            ),
          ],
        );
      case DownloadState.failed:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              download.error == null
                  ? context.l10n.downloadFailedFallback
                  : localizedAppError(context.l10n, download.error!),
              key: const Key('download-error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onPrimaryAction,
              child: Text(context.l10n.retryDownload),
            ),
          ],
        );
      case DownloadState.idle:
        if (!package.isSupported) {
          return Text(
            context.l10n.requiresAppVersion(package.minAppVersion),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          );
        }
        return FilledButton(
          onPressed: onPrimaryAction,
          child: Text(package.primaryActionLabel(context.l10n)),
        );
    }
  }

  String _progressLabel(AppLocalizations l10n, DownloadProgress? progress) {
    if (progress == null) return l10n.downloadingStarting;
    final fraction = progress.fraction;
    if (fraction == null) return l10n.downloadingStarting;
    return l10n.downloadingPercent((fraction * 100).round());
  }
}

class _StoreStatusBanner extends StatelessWidget {
  const _StoreStatusBanner({required this.pane});

  final LibraryPane pane;

  @override
  Widget build(BuildContext context) {
    final title = pane == LibraryPane.downloads
        ? context.l10n.storeBannerDownloadsTitle
        : context.l10n.storeBannerCatalogTitle;
    final body = pane == LibraryPane.downloads
        ? context.l10n.storeBannerDownloadsBody
        : context.l10n.storeBannerCatalogBody;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.package,
    required this.progress,
    required this.onTap,
  });

  final InstalledPackage package;
  final (int, int) progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (learned, total) = progress;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.progressVersesOf(learned, total),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(PhosphorIconsRegular.caretRight),
            ],
          ),
        ),
      ),
    );
  }
}

/// Per-chapter learned/to-learn heatmap for one installed package
/// (wireframe screen `9b`).
class PackageProgressScreen extends StatefulWidget {
  const PackageProgressScreen({
    super.key,
    required this.package,
    required this.contentRepository,
    required this.studies,
  });

  final InstalledPackage package;
  final PackageContentRepository contentRepository;
  final StudyController studies;

  @override
  State<PackageProgressScreen> createState() => _PackageProgressScreenState();
}

class _PackageProgressScreenState extends State<PackageProgressScreen> {
  late Future<PackageContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = widget.contentRepository.load(widget.package);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.package.title)),
      body: FutureBuilder<PackageContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: InfoPanel(
                title: context.l10n.manifestErrorTitle,
                body: localizedAppError(context.l10n, error!),
              ),
            );
          }

          final content = snapshot.requireData;
          return ListenableBuilder(
            listenable: widget.studies,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final chapter in content.index.chapterOrder) ...[
                  _ChapterHeatmapRow(
                    chapter: chapter,
                    verses: content.versesByChapter[chapter] ?? const [],
                    packageId: widget.package.id,
                    studies: widget.studies,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChapterHeatmapRow extends StatelessWidget {
  const _ChapterHeatmapRow({
    required this.chapter,
    required this.verses,
    required this.packageId,
    required this.studies,
  });

  final int chapter;
  final List<Verse> verses;
  final String packageId;
  final StudyController studies;

  @override
  Widget build(BuildContext context) {
    final learned = verses
        .where((v) => studies.stateFor(packageId, v.verseRef).isLearned)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.chapterWithNumber(chapter),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  context.l10n.learnedOf(learned, verses.length),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final verse in verses)
                  _VerseHeatCell(
                    state: studies.stateFor(packageId, verse.verseRef),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerseHeatCell extends StatelessWidget {
  const _VerseHeatCell({required this.state});

  final VerseState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color color;
    if (state.isLearned) {
      color = scheme.primary;
    } else if (state.isDifficult) {
      color = scheme.secondary;
    } else {
      color = scheme.outlineVariant;
    }

    return Tooltip(
      message: state.verseRef,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: state.isLearned || state.isDifficult
              ? color
              : Colors.transparent,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(trailing),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.catalogCount, required this.installedCount});

  final int catalogCount;
  final int installedCount;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.appName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.drawerTagline,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              _DrawerMetric(
                label: context.l10n.catalogPackages,
                value: '$catalogCount',
              ),
              const SizedBox(height: 10),
              _DrawerMetric(
                label: context.l10n.installedPackages,
                value: '$installedCount',
              ),
              const Spacer(),
              Text(context.l10n.guestModeNote),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerMetric extends StatelessWidget {
  const _DrawerMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
