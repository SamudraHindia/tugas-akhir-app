import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/subject_visual.dart';
import '../data/models/modul_ajar.dart';
import 'status_badge.dart';
import 'subject_avatar.dart';

enum ModulCardAction { favorit, edit, duplikat, hapus }

class ModulCard extends StatelessWidget {
  const ModulCard({
    super.key,
    required this.modul,
    this.onTap,
    this.onAction,
    this.showMenu = true,
    this.margin = EdgeInsets.zero,
  });

  final ModulAjar modul;
  final VoidCallback? onTap;
  final ValueChanged<ModulCardAction>? onAction;
  final bool showMenu;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = SubjectVisual.forMapel(modul.mataPelajaran);

    return Padding(
      padding: margin,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubjectAvatar(mapel: modul.mataPelajaran, size: 46),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              modul.mataPelajaran.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: visual.color,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (modul.favorit) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star_rounded,
                              size: 17,
                              color: AppColors.accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        modul.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 5,
                        children: [
                          _MetaItem(
                            icon: Icons.schedule_rounded,
                            text: '${modul.alokasiJp} JP',
                          ),
                          _MetaItem(
                            icon: Icons.school_rounded,
                            text: 'Kelas ${modul.kelas}',
                          ),
                          _MetaItem(
                            icon: Icons.calendar_month_rounded,
                            text: modul.semester,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          StatusBadge(status: modul.status, compact: true),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              formatWaktuRelatif(modul.updatedAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showMenu && onAction != null)
                  PopupMenuButton<ModulCardAction>(
                    tooltip: 'Aksi modul',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    padding: EdgeInsets.zero,
                    onSelected: onAction,
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: ModulCardAction.favorit,
                          child: _MenuRow(
                            icon: modul.favorit
                                ? Icons.star_outline_rounded
                                : Icons.star_rounded,
                            label: modul.favorit
                                ? 'Hapus dari favorit'
                                : 'Tambah ke favorit',
                          ),
                        ),
                        const PopupMenuItem(
                          value: ModulCardAction.edit,
                          child: _MenuRow(
                            icon: Icons.edit_outlined,
                            label: 'Edit modul',
                          ),
                        ),
                        const PopupMenuItem(
                          value: ModulCardAction.duplikat,
                          child: _MenuRow(
                            icon: Icons.copy_rounded,
                            label: 'Duplikat',
                          ),
                        ),
                        PopupMenuItem(
                          value: ModulCardAction.hapus,
                          child: _MenuRow(
                            icon: Icons.delete_outline_rounded,
                            label: 'Hapus',
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ];
                    },
                  )
                else
                  const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 19, color: color ?? theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
