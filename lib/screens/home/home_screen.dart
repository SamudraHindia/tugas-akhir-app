import 'package:flutter/material.dart';

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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHeader(
              controller: controller,
              now: now,
              onOpenProfile: () => onNavigateTab(3),
              onSearch: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ModulSearchScreen(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: PageWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  if (controller.storageError != null) ...[
                    _WarningBanner(message: controller.storageError!),
                    const SizedBox(height: 16),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 700 ? 4 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 4,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              mainAxisExtent: 120,
                            ),
                        itemBuilder: (context, index) {
                          final items = [
                            StatCard(
                              label: 'Total modul',
                              value: '${controller.totalModul}',
                              icon: Icons.auto_stories_rounded,
                              color: AppColors.primary,
                              onTap: () => onNavigateTab(1),
                            ),
                            StatCard(
                              label: 'Sudah terbit',
                              value: '${controller.totalTerbit}',
                              icon: Icons.verified_rounded,
                              color: AppColors.success,
                              onTap: () => onNavigateTab(1),
                            ),
                            StatCard(
                              label: 'Masih draft',
                              value: '${controller.totalDraft}',
                              icon: Icons.edit_note_rounded,
                              color: AppColors.accent,
                              onTap: () => onNavigateTab(1),
                            ),
                            StatCard(
                              label: 'Total jam pelajaran',
                              value: '${controller.totalJp}',
                              icon: Icons.timer_rounded,
                              color: const Color(0xFF2563EB),
                              onTap: () => onNavigateTab(1),
                            ),
                          ];
                          return items[index];
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(
                    title: 'Aksi cepat',
                    subtitle: 'Mulai kelola perangkat ajar kamu',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.note_add_rounded,
                          label: 'Modul\nbaru',
                          color: AppColors.primary,
                          onTap: () => _openForm(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.search_rounded,
                          label: 'Cari\nmodul',
                          color: const Color(0xFF2563EB),
                          onTap: () => Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const ModulSearchScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.manage_accounts_rounded,
                          label: 'Edit\nprofil',
                          color: AppColors.accent,
                          onTap: () => onNavigateTab(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SectionHeader(
                    title: 'Modul terbaru',
                    subtitle: 'Lanjutkan modul yang terakhir kamu kerjakan',
                    actionLabel: controller.totalModul > 0
                        ? 'Lihat semua'
                        : null,
                    onAction: controller.totalModul > 0
                        ? () => onNavigateTab(1)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (latest.isEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                      child: EmptyState(
                        icon: Icons.auto_stories_outlined,
                        title: 'Belum ada modul ajar',
                        message:
                            'Buat modul pertamamu dan susun perangkat ajar yang siap dipakai di kelas.',
                        actionLabel: 'Buat Modul Pertama',
                        onAction: () => _openForm(context),
                        compact: true,
                      ),
                    )
                  else
                    ...latest.map(
                      (modul) => ModulCard(
                        modul: modul,
                        margin: const EdgeInsets.only(bottom: 10),
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
                    const SizedBox(height: 12),
                    _MapelSummaryCard(summaries: ringkasan),
                  ],
                  if (activities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Aktivitas terakhir',
                      subtitle: 'Jejak perubahan pada modul ajar',
                      actionLabel: 'Lihat semua',
                      onAction: () => onNavigateTab(2),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
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
                                      .withValues(alpha: 0.5),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Data tersimpan otomatis di perangkat ini',
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
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.controller,
    required this.now,
    required this.onOpenProfile,
    required this.onSearch,
  });

  final AppController controller;
  final DateTime now;
  final VoidCallback onOpenProfile;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nameParts = controller.profile.nama.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? 'Guru' : nameParts.first;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            Color(0xFF0D9488),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _Orb(size: 190, opacity: 0.09),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _Orb(size: 170, opacity: 0.06),
          ),
          SafeArea(
            bottom: false,
            child: PageWidth(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ModulAjar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Kurikulum Merdeka',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: isDark
                            ? 'Gunakan tema terang'
                            : 'Gunakan tema gelap',
                        onPressed: () => controller.ubahTema(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(
                            alpha: 0.12,
                          ),
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onOpenProfile,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            controller.profile.inisial,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    formatHariTanggal(now),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sapaanWaktu(now)}, $firstName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Siap menyusun pembelajaran yang bermakna hari ini?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      onTap: onSearch,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        height: 47,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cari modul, mapel, atau materi...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${controller.totalModul} modul',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapelSummaryCard extends StatelessWidget {
  const _MapelSummaryCard({required this.summaries});

  final List<MapelSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < summaries.length; i++) ...[
              _MapelSummaryRow(summary: summaries[i]),
              if (i < summaries.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Divider(
                    height: 1,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.45,
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
            SubjectAvatar(mapel: summary.mapel, size: 36),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.mapel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: summary.progress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
