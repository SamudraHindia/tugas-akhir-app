import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

enum _AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _sekolahController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;
  bool _busy = false;
  bool _submitted = false;
  bool _initialErrorLoaded = false;
  String? _error;

  bool get _isRegister => _mode == _AuthMode.register;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialErrorLoaded) return;
    _initialErrorLoaded = true;
    final authError = AppScope.read(context).authError;
    if (authError != null && authError.trim().isNotEmpty) {
      _error = authError;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _sekolahController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode mode) {
    if (_busy || mode == _mode) return;
    setState(() {
      _mode = mode;
      _submitted = false;
      _error = null;
    });
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi.';
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(text)) return 'Format email belum benar.';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Kata sandi wajib diisi.';
    if (_isRegister && text.length < 8) {
      return 'Kata sandi minimal 8 karakter.';
    }
    return null;
  }

  String? _validateRequired(String? value, String label) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label wajib diisi.';
    if (text.length < 3) return '$label minimal 3 karakter.';
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _submitted = true;
      _error = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = AppScope.read(context);
    setState(() => _busy = true);

    try {
      final ok = _isRegister
          ? await controller.register(
              nama: _namaController.text,
              sekolah: _sekolahController.text,
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await controller.login(
              _emailController.text,
              _passwordController.text,
            );

      if (!mounted) return;
      if (!ok) {
        setState(() {
          _error = controller.authError ?? 'Gagal memproses. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withValues(alpha: isDark ? 0.12 : 0.08),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: TweenAnimationBuilder<double>(
                    tween: const Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, child) => Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 18),
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppInfo.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppInfo.tagline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: AutofillGroup(
                              child: Form(
                                key: _formKey,
                                autovalidateMode: _submitted
                                    ? AutovalidateMode.onUserInteraction
                                    : AutovalidateMode.disabled,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      child: Column(
                                        key: ValueKey(_mode),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isRegister
                                                ? 'Buat akun guru'
                                                : 'Masuk ke akun',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _isRegister
                                                ? 'Daftar sekali, lalu kelola modul ajar milikmu sendiri.'
                                                : 'Gunakan email dan kata sandi akun gurumu.',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 14),
                                      _ErrorBanner(message: _error!),
                                    ],
                                    const SizedBox(height: 16),
                                    if (_isRegister) ...[
                                      TextFormField(
                                        key: const ValueKey('auth-nama'),
                                        controller: _namaController,
                                        validator: (value) =>
                                            _validateRequired(value, 'Nama'),
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                        maxLength: 60,
                                        decoration: const InputDecoration(
                                          labelText: 'Nama lengkap',
                                          prefixIcon: Icon(
                                            Icons.person_outline_rounded,
                                          ),
                                          counterText: '',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        key: const ValueKey('auth-sekolah'),
                                        controller: _sekolahController,
                                        validator: (value) => _validateRequired(
                                          value,
                                          'Nama sekolah',
                                        ),
                                        textCapitalization:
                                            TextCapitalization.words,
                                        textInputAction: TextInputAction.next,
                                        maxLength: 80,
                                        decoration: const InputDecoration(
                                          labelText: 'Sekolah',
                                          prefixIcon: Icon(
                                            Icons.school_outlined,
                                          ),
                                          counterText: '',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                    TextFormField(
                                      key: const ValueKey('auth-email'),
                                      controller: _emailController,
                                      validator: _validateEmail,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.email],
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(
                                          Icons.mail_outline_rounded,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      key: const ValueKey('auth-password'),
                                      controller: _passwordController,
                                      validator: _validatePassword,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: _isRegister
                                          ? const [AutofillHints.newPassword]
                                          : const [AutofillHints.password],
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: InputDecoration(
                                        labelText: 'Kata sandi',
                                        helperText: _isRegister
                                            ? 'Minimal 8 karakter.'
                                            : null,
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Tampilkan kata sandi'
                                              : 'Sembunyikan kata sandi',
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton(
                                      key: const ValueKey('auth-submit'),
                                      onPressed: _busy ? null : _submit,
                                      child: _busy
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _isRegister
                                                  ? 'Daftar & Masuk'
                                                  : 'Masuk',
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      key: const ValueKey('auth-toggle'),
                                      onPressed: _busy
                                          ? null
                                          : () => _switchMode(
                                              _isRegister
                                                  ? _AuthMode.login
                                                  : _AuthMode.register,
                                            ),
                                      child: Text(
                                        _isRegister
                                            ? 'Sudah punya akun? Masuk'
                                            : 'Belum punya akun? Daftar',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_isRegister) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.06,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Akun demo: demo@modulajar.local · password',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          '${AppInfo.name} v${AppInfo.version} · Data tersimpan di PostgreSQL',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 17, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
