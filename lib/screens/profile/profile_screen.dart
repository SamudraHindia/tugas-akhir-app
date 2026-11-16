import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models/teacher_profile.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/page_width.dart';
import '../../widgets/section_header.dart';
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
      ..showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui.')));
  }

  Future<void> _resetSample(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Muat ulang data contoh?',
      message:
          'Data modul dan aktivitas saat ini akan diganti dengan data contoh bawaan aplikasi.',
      confirmLabel: 'Muat ulang',
      cancelLabel: 'Batal',
      destructive: false,
      icon: Icons.restore_rounded,
    );
    if (!confirmed || !context.mounted) return;

    await AppScope.read(context).muatDataContoh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Data contoh berhasil dimuat ulang.')),
      );
  }

  Future<void> _deleteAll(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus semua modul?',
      message:
          'Seluruh modul ajar dan riwayat aktivitas akan dihapus dari perangkat. Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus semua',
    );
    if (!confirmed || !context.mounted) return;

    await AppScope.read(context).hapusSemuaModul();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Semua modul telah dihapus.')));
  }

  void _showAbout(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDeep, AppColors.teal],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 28,
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
                title: 'Data aplikasi',
                subtitle: 'Kelola data yang tersimpan di perangkat ini.',
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
                        'Ganti data saat ini dengan modul contoh.',
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
                        'Menghapus seluruh modul dan riwayat aktivitas.',
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
                      subtitle: const Text('Informasi versi dan tujuan aplikasi.'),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
              ),
              if (controller.storageError != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
            Color(0xFF0D9488),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -48,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      profile.inisial,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          profile.jabatan,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.sekolah,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit profil',
                    onPressed: onEdit,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.13),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    _HeaderStat(label: 'Modul', value: totalModul),
                    _StatDivider(),
                    _HeaderStat(label: 'Terbit', value: totalTerbit),
                    _StatDivider(),
                    _HeaderStat(label: 'Favorit', value: totalFavorit),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Akun guru · Perangkat ajar Kurikulum Merdeka',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 9.5,
                      ),
                    ),
                  ),
                ],
              ),
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
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
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
      color: Colors.white.withValues(alpha: 0.16),
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
          color: theme.colorScheme.primary.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(10),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
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
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
