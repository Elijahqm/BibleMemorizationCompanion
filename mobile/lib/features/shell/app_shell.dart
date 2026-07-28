import 'package:flutter/material.dart';

enum LibraryPane { downloads, store }

enum PackageStatus { downloaded, available, locked, downloading }

class AppShell extends StatefulWidget {
	const AppShell({super.key});

	@override
	State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
	final List<ContentPackage> _packages = demoPackages;
	final List<StudySession> _studies = demoStudies;

	int _currentIndex = 0;
	LibraryPane _libraryPane = LibraryPane.downloads;

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Text(_titleForIndex()),
				actions: [
					IconButton(
						onPressed: () => _showSignInPrompt(context),
						icon: const Icon(Icons.person_outline),
						tooltip: 'Account',
					),
				],
			),
			drawer: _AppDrawer(
				installedCount: _packages.where((package) => package.isInstalled).length,
				studyCount: _studies.length,
			),
			body: SafeArea(child: _buildPage()),
			bottomNavigationBar: NavigationBar(
				selectedIndex: _currentIndex,
				onDestinationSelected: (index) {
					setState(() {
						_currentIndex = index;
					});
				},
				destinations: const [
					NavigationDestination(
						icon: Icon(Icons.auto_stories_outlined),
						selectedIcon: Icon(Icons.auto_stories),
						label: 'Studies',
					),
					NavigationDestination(
						icon: Icon(Icons.library_books_outlined),
						selectedIcon: Icon(Icons.library_books),
						label: 'Library',
					),
					NavigationDestination(
						icon: Icon(Icons.insights_outlined),
						selectedIcon: Icon(Icons.insights),
						label: 'Progress',
					),
					NavigationDestination(
						icon: Icon(Icons.tune_outlined),
						selectedIcon: Icon(Icons.tune),
						label: 'Settings',
					),
				],
			),
		);
	}

	Widget _buildPage() {
		switch (_currentIndex) {
			case 0:
				return StudiesScreen(
					studies: _studies,
					onOpenStudy: (study) => _openStudy(context, study),
				);
			case 1:
				return LibraryScreen(
					pane: _libraryPane,
					packages: _packages,
					onPaneChanged: (pane) {
						setState(() {
							_libraryPane = pane;
						});
					},
					onOpenPackage: (package) => _openPackage(context, package),
					onPrimaryAction: (package) => _handlePackageAction(context, package),
				);
			case 2:
				return ProgressScreen(studies: _studies);
			case 3:
				return const SettingsScreen();
			default:
				return const SizedBox.shrink();
		}
	}

	String _titleForIndex() {
		switch (_currentIndex) {
			case 0:
				return 'My Studies';
			case 1:
				return 'Library';
			case 2:
				return 'Progress';
			case 3:
				return 'Settings';
			default:
				return 'Bible Memorization Companion';
		}
	}

	void _openPackage(BuildContext context, ContentPackage package) {
		Navigator.of(context).push(
			MaterialPageRoute<void>(
				builder: (_) => PackageDetailScreen(
					package: package,
					onPrimaryAction: () => _handlePackageAction(context, package),
					onOpenStudy: () {
						final study = _studies.firstWhere(
							(item) => item.packageId == package.id,
							orElse: () => _studies.first,
						);
						_openStudy(context, study);
					},
				),
			),
		);
	}

	void _openStudy(BuildContext context, StudySession study) {
		Navigator.of(context).push(
			MaterialPageRoute<void>(
				builder: (_) => VerseStudyScreen(study: study),
			),
		);
	}

	void _handlePackageAction(BuildContext context, ContentPackage package) {
		switch (package.status) {
			case PackageStatus.downloaded:
				final study = _studies.firstWhere(
					(item) => item.packageId == package.id,
					orElse: () => _studies.first,
				);
				_openStudy(context, study);
				return;
			case PackageStatus.available:
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('Queued ${package.title} for download.')),
				);
				return;
			case PackageStatus.locked:
				_showSignInPrompt(context);
				return;
			case PackageStatus.downloading:
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('${package.title} is already downloading.')),
				);
				return;
		}
	}

	Future<void> _showSignInPrompt(BuildContext context) {
		return showModalBottomSheet<void>(
			context: context,
			showDragHandle: true,
			backgroundColor: Theme.of(context).colorScheme.surface,
			builder: (context) => Padding(
				padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							'Sign in only when it helps',
							style: Theme.of(context).textTheme.titleLarge,
						),
						const SizedBox(height: 12),
						Text(
							'Free scripture downloads stay guest-friendly. Account access is reserved for future paid audio, purchase recovery, and cross-device sync.',
							style: Theme.of(context).textTheme.bodyLarge,
						),
						const SizedBox(height: 20),
						FilledButton(
							onPressed: () => Navigator.of(context).pop(),
							child: const Text('Continue as guest'),
						),
						const SizedBox(height: 8),
						TextButton(
							onPressed: () => Navigator.of(context).pop(),
							child: const Text('Preview sign-in later'),
						),
					],
				),
			),
		);
	}
}

