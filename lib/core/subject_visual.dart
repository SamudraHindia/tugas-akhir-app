import 'package:flutter/material.dart';

/// Ikon dan warna aksen yang konsisten untuk setiap mata pelajaran.
@immutable
class SubjectVisual {
  const SubjectVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  static SubjectVisual forMapel(String mapel) {
    final key = mapel.toLowerCase();

    if (key.contains('matematika')) {
      return const SubjectVisual(
        icon: Icons.calculate_rounded,
        color: Color(0xFF2563EB),
      );
    }
    if (key.contains('fisika')) {
      return const SubjectVisual(
        icon: Icons.science_rounded,
        color: Color(0xFF7C3AED),
      );
    }
    if (key.contains('kimia')) {
      return const SubjectVisual(
        icon: Icons.biotech_rounded,
        color: Color(0xFFEA580C),
      );
    }
    if (key.contains('biologi')) {
      return const SubjectVisual(
        icon: Icons.eco_rounded,
        color: Color(0xFF16A34A),
      );
    }
    if (key.contains('indonesia')) {
      return const SubjectVisual(
        icon: Icons.menu_book_rounded,
        color: Color(0xFFE11D48),
      );
    }
    if (key.contains('inggris')) {
      return const SubjectVisual(
        icon: Icons.translate_rounded,
        color: Color(0xFF4F46E5),
      );
    }
    if (key.contains('sejarah')) {
      return const SubjectVisual(
        icon: Icons.history_edu_rounded,
        color: Color(0xFFB45309),
      );
    }
    if (key.contains('ekonomi')) {
      return const SubjectVisual(
        icon: Icons.trending_up_rounded,
        color: Color(0xFF059669),
      );
    }
    if (key.contains('geografi')) {
      return const SubjectVisual(
        icon: Icons.public_rounded,
        color: Color(0xFF0D9488),
      );
    }
    if (key.contains('sosiologi')) {
      return const SubjectVisual(
        icon: Icons.groups_rounded,
        color: Color(0xFF9333EA),
      );
    }
    if (key.contains('informatika')) {
      return const SubjectVisual(
        icon: Icons.code_rounded,
        color: Color(0xFF0891B2),
      );
    }
    if (key.contains('seni')) {
      return const SubjectVisual(
        icon: Icons.palette_rounded,
        color: Color(0xFFDB2777),
      );
    }
    if (key.contains('pjok') || key.contains('olahraga')) {
      return const SubjectVisual(
        icon: Icons.sports_soccer_rounded,
        color: Color(0xFFDC2626),
      );
    }
    if (key.contains('pancasila')) {
      return const SubjectVisual(
        icon: Icons.account_balance_rounded,
        color: Color(0xFF0F766E),
      );
    }
    if (key.contains('prakarya')) {
      return const SubjectVisual(
        icon: Icons.handyman_rounded,
        color: Color(0xFF65A30D),
      );
    }
    if (key.contains('jawa')) {
      return const SubjectVisual(
        icon: Icons.auto_stories_rounded,
        color: Color(0xFF92400E),
      );
    }

    return const SubjectVisual(
      icon: Icons.school_rounded,
      color: Color(0xFF64748B),
    );
  }
}
