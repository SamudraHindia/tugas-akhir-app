import 'package:flutter/foundation.dart';

enum ActivityType {
  dibuat('Modul dibuat'),
  diperbarui('Modul diperbarui'),
  dihapus('Modul dihapus'),
  dipulihkan('Modul dipulihkan'),
  diterbitkan('Modul diterbitkan'),
  ditarikDraft('Modul dikembalikan ke draft'),
  diduplikasi('Modul diduplikasi');

  const ActivityType(this.label);

  final String label;

  static ActivityType fromKey(String? key) {
    return ActivityType.values.firstWhere(
      (type) => type.name == key,
      orElse: () => ActivityType.diperbarui,
    );
  }
}

/// Catatan aktivitas CRUD modul untuk halaman Aktivitas.
@immutable
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.type,
    required this.modulId,
    required this.judulModul,
    required this.timestamp,
  });

  final String id;
  final ActivityType type;
  final String modulId;
  final String judulModul;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'modulId': modulId,
      'judulModul': judulModul,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim();
    if (id == null || id.isEmpty) {
      throw const FormatException('Aktivitas tanpa id tidak dapat dibaca.');
    }
    return ActivityEntry(
      id: id,
      type: ActivityType.fromKey(json['type'] as String?),
      modulId: (json['modulId'] as String?) ?? '',
      judulModul: (json['judulModul'] as String?) ?? 'Modul ajar',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
