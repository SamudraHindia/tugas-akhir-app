import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../core/formatters.dart';
import '../../data/models/teacher_profile.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/page_width.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _sekolahController;
  late final TextEditingController _nipController;
  late final TextEditingController _emailController;

  bool _saving = false;
  bool _dirty = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final profile = AppScope.read(context).profile;
    _namaController = TextEditingController(text: profile.nama);
    _sekolahController = TextEditingController(text: profile.sekolah);
    _nipController = TextEditingController(text: profile.nip);
    _emailController = TextEditingController(text: profile.email);

    _namaController.addListener(_markDirty);
    _sekolahController.addListener(_markDirty);
    _nipController.addListener(_markDirty);
    _emailController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _sekolahController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!mounted || _dirty) return;
    setState(() => _dirty = true);
  }

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showConfirmDialog(
      context,
      title: 'Buang perubahan?',
      message: 'Perubahan profil yang belum disimpan akan hilang.',
      confirmLabel: 'Buang',
      cancelLabel: 'Lanjut mengedit',
      icon: Icons.undo_rounded,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  String? _validateRequired(String? value, String label, {int min = 3}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label wajib diisi.';
    if (text.length < min) return '$label minimal $min karakter.';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Periksa kembali data profil yang diisi.'),
          ),
        );
      return;
    }

    setState(() => _saving = true);
    final profile = TeacherProfile(
      nama: _namaController.text.trim(),
      sekolah: _sekolahController.text.trim(),
      nip: _nipController.text.trim(),
      email: _emailController.text.trim(),
    );

    try {
      await AppScope.read(context).perbaruiProfil(profile);
      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Kembali',
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Edit Profil'),
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            child: PageWidth(
              maxWidth: 620,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _namaController,
                            builder: (context, value, _) {
                              final initial = inisialNama(value.text);
                              return Container(
                                width: 74,
                                height: 74,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF115E59),
                                      Color(0xFF0D9488),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Informasi ini tampil di beranda dan halaman profil.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            key: const ValueKey('field-nama'),
                            controller: _namaController,
                            validator: (value) =>
                                _validateRequired(value, 'Nama'),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('field-sekolah'),
                            controller: _sekolahController,
                            validator: (value) =>
                                _validateRequired(value, 'Nama sekolah'),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            maxLength: 80,
                            decoration: const InputDecoration(
                              labelText: 'Sekolah',
                              prefixIcon: Icon(Icons.school_outlined),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nipController,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              if (!RegExp(r'^\d{18}$').hasMatch(text)) {
                                return 'NIP harus terdiri dari 18 digit angka.';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(18),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'NIP (opsional)',
                              prefixIcon: Icon(Icons.badge_outlined),
                              helperText: 'Kosongkan bila belum memiliki NIP.',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const ValueKey('field-email'),
                            controller: _emailController,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              final pattern = RegExp(
                                r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
                              );
                              if (!pattern.hasMatch(text)) {
                                return 'Format email belum benar.';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _save(),
                            decoration: const InputDecoration(
                              labelText: 'Email (opsional)',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Data profil disimpan secara lokal di perangkat ini dan tidak dikirim ke mana pun.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 19),
                      label: Text(
                        _saving ? 'Menyimpan...' : 'Simpan Profil',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