class StudiesScreen extends StatelessWidget {
	const StudiesScreen({
		super.key,
		required this.studies,
		required this.onOpenStudy,
	});

	final List<StudySession> studies;
	final ValueChanged<StudySession> onOpenStudy;

	@override
	Widget build(BuildContext context) {
		final nextStudy = studies.first;

		return ListView(
			padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
			children: [
				_HeroPanel(study: nextStudy, onOpenStudy: () => onOpenStudy(nextStudy)),
				const SizedBox(height: 20),
				Text(
					'Continue where you left off',
					style: Theme.of(context).textTheme.titleLarge,
				),
				const SizedBox(height: 12),
				for (final study in studies) ...[
					_StudyCard(study: study, onTap: () => onOpenStudy(study)),
					const SizedBox(height: 12),
				],
			],
		);
	}
}

class LibraryScreen extends StatelessWidget {
	const LibraryScreen({
		super.key,
		required this.pane,
		required this.packages,
		required this.onPaneChanged,
		required this.onOpenPackage,
		required this.onPrimaryAction,
	});

	final LibraryPane pane;
	final List<ContentPackage> packages;
	final ValueChanged<LibraryPane> onPaneChanged;
	final ValueChanged<ContentPackage> onOpenPackage;
	final ValueChanged<ContentPackage> onPrimaryAction;

	@override
	Widget build(BuildContext context) {
		final visiblePackages = switch (pane) {
			LibraryPane.downloads =>
				packages.where((package) => package.isInstalled).toList(),
			LibraryPane.store => packages,
		};

		return ListView(
			padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
			children: [
				SegmentedButton<LibraryPane>(
					segments: const [
						ButtonSegment(
							value: LibraryPane.downloads,
							label: Text('Downloads'),
						),
						ButtonSegment(value: LibraryPane.store, label: Text('Store')),
					],
					selected: {pane},
					onSelectionChanged: (selection) => onPaneChanged(selection.first),
				),
				const SizedBox(height: 18),
				_StoreStatusBanner(pane: pane),
				const SizedBox(height: 18),
				for (final package in visiblePackages) ...[
					_PackageCard(
						package: package,
						onTap: () => onOpenPackage(package),
						onPrimaryAction: () => onPrimaryAction(package),
					),
					const SizedBox(height: 14),
				],
			],
		);
	}
}

class ProgressScreen extends StatelessWidget {
	const ProgressScreen({super.key, required this.studies});

	final List<StudySession> studies;

