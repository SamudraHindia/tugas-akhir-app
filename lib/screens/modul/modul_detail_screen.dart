import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/subject_visual.dart';
import '../../data/models/modul_ajar.dart';
import '../../state/app_controller.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/page_width.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/subject_avatar.dart';
import 'modul_form_screen.dart';

enum _DetailAction { edit, duplikat, hapus }

class ModulDetailScreen extends StatelessWidget {
  const ModulDetailScreen({super.key, required this.modulId});

  final String modulId;

  Future<void> _toggleFavorit(
    BuildContext context,
    AppController controller,
    ModulAjar modul,
  ) async {
    final wasFavorite = modul.favorit;
    final berhasil = await controller.toggleFavorit(modul.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            !berhasil
                ? (controller.storageError ??
                      'Status favorit gagal disimpan ke server.')
                : wasFavorite
                ? 'Modul dihapus dari favorit.'
                : 'Modul ditambahkan ke favorit.',
          ),
        ),
      );
  }

  Future<void> _toggleStatus(
    BuildContext context,
    AppController controller,
    ModulAjar modul,
  ) async {
    final wasDraft = modul.isDraft;
    final updated = await controller.ubahStatus(modul.id);
    if (!context.mounted) return;
    if (updated == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              controller.storageError ??
                  'Status modul gagal disimpan ke server.',
            ),
          ),
        );
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasDraft
                ? 'Modul berhasil diterbitkan.'
                : 'Modul dikembalikan ke draft.',
          ),
        ),
      );
  }

  Future<void> _edit(BuildContext context, ModulAjar modul) async {
    final saved = await Navigator.of(context).push<ModulAjar>(
      MaterialPageRoute<ModulAjar>(
        builder: (_) => ModulFormScreen(modul: modul),
      ),
    );
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Perubahan "${saved.judul}" tersimpan.')),
      );
  }

  Future<void> _duplicate(
    BuildContext context,
    AppController controller,
    ModulAjar modul,
  ) async {
    final copy = await controller.duplikatModul(modul.id);
    if (copy == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Salinan "${modul.judul}" dibuat.'),
          action: SnackBarAction(
            label: 'Buka',
            onPressed: () {
              Navigator.of(context).pushReplacement<void, void>(
                MaterialPageRoute<void>(
                  builder: (_) => ModulDetailScreen(modulId: copy.id),
                ),
              );
            },
          ),
        ),
      );
  }

  Future<void> _delete(
    BuildContext context,
    AppController controller,
    ModulAjar modul,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus modul?',
      message:
          '"${modul.judul}" akan dihapus. Kamu masih bisa mengurungkannya sesaat setelah ini.',
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !context.mounted) return;

    final removed = await controller.hapusModul(modul.id);
    if (!context.mounted || removed == null) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${removed.judul}" dihapus.'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => controller.pulihkanModul(removed),
          ),
        ),
      );
  }

  void _handleAction(
    BuildContext context,
    AppController controller,
    ModulAjar modul,
    _DetailAction action,
  ) {
    switch (action) {
      case _DetailAction.edit:
        _edit(context, modul);
      case _DetailAction.duplikat:
        _duplicate(context, controller, modul);
      case _DetailAction.hapus:
        _delete(context, controller, modul);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final modul = controller.cariModul(modulId);

    if (modul == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Modul')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text('Modul tidak ditemukan', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Modul mungkin sudah dihapus dari server.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    final visual = SubjectVisual.forMapel(modul.mataPelajaran);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Modul'),
        actions: [
          IconButton(
            key: const ValueKey('tombol-favorit'),
            tooltip: modul.favorit ? 'Hapus dari favorit' : 'Tambah ke favorit',
            onPressed: () => _toggleFavorit(context, controller, modul),
            icon: Icon(
              modul.favorit ? Icons.star_rounded : Icons.star_outline_rounded,
              color: modul.favorit ? AppColors.accent : null,
            ),
          ),
          PopupMenuButton<_DetailAction>(
            tooltip: 'Aksi lainnya',
            onSelected: (action) =>
                _handleAction(context, controller, modul, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _DetailAction.edit,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit modul'),
                ),
              ),
              PopupMenuItem(
                value: _DetailAction.duplikat,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.copy_rounded),
                  title: Text('Duplikat'),
                ),
              ),
              PopupMenuItem(
                value: _DetailAction.hapus,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Hapus'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 6, bottom: 106),
        child: PageWidth(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailHero(modul: modul),
              const SizedBox(height: 14),
              _MetaCard(modul: modul),
              const SizedBox(height: 14),
              _DetailSection(
                icon: Icons.notes_rounded,
                title: 'Deskripsi',
                child: Text(
                  modul.deskripsi.isEmpty
                      ? 'Belum ada deskripsi.'
                      : modul.deskripsi,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.65,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _DetailSection(
                icon: Icons.flag_rounded,
                title: 'Tujuan Pembelajaran',
                trailing: '${modul.tujuanPembelajaran.length} tujuan',
                child: modul.tujuanPembelajaran.isEmpty
                    ? const _EmptyText(text: 'Belum ada tujuan pembelajaran.')
                    : Column(
                        children: [
                          for (
                            var i = 0;
                            i < modul.tujuanPembelajaran.length;
                            i++
                          )
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == modul.tujuanPembelajaran.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 23,
                                    height: 23,
                                    margin: const EdgeInsets.only(top: 1),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.11),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      modul.tujuanPembelajaran[i],
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(height: 1.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 14),
              _DetailSection(
                icon: Icons.inventory_2_rounded,
                title: 'Materi Pokok',
                trailing: '${modul.materiPokok.length} materi',
                child: modul.materiPokok.isEmpty
                    ? const _EmptyText(text: 'Belum ada materi pokok.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: modul.materiPokok.map((materi) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: visual.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: visual.color.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              materi,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: visual.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _DetailSection(
                icon: Icons.play_circle_outline_rounded,
                title: 'Kegiatan Pembelajaran',
                child: Text(
                  modul.kegiatanPembelajaran.isEmpty
                      ? 'Belum ada kegiatan pembelajaran.'
                      : modul.kegiatanPembelajaran,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.65,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _DetailSection(
                icon: Icons.fact_check_outlined,
                title: 'Asesmen',
                child: Text(
                  modul.asesmen.isEmpty ? 'Belum ada asesmen.' : modul.asesmen,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.65,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Dibuat ${formatTanggal(modul.createdAt)} · '
                  'Diperbarui ${formatWaktuRelatif(modul.updatedAt)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('tombol-status'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () =>
                            _toggleStatus(context, controller, modul),
                        icon: Icon(
                          modul.isDraft
                              ? Icons.publish_rounded
                              : Icons.unpublished_rounded,
                          size: 18,
                        ),
                        label: Text(modul.isDraft ? 'Terbitkan' : 'Draft'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('tombol-edit-modul'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () => _edit(context, modul),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit Modul'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.modul});

  final ModulAjar modul;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.85),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SubjectAvatar(mapel: modul.mataPelajaran, size: 42),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modul.mataPelajaran,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelas ${modul.kelas} · Semester ${modul.semester}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: modul.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            modul.judul,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaBadge(
                icon: Icons.school_outlined,
                label: 'Kelas ${modul.kelas} · Fase ${modul.fase}',
              ),
              _MetaBadge(
                icon: Icons.calendar_today_outlined,
                label: 'Semester ${modul.semester}',
              ),
              _MetaBadge(
                icon: Icons.schedule_outlined,
                label: '${modul.alokasiJp} JP',
              ),
              if (modul.favorit)
                const _MetaBadge(icon: Icons.star_border, label: 'Favorit'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Diperbarui ${formatWaktuRelatif(modul.updatedAt)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.modul});

  final ModulAjar modul;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = SubjectVisual.forMapel(modul.mataPelajaran);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: width,
                  child: _MetaTile(
                    icon: Icons.menu_book_rounded,
                    color: visual.color,
                    label: 'Mata pelajaran',
                    value: modul.mataPelajaran,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetaTile(
                    icon: Icons.groups_2_rounded,
                    color: const Color(0xFF2563EB),
                    label: 'Kelas & fase',
                    value: 'Kelas ${modul.kelas} · Fase ${modul.fase}',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetaTile(
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF7C3AED),
                    label: 'Semester',
                    value: modul.semester,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetaTile(
                    icon: Icons.timer_rounded,
                    color: AppColors.accent,
                    label: 'Alokasi waktu',
                    value: '${modul.alokasiJp} jam pelajaran',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetaTile(
                    icon: Icons.event_rounded,
                    color: AppColors.success,
                    label: 'Dibuat',
                    value: formatTanggalSingkat(modul.createdAt),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _MetaTile(
                    icon: Icons.update_rounded,
                    color: theme.colorScheme.primary,
                    label: 'Diperbarui',
                    value: formatTanggalSingkat(modul.updatedAt),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 9.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 17, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 9),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
