import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models/teacher_profile.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/page_width.dart';
import '../../widgets/section_header.dart';
import 'change_password_dialog.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editProfile(BuildContext context) async {
    final updated = await Navigator.of(context).push<TeacherProfile>(
      MaterialPageRoute<TeacherProfile>(
        builder: (_) => const ProfileEditScreen(),
      ),
    );
    if (updated == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
  }

  Future<void> _resetSample(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Muat ulang data contoh?',
      message: 'Data modul dan aktivitas pada server akan diganti dengan data contoh bawaan aplikasi.',
      confirmLabel: 'Muat ulang',
      cancelLabel: 'Batal',
      destructive: false,
      icon: Icons.restore_rounded,
    );
    if (!confirmed || !context.mounted) return;

    final berhasil = await AppScope.read(context).muatDataContoh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            berhasil
                ? 'Data contoh berhasil dimuat ulang.'
                : 'Data contoh gagal dimuat. Periksa pesan kesalahan.',
          ),
        ),
      );
  }

  Future<void> _deleteAll(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus semua modul?',
      message: 'Seluruh modul ajar dan riwayat aktivitas akan dihapus dari basis data server. Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus semua',
    );
    if (!confirmed || !context.mounted) return;

    final berhasil = await AppScope.read(context).hapusSemuaModul();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            berhasil
                ? 'Semua modul telah dihapus.'
                : 'Penghapusan gagal. Periksa pesan kesalahan.',
          ),
        ),
      );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Keluar dari akun?',
      message:
          'Kamu perlu masuk kembali untuk mengakses modul ajar milikmu.',
      confirmLabel: 'Keluar',
      cancelLabel: 'Batal',
      icon: Icons.logout_rounded,
    );
    if (!confirmed || !context.mounted) return;

    await AppScope.read(context).logout();
  }

  Future<void> _changePassword(BuildContext context) async {
    final berhasil = await showChangePasswordDialog(context);
    if (!berhasil || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diubah. Sesi lain telah berakhir.'),
        ),
      );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final controller = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    var dialogTerbuka = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Menyiapkan ekspor CSV...')),
          ],
        ),
      ),
    );

    try {
      final csv = await controller.muatCsvModul();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      dialogTerbuka = false;

      await Clipboard.setData(ClipboardData(text: csv));
      if (!context.mounted) return;

      final baris = csv
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .length;
      final dataBaris = baris > 1 ? baris - 1 : 0;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'CSV rekap modul disalin ke clipboard ($dataBaris baris data).',
            ),
          ),
        );
    } catch (error) {
      if (!context.mounted) return;
      if (dialogTerbuka) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Ekspor CSV gagal: $error')),
        );
    }
  }

  void _showAbout(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          title: const Text(AppInfo.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppInfo.tagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.45,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Versi ${AppInfo.version} · Tugas Akhir',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showServerReport(BuildContext context) async {
    final controller = AppScope.read(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Memuat rekap dari layanan Python...')),
          ],
        ),
      ),
    );

    try {
      final summary = await controller.muatRingkasanServer();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          return AlertDialog(
            title: const Text('Rekap Data Server'),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ReportRow(
                      label: 'Total modul',
                      value: '${summary.totalModul}',
                    ),
                    _ReportRow(
                      label: 'Sudah terbit',
                      value: '${summary.totalTerbit}',
                    ),
                    _ReportRow(
                      label: 'Masih draft',
                      value: '${summary.totalDraft}',
                    ),
                    _ReportRow(label: 'Total JP', value: '${summary.totalJp}'),
                    _ReportRow(
                      label: 'Aktivitas tercatat',
                      value: '${summary.totalAktivitas}',
                    ),
                    const Divider(height: 22),
                    Text(
                      'Per mata pelajaran',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (summary.perMapel.isEmpty)
                      Text(
                        'Belum ada data modul.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...summary.perMapel
                          .take(6)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.mataPelajaran,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${item.total} modul · ${item.totalJp} JP',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    const SizedBox(height: 10),
                    Text(
                      'Dihitung oleh layanan Python (FastAPI) dari database PostgreSQL.',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Rekap gagal dimuat: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final profile = controller.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 6, bottom: 32),
        child: PageWidth(
          maxWidth: 820,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(
                profile: profile,
                totalModul: controller.totalModul,
                totalTerbit: controller.totalTerbit,
                totalFavorit: controller.totalFavorit,
                onEdit: () => _editProfile(context),
              ),
              const SizedBox(height: 22),
              SectionHeader(
                title: 'Informasi guru',
                actionLabel: 'Edit',
                onAction: () => _editProfile(context),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'NIP',
                      value: profile.nip.isEmpty ? 'Belum diisi' : profile.nip,
                    ),
                    const _InfoDivider(),
                    _InfoTile(
                      icon: Icons.school_outlined,
                      label: 'Sekolah',
                      value: profile.sekolah,
                    ),
                    const _InfoDivider(),
                    _InfoTile(
                      icon: Icons.mail_outline_rounded,
                      label: 'Email',
                      value: profile.email.isEmpty
                          ? 'Belum diisi'
                          : profile.email,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(
                title: 'Tampilan',
                subtitle: 'Sesuaikan tema aplikasi dengan kenyamananmu.',
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SegmentedButton<ThemeMode>(
                    expandedInsets: EdgeInsets.zero,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.brightness_auto_rounded, size: 17),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Terang'),
                        icon: Icon(Icons.light_mode_rounded, size: 17),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Gelap'),
                        icon: Icon(Icons.dark_mode_rounded, size: 17),
                      ),
                    ],
                    selected: {controller.themeMode},
                    onSelectionChanged: (selection) =>
                        controller.ubahTema(selection.first),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(
                title: 'Laporan server',
                subtitle:
                    'Rekap dari layanan Python, dapat diekspor sebagai CSV.',
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const _ActionIcon(
                        icon: Icons.analytics_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text('Muat rekap data'),
                      subtitle: const Text(
                        'Jumlah modul, status, JP, dan aktivitas per mata pelajaran.',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () => _showServerReport(context),
                    ),
                    if (controller.canLogout) ...[
                      const _InfoDivider(),
                      ListTile(
                        leading: const _ActionIcon(
                          icon: Icons.table_view_outlined,
                          color: AppColors.success,
                        ),
                        title: const Text('Ekspor CSV'),
                        subtitle: const Text(
                          'Salin rekap modul ke clipboard dalam format CSV.',
                        ),
                        trailing: const Icon(
                          Icons.download_rounded,
                          size: 20,
                        ),
                        onTap: () => _exportCsv(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(
                title: 'Data aplikasi',
                subtitle: 'Kelola data yang tersimpan pada basis data server.',
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const _ActionIcon(
                        icon: Icons.restore_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text('Muat ulang data contoh'),
                      subtitle: const Text(
                        'Ganti data server dengan modul contoh.',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () => _resetSample(context),
                    ),
                    const _InfoDivider(),
                    ListTile(
                      leading: const _ActionIcon(
                        icon: Icons.delete_sweep_rounded,
                        color: AppColors.danger,
                      ),
                      title: Text(
                        'Hapus semua modul',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      subtitle: const Text(
                        'Menghapus seluruh modul dan riwayat dari server.',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () => _deleteAll(context),
                    ),
                    const _InfoDivider(),
                    ListTile(
                      leading: const _ActionIcon(
                        icon: Icons.info_outline_rounded,
                        color: Color(0xFF2563EB),
                      ),
                      title: const Text('Tentang aplikasi'),
                      subtitle: const Text(
                        'Informasi versi dan tujuan aplikasi.',
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ),
              if (controller.canLogout) ...[
                const SizedBox(height: 22),
                const SectionHeader(
                  title: 'Akun',
                  subtitle: 'Kelola kata sandi dan sesi login pada perangkat ini.',
                ),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const _ActionIcon(
                          icon: Icons.lock_reset_rounded,
                          color: AppColors.primary,
                        ),
                        title: const Text('Ubah kata sandi'),
                        subtitle: const Text(
                          'Perbarui kata sandi akun dan akhiri sesi lain.',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                        onTap: () => _changePassword(context),
                      ),
                      const _InfoDivider(),
                      ListTile(
                        leading: const _ActionIcon(
                          icon: Icons.logout_rounded,
                          color: AppColors.danger,
                        ),
                        title: Text(
                          'Keluar',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        subtitle: Text(
                          controller.session?.user.email.isNotEmpty == true
                              ? 'Masuk sebagai ${controller.session!.user.email}'
                              : 'Akhiri sesi login di perangkat ini.',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
              ],
              if (controller.storageError != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    controller.storageError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Center(
                child: Text(
                  '${AppInfo.name} v${AppInfo.version} · Dibuat untuk Tugas Akhir',
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
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.totalModul,
    required this.totalTerbit,
    required this.totalFavorit,
    required this.onEdit,
  });

  final TeacherProfile profile;
  final int totalModul;
  final int totalTerbit;
  final int totalFavorit;
  final VoidCallback onEdit;

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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
                child: Text(
                  profile.inisial,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.jabatan,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.sekolah,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit profil',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeaderStat(label: 'Modul', value: totalModul),
              _StatDivider(),
              _HeaderStat(label: 'Terbit', value: totalTerbit),
              _StatDivider(),
              _HeaderStat(label: 'Favorit', value: totalFavorit),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value.toDouble()),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => Text(
              '${animated.round()}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 1),
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

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      color: Theme.of(context).colorScheme.outlineVariant
          .withValues(alpha: 0.7),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
      title: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 62,
      color: Theme.of(context).colorScheme.outlineVariant
          .withValues(alpha: 0.4),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