	@override
	Widget build(BuildContext context) {
		return ListView(
			padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
			children: [
				const Row(
					children: [
						Expanded(child: _MetricTile(label: 'Verses reviewed', value: '112')),
						SizedBox(width: 12),
						Expanded(child: _MetricTile(label: 'Current streak', value: '6 days')),
					],
				),
				const SizedBox(height: 12),
				const Row(
					children: [
						Expanded(child: _MetricTile(label: 'Packages active', value: '3')),
						SizedBox(width: 12),
						Expanded(
							child: _MetricTile(label: 'Recall confidence', value: '74%'),
						),
					],
				),
				const SizedBox(height: 20),
				Text('Section progress', style: Theme.of(context).textTheme.titleLarge),
				const SizedBox(height: 12),
				for (final study in studies) ...[
					_ProgressRow(study: study),
					const SizedBox(height: 12),
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
			children: const [
				_SettingTile(
					icon: Icons.format_size,
					title: 'Text size',
					subtitle: 'Comfortable reading with larger verse cards',
					trailing: 'Standard',
				),
				SizedBox(height: 12),
				_SettingTile(
					icon: Icons.palette_outlined,
					title: 'Theme tone',
					subtitle: 'Calm parchment with strong scripture contrast',
					trailing: 'Light',
				),
				SizedBox(height: 12),
				_SettingTile(
					icon: Icons.language_outlined,
					title: 'App language',
					subtitle: 'Follow device language with English fallback',
					trailing: 'Auto',
				),
				SizedBox(height: 12),
				_SettingTile(
					icon: Icons.volume_up_outlined,
					title: 'Audio teaser',
					subtitle: 'Preview-only in the first release shell',
					trailing: 'Off',
				),
			],
		);
	}
}

class PackageDetailScreen extends StatelessWidget {
	const PackageDetailScreen({
		super.key,
		required this.package,
		required this.onPrimaryAction,
		required this.onOpenStudy,
	});

	final ContentPackage package;
	final VoidCallback onPrimaryAction;
	final VoidCallback onOpenStudy;

	@override
	Widget build(BuildContext context) {
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
											Chip(label: Text(package.packageTypeLabel)),
											Chip(label: Text(package.language)),
											Chip(label: Text(package.sizeLabel)),
										],
									),
									const SizedBox(height: 16),
									Text(
										package.summary,
										style: Theme.of(context).textTheme.bodyLarge,
									),
									const SizedBox(height: 20),
									FilledButton(
										onPressed: onPrimaryAction,
										child: Text(package.primaryActionLabel),
									),
									const SizedBox(height: 8),
									if (package.isInstalled)
										TextButton(
											onPressed: onOpenStudy,
											child: const Text('Start study flow'),
										),
								],
							),
						),
					),
					const SizedBox(height: 20),
					Text('Included sections', style: Theme.of(context).textTheme.titleLarge),
					const SizedBox(height: 12),
					Wrap(
						spacing: 10,
						runSpacing: 10,
						children: [
							for (final section in package.sections) Chip(label: Text(section)),
						],
					),
				],
			),
		);
	}
}

class VerseStudyScreen extends StatefulWidget {
	const VerseStudyScreen({super.key, required this.study});

	final StudySession study;

	@override
	State<VerseStudyScreen> createState() => _VerseStudyScreenState();
}

class _VerseStudyScreenState extends State<VerseStudyScreen> {
	int _verseIndex = 0;
	bool _revealed = false;

	@override
	Widget build(BuildContext context) {
		final verse = widget.study.verses[_verseIndex];
		final progress = (_verseIndex + 1) / widget.study.verses.length;

		return Scaffold(
			appBar: AppBar(title: Text(widget.study.title)),
			body: Padding(
				padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							widget.study.sectionTitle,
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
									onTap: () {
										setState(() {
											_revealed = !_revealed;
										});
									},
									child: Padding(
										padding: const EdgeInsets.all(24),
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													verse.reference,
													style: Theme.of(context).textTheme.headlineMedium,
												),
												const SizedBox(height: 20),
												Text(
													_revealed
															? verse.text
															: 'Tap to reveal the verse text, then tap again to hide it and test recall.',
													style: Theme.of(context)
															.textTheme
															.bodyLarge
															?.copyWith(fontSize: 20, height: 1.6),
												),
												const Spacer(),
												Text(
													'Credit: ${widget.study.attribution}',
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
												: () {
														setState(() {
															_verseIndex -= 1;
															_revealed = false;
														});
													},
										child: const Text('Previous'),
									),
								),
								const SizedBox(width: 12),
								Expanded(
									child: FilledButton(
										onPressed: _verseIndex == widget.study.verses.length - 1
												? null
												: () {
														setState(() {
															_verseIndex += 1;
															_revealed = false;
														});
													},
										child: const Text('Next'),
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

class _HeroPanel extends StatelessWidget {
	const _HeroPanel({required this.study, required this.onOpenStudy});

	final StudySession study;
	final VoidCallback onOpenStudy;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(28),
				gradient: const LinearGradient(
					colors: [Color(0xFF314F7E), Color(0xFF5D78AA)],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
			),
			padding: const EdgeInsets.all(24),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
						decoration: BoxDecoration(
							color: Colors.white.withValues(alpha: 0.14),
							borderRadius: BorderRadius.circular(999),
						),
						child: const Text(
							'Continue studying',
							style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
						),
					),
					const SizedBox(height: 18),
					Text(
						study.title,
						style: Theme.of(context)
								.textTheme
								.headlineMedium
								?.copyWith(color: Colors.white),
					),
					const SizedBox(height: 12),
					Text(
						'${study.completedVerses}/${study.totalVerses} verses reviewed today',
						style: Theme.of(context)
								.textTheme
								.bodyLarge
								?.copyWith(color: const Color(0xFFE6ECF7)),
					),
					const SizedBox(height: 18),
					FilledButton.tonal(
						style: FilledButton.styleFrom(
							backgroundColor: const Color(0xFFFFF8E8),
							foregroundColor: const Color(0xFF1D2433),
						),
						onPressed: onOpenStudy,
						child: const Text('Open verse session'),
					),
				],
			),
		);
	}
}

