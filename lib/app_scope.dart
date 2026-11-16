import 'package:flutter/widgets.dart';

import 'state/app_controller.dart';

/// Menyediakan [AppController] ke seluruh widget tree dan ikut rebuild
/// ketika controller memberi notifikasi.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di widget tree.');
    return scope!.notifier!;
  }

  static AppController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di widget tree.');
    return scope!.notifier!;
  }
}
