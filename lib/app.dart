import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'core/app_theme.dart';
import 'data/app_storage.dart';
import 'screens/root_shell.dart';
import 'screens/splash_screen.dart';
import 'state/app_controller.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.storage, this.controller});

  /// Dapat diinjeksi pada pengujian agar tidak bergantung plugin platform.
  final AppStorage? storage;
  final AppController? controller;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        AppController(widget.storage ?? SharedPreferencesStorage());
    if (!_controller.isReady) {
      _controller.initialize();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'ModulAjar',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _controller.themeMode,
            builder: (context, child) {
              return MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.4,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: _controller.isReady
                ? const RootShell()
                : const SplashScreen(),
          );
        },
      ),
    );
  }
}