class _StudyCard extends StatelessWidget {
	const _StudyCard({required this.study, required this.onTap});

	final StudySession study;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
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
										Text(study.title, style: Theme.of(context).textTheme.titleMedium),
										const SizedBox(height: 6),
										Text(study.sectionTitle, style: Theme.of(context).textTheme.bodyMedium),
										const SizedBox(height: 12),
										LinearProgressIndicator(
											value: study.progress,
											minHeight: 8,
											borderRadius: BorderRadius.circular(999),
										),
									],
								),
							),
							const SizedBox(width: 16),
							Text('${(study.progress * 100).round()}%'),
						],
					),
				),
			),
		);
	}
}

class _PackageCard extends StatelessWidget {
	const _PackageCard({
		required this.package,
		required this.onTap,
		required this.onPrimaryAction,
	});

	final ContentPackage package;
	final VoidCallback onTap;
	final VoidCallback onPrimaryAction;

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
													package.subtitle,
													style: Theme.of(context).textTheme.bodyMedium,
												),
											],
										),
									),
									const SizedBox(width: 12),
									Chip(label: Text(package.statusLabel)),
								],
							),
							const SizedBox(height: 14),
							Wrap(
								spacing: 8,
								runSpacing: 8,
								children: [
									Chip(label: Text(package.language)),
									Chip(label: Text(package.packageTypeLabel)),
									Chip(label: Text(package.sizeLabel)),
								],
							),
							const SizedBox(height: 14),
							Text(package.summary, style: Theme.of(context).textTheme.bodyLarge),
							const SizedBox(height: 16),
							FilledButton(
								onPressed: onPrimaryAction,
								child: Text(package.primaryActionLabel),
							),
						],
					),
				),
			),
		);
	}
}

class _StoreStatusBanner extends StatelessWidget {
	const _StoreStatusBanner({required this.pane});

	final LibraryPane pane;

	@override
	Widget build(BuildContext context) {
		final title = pane == LibraryPane.downloads
				? 'Offline-ready downloads'
				: 'Guest-first scripture catalog';
		final body = pane == LibraryPane.downloads
				? 'Downloaded packages stay available without a network connection, ready for verse-by-verse review.'
				: 'Free scripture content can be browsed and downloaded without signing in. Locked cards preview future paid audio add-ons.';

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
	const _ProgressRow({required this.study});

	final StudySession study;

	@override
	Widget build(BuildContext context) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(18),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(study.title, style: Theme.of(context).textTheme.titleMedium),
						const SizedBox(height: 8),
						Text(study.sectionTitle, style: Theme.of(context).textTheme.bodyMedium),
						const SizedBox(height: 14),
						LinearProgressIndicator(
							value: study.progress,
							minHeight: 10,
							borderRadius: BorderRadius.circular(999),
						),
					],
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
	const _AppDrawer({required this.installedCount, required this.studyCount});

	final int installedCount;
	final int studyCount;

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
								'Bible Memorization Companion',
								style: Theme.of(context).textTheme.titleLarge,
							),
							const SizedBox(height: 8),
							Text(
								'Clear, calm scripture practice with offline-ready packages.',
								style: Theme.of(context).textTheme.bodyLarge,
							),
							const SizedBox(height: 24),
							_DrawerMetric(label: 'Installed packages', value: '$installedCount'),
							const SizedBox(height: 10),
							_DrawerMetric(label: 'Active studies', value: '$studyCount'),
							const Spacer(),
							const Text(
								'Guest mode stays fully supported for free scripture downloads.',
							),
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
				Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
				Text(value, style: Theme.of(context).textTheme.titleMedium),
			],
		);
	}
}

class ContentPackage {
	const ContentPackage({
		required this.id,
		required this.title,
		required this.subtitle,
		required this.language,
		required this.packageTypeLabel,
		required this.sizeLabel,
		required this.status,
		required this.summary,
		required this.sections,
	});

	final String id;
	final String title;
	final String subtitle;
	final String language;
	final String packageTypeLabel;
	final String sizeLabel;
	final PackageStatus status;
	final String summary;
	final List<String> sections;

