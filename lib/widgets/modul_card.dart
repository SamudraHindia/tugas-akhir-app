import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/subject_visual.dart';
import '../data/models/modul_ajar.dart';
import 'press_scale.dart';
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
      child: PressScale(
        enabled: onTap != null,
        child: Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.85),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SubjectAvatar(mapel: modul.mataPelajaran, size: 42),
                const SizedBox(width: 11),
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
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedScale(
                            scale: modul.favorit ? 1 : 0.55,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutBack,
                            child: AnimatedOpacity(
                              opacity: modul.favorit ? 1 : 0,
                              duration: const Duration(milliseconds: 160),
                              child: const Icon(
                                Icons.star_rounded,
                                size: 17,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        modul.judul,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
        Icon(
          icon,
          size: 19,
          color: color ?? theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
