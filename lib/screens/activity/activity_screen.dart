import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/formatters.dart';
import '../../data/models/activity_entry.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_width.dart';
import '../modul/modul_detail_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  String _dayLabel(DateTime time) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final date = DateUtils.dateOnly(time);
    if (date == today) return 'Hari ini';
    if (date == today.subtract(const Duration(days: 1))) return 'Kemarin';
    return formatTanggalLengkap(time);
  }

  Future<void> _clearAll(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Bersihkan aktivitas?',
      message:
          'Seluruh riwayat aktivitas akan dihapus. Data modul ajar tetap aman.',
      confirmLabel: 'Bersihkan',
      icon: Icons.delete_sweep_rounded,
    );
    if (!confirmed || !context.mounted) return;

    await AppScope.read(context).hapusSemuaAktivitas();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Riwayat aktivitas dibersihkan.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final activities = controller.activities;
    final groups = <String, List<ActivityEntry>>{};
    for (final entry in activities) {
      groups.putIfAbsent(_dayLabel(entry.timestamp), () => []).add(entry);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas'),
        actions: [
          IconButton(
            tooltip: 'Bersihkan aktivitas',
            onPressed: activities.isEmpty ? null : () => _clearAll(context),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: activities.isEmpty
          ? const EmptyState(
              icon: Icons.timeline_rounded,
              title: 'Belum ada aktivitas',
              message:
                  'Setiap modul yang kamu buat, ubah, terbitkan, atau hapus akan tercatat di sini.',
            )
          : PageWidth(
              maxWidth: 820,
              child: ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.09,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            size: 19,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jejak perubahan modul',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${activities.length} aktivitas terakhir tersimpan',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final group in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 8),
                      child: Text(
                        group.key,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < group.value.length;
                              i++
                            ) ...[
                              ActivityTile(
                                entry: group.value[i],
                                onTap: () {
                                  final modul = controller.cariModul(
                                    group.value[i].modulId,
                                  );
                                  if (modul == null) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Modul terkait sudah tidak tersedia.',
                                          ),
                                        ),
                                      );
                                    return;
                                  }
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ModulDetailScreen(
                                        modulId: modul.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (i < group.value.length - 1)
                                Divider(
                                  height: 1,
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.45),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),
    );
  }
}
