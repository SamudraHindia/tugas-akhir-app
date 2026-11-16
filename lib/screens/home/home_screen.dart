import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/modul_ajar.dart';
import '../../state/app_controller.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/modul_card.dart';
import '../../widgets/page_width.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/subject_avatar.dart';
import '../modul/modul_detail_screen.dart';
import '../modul/modul_form_screen.dart';
import '../search/modul_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigateTab});

  final ValueChanged<int> onNavigateTab;

  Future<void> _openForm(BuildContext context) async {
    final result = await Navigator.of(context).push<ModulAjar>(
      MaterialPageRoute<ModulAjar>(builder: (_) => const ModulFormScreen()),
    );
    if (result == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Modul "${result.judul}" berhasil dibuat.')),
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ModulDetailScreen(modulId: result.id),
      ),
    );
  }

  void _openDetail(BuildContext context, ModulAjar modul) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ModulDetailScreen(modulId: modul.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final latest = controller.modulTerbaru.take(3).toList();
    final ringkasan = controller.ringkasanMapel.take(4).toList();
    final activities = controller.activities.take(3).toList();
    final nameParts = controller.profile.nama.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? 'Guru' : nameParts.first;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ModulAjar',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Sistem pengelolaan modul ajar',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Gunakan tema terang' : 'Gunakan tema gelap',
            onPressed: () =>
                controller.ubahTema(isDark ? ThemeMode.light : ThemeMode.dark),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween(begin: 0.8, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                key: ValueKey(isDark),
                size: 20,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 14),
            child: InkWell(
              onTap: () => onNavigateTab(3),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  controller.profile.inisial,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.muatUlang,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            PageWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _HomeHeader(
                    now: now,
                    firstName: firstName,
                    onSearch: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ModulSearchScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MotivationBanner(
                    totalModul: controller.totalModul,
                    totalDraft: controller.totalDraft,
                    totalTerbit: controller.totalTerbit,
                    totalFavorit: controller.totalFavorit,
                  ),
                  if (controller.storageError != null) ...[
                    const SizedBox(height: 12),
                    _WarningBanner(
                      message: controller.storageError!,
                      onRetry: () => controller.muatUlang(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 640 ? 4 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          mainAxisExtent: 88,
                        ),
                        itemBuilder: (context, index) {
                          final items = [
                            StatCard(
                              label: 'Total modul',
                              value: controller.totalModul,
                              icon: Icons.folder_outlined,
                              color: AppColors.primary,
                              onTap: () => onNavigateTab(1),
                            ),
                            StatCard(
                              label: 'Sudah terbit',
                              value: controller.totalTerbit,
                              icon: Icons.check_circle_outline,
                              color: AppColors.success,
                              onTap: () => onNavigateTab(1),
                            ),
                            StatCard(
                              label: 'Masih draft',
                              value: controller.totalDraft,
                              icon: Icons.edit_note_outlined,
                              color: AppColors.accent,
                              onTap: () => onNavigateTab(1),
                            ),
                            StatCard(
                              label: 'Total jam pelajaran',
                              value: controller.totalJp,
                              icon: Icons.schedule_outlined,
                              color: const Color(0xFF2563EB),
                              onTap: () => onNavigateTab(1),
                            ),
                          ];
                          return items[index];
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(
                    title: 'Menu cepat',
                    subtitle: 'Akses fitur utama aplikasi',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _openForm(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Modul'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const ModulSearchScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Cari Modul'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => onNavigateTab(3),
                        icon: const Icon(Icons.person_outline, size: 18),
                        label: const Text('Edit Profil'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SectionHeader(
                    title: 'Modul terbaru',
                    subtitle: 'Tiga modul yang terakhir diperbarui',
                    actionLabel: controller.totalModul > 0
                        ? 'Lihat semua'
                        : null,
                    onAction: controller.totalModul > 0
                        ? () => onNavigateTab(1)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  if (latest.isEmpty)
                    Card(
                      child: EmptyState(
                        icon: Icons.folder_open_outlined,
                        title: 'Belum ada modul ajar',
                        message: 'Tambahkan modul pertama untuk mulai mengelola perangkat ajar.',
                        actionLabel: 'Tambah Modul',
                        onAction: () => _openForm(context),
                        compact: true,
                      ),
                    )
                  else
                    ...latest.map(
                      (modul) => ModulCard(
                        modul: modul,
                        margin: const EdgeInsets.only(bottom: 8),
                        showMenu: false,
                        onTap: () => _openDetail(context, modul),
                      ),
                    ),
                  if (ringkasan.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    SectionHeader(
                      title: 'Ringkasan per mapel',
                      subtitle:
                          '${controller.totalTerbit} terbit · ${controller.totalDraft} draft',
                    ),
                    const SizedBox(height: 10),
                    _MapelSummaryCard(summaries: ringkasan),
                  ],
                  if (activities.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    SectionHeader(
                      title: 'Aktivitas terakhir',
                      subtitle: 'Riwayat perubahan modul ajar',
                      actionLabel: 'Lihat semua',
                      onAction: () => onNavigateTab(2),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < activities.length; i++) ...[
                              ActivityTile(
                                entry: activities[i],
                                dense: true,
                                onTap: () {
                                  final modul = controller.cariModul(
                                    activities[i].modulId,
                                  );
                                  if (modul != null) {
                                    _openDetail(context, modul);
                                  }
                                },
                              ),
                              if (i < activities.length - 1)
                                Divider(
                                  height: 1,
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.7),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.storage_outlined,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Data tersimpan pada basis data PostgreSQL di server',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.now,
    required this.firstName,
    required this.onSearch,
  });

  final DateTime now;
  final String firstName;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${sapaanWaktu(now)}, $firstName',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatHariTanggal(now),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onSearch,
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cari modul, mata pelajaran, atau materi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MotivationBanner extends StatefulWidget {
  const _MotivationBanner({
    required this.totalModul,
    required this.totalDraft,
    required this.totalTerbit,
    required this.totalFavorit,
  });

  final int totalModul;
  final int totalDraft;
  final int totalTerbit;
  final int totalFavorit;

  @override
  State<_MotivationBanner> createState() => _MotivationBannerState();
}

class _MotivationBannerState extends State<_MotivationBanner> {
  int _index = 0;

  List<_MotivationIdea> _buildIdeas() {
    final ideas = <_MotivationIdea>[
      const _MotivationIdea(
        icon: Icons.auto_awesome_rounded,
        title: 'Mulai dari satu modul',
        message:
            'Modul yang rapi tidak harus panjang. Tulis tujuan, langkah, dan '
            'asesmen singkat, lalu simpan sebagai draft.',
      ),
      const _MotivationIdea(
        icon: Icons.playlist_add_check_rounded,
        title: 'Rapikan langkah pembelajaran',
        message:
            'Pecah kegiatan menjadi pembuka, inti, dan penutup agar guru lain '
            'mudah memakai modulmu.',
      ),
      const _MotivationIdea(
        icon: Icons.auto_stories_rounded,
        title: 'Beri contoh nyata',
        message:
            'Satu contoh kontekstual sering lebih membantu daripada banyak '
            'teori. Tambahkan studi kasus singkat di modulmu.',
      ),
      const _MotivationIdea(
        icon: Icons.insights_rounded,
        title: 'Tinjau rekap berkala',
        message:
            'Buka rekap server untuk melihat sebaran modul dan jam pelajaran '
            'per mata pelajaran.',
      ),
    ];

    if (widget.totalModul == 0) {
      ideas.insert(
        0,
        const _MotivationIdea(
          icon: Icons.rocket_launch_rounded,
          title: 'Petualangan dimulai!',
          message:
              'Belum ada modul. Buat modul pertamamu, atau muat data contoh '
              'dari halaman profil untuk melihat isi aplikasi.',
        ),
      );
    } else if (widget.totalDraft > 0) {
      ideas.insert(
        0,
        _MotivationIdea(
          icon: Icons.edit_note_rounded,
          title: '${widget.totalDraft} draft menunggu',
          message:
              'Draft belum terlihat asyik? Lengkapi satu bagian kecil hari ini, '
              'lalu terbitkan saat sudah siap.',
        ),
      );
    } else {
      ideas.insert(
        0,
        _MotivationIdea(
          icon: Icons.verified_rounded,
          title: 'Semua modul sudah terbit',
          message:
              '${widget.totalTerbit} modul sudah terbit dan '
              '${widget.totalFavorit} ditandai favorit. Kerja bagus!',
        ),
      );
    }

    return ideas;
  }

  void _nextIdea(int total) {
    HapticFeedback.selectionClick();
    setState(() => _index = (_index + 1) % total);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ideas = _buildIdeas();
    final idea = ideas[_index % ideas.length];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _nextIdea(ideas.length),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.12),
                theme.colorScheme.primary.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    idea.icon,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: Column(
                      key: ValueKey(idea.title),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea.title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          idea.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Ganti ide',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _nextIdea(ideas.length),
                  icon: Icon(
                    Icons.autorenew_rounded,
                    size: 19,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MotivationIdea {
  const _MotivationIdea({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

class _MapelSummaryCard extends StatelessWidget {
  const _MapelSummaryCard({required this.summaries});

  final List<MapelSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < summaries.length; i++) ...[
              _MapelSummaryRow(summary: summaries[i]),
              if (i < summaries.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapelSummaryRow extends StatelessWidget {
  const _MapelSummaryRow({required this.summary});

  final MapelSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SubjectAvatar(mapel: summary.mapel, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.mapel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${summary.terbit} dari ${summary.total} modul terbit · '
                    '${summary.totalJp} JP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${(summary.progress * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: summary.progress),
          duration: const Duration(milliseconds: 750),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