	bool get isInstalled => status == PackageStatus.downloaded;

	String get statusLabel {
		switch (status) {
			case PackageStatus.downloaded:
				return 'Downloaded';
			case PackageStatus.available:
				return 'Free';
			case PackageStatus.locked:
				return 'Audio teaser';
			case PackageStatus.downloading:
				return 'Downloading';
		}
	}

	String get primaryActionLabel {
		switch (status) {
			case PackageStatus.downloaded:
				return 'Open';
			case PackageStatus.available:
				return 'Download';
			case PackageStatus.locked:
				return 'Preview sign-in';
			case PackageStatus.downloading:
				return 'View progress';
		}
	}
}

class StudySession {
	const StudySession({
		required this.packageId,
		required this.title,
		required this.sectionTitle,
		required this.completedVerses,
		required this.totalVerses,
		required this.verses,
		required this.attribution,
	});

	final String packageId;
	final String title;
	final String sectionTitle;
	final int completedVerses;
	final int totalVerses;
	final List<VerseItem> verses;
	final String attribution;

	double get progress => completedVerses / totalVerses;
}

class VerseItem {
	const VerseItem({required this.reference, required this.text});

	final String reference;
	final String text;
}

const demoPackages = [
	ContentPackage(
		id: 'cb-hechos-1-9',
		title: 'CB Hechos 1-9',
		subtitle: 'Spanish scripture package',
		language: 'ES',
		packageTypeLabel: 'Book',
		sizeLabel: '27 MB',
		status: PackageStatus.downloaded,
		summary: 'A downloaded package ready for offline verse review, section drills, and chapter study creation.',
		sections: ['El Espíritu Santo prometido', 'Pentecostés', 'Pedro sana a un cojo'],
	),
	ContentPackage(
		id: 'bq-acts-1-9',
		title: 'BQ Acts 1-9',
		subtitle: 'English Bible Quiz season set',
		language: 'EN',
		packageTypeLabel: 'Season',
		sizeLabel: '26 MB',
		status: PackageStatus.available,
		summary: 'An English season package in the store with free download access and section-based study entry points.',
		sections: ['The Promise of the Spirit', 'The Birth of the Church', 'The Conversion of Saul'],
	),
	ContentPackage(
		id: 'acts-audio-preview',
		title: 'Acts Audio Preview',
		subtitle: 'Future paid audio add-on',
		language: 'EN / ES',
		packageTypeLabel: 'Audio add-on',
		sizeLabel: 'Preview',
		status: PackageStatus.locked,
		summary: 'A teaser card for later paid audio flows. The shell keeps the account prompt contextual instead of forcing sign-in up front.',
		sections: ['Verse timing preview', 'Narration samples'],
	),
];

const demoStudies = [
	StudySession(
		packageId: 'cb-hechos-1-9',
		title: 'Acts 2 Memory Review',
		sectionTitle: 'Pentecostés',
		completedVerses: 18,
		totalVerses: 28,
		attribution: 'REINA-VALERA 1960',
		verses: [
			VerseItem(
				reference: 'Hechos 2:1',
				text: 'Cuando llegó el día de Pentecostés, estaban todos unánimes juntos.',
			),
			VerseItem(
				reference: 'Hechos 2:2',
				text: 'Y de repente vino del cielo un estruendo como de un viento recio que soplaba.',
			),
			VerseItem(
				reference: 'Hechos 2:4',
				text: 'Y fueron todos llenos del Espíritu Santo, y comenzaron a hablar en otras lenguas.',
			),
		],
	),
	StudySession(
		packageId: 'bq-acts-1-9',
		title: 'Acts 9 Recall Drill',
		sectionTitle: 'The Conversion of Saul',
		completedVerses: 9,
		totalVerses: 22,
		attribution: 'KING JAMES VERSION',
		verses: [
			VerseItem(
				reference: 'Acts 9:1',
				text: 'And Saul, yet breathing out threatenings and slaughter against the disciples of the Lord, went unto the high priest.',
			),
			VerseItem(
				reference: 'Acts 9:3',
				text: 'And as he journeyed, he came near Damascus: and suddenly there shined round about him a light from heaven.',
			),
			VerseItem(
				reference: 'Acts 9:5',
				text: 'And he said, Who art thou, Lord? And the Lord said, I am Jesus whom thou persecutest.',
			),
		],
	),
];