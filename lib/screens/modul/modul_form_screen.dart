import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/constants.dart';
import '../../data/models/modul_ajar.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/page_width.dart';
import '../../widgets/string_list_editor.dart';

class ModulFormScreen extends StatefulWidget {
  const ModulFormScreen({super.key, this.modul});

  final ModulAjar? modul;

  bool get isEdit => modul != null;

  @override
  State<ModulFormScreen> createState() => _ModulFormScreenState();
}

class _ModulFormScreenState extends State<ModulFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _judulController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _kegiatanController;
  late final TextEditingController _asesmenController;

  late final List<String> _mapelOptions;
  late String _mataPelajaran;
  late String _kelas;
  late String _semester;
  late int _alokasiJp;
  late List<String> _tujuan;
  late List<String> _materi;
  late ModulStatus _status;

  bool _saving = false;
  bool _dirty = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final modul = widget.modul;
    _judulController = TextEditingController(text: modul?.judul ?? '');
    _deskripsiController = TextEditingController(text: modul?.deskripsi ?? '');
    _kegiatanController = TextEditingController(
      text: modul?.kegiatanPembelajaran ?? '',
    );
    _asesmenController = TextEditingController(text: modul?.asesmen ?? '');
    _mataPelajaran = modul?.mataPelajaran ?? ModulOptions.mapel.first;
    _mapelOptions = {
      ...ModulOptions.mapel,
      if (!ModulOptions.mapel.contains(_mataPelajaran)) _mataPelajaran,
    }.toList();
    _kelas = modul?.kelas ?? 'X';
    _semester = modul?.semester ?? 'Ganjil';
    _alokasiJp = modul?.alokasiJp ?? 4;
    _tujuan = [...?modul?.tujuanPembelajaran];
    _materi = [...?modul?.materiPokok];
    _status = modul?.status ?? ModulStatus.draft;

    _judulController.addListener(_markDirty);
    _deskripsiController.addListener(_markDirty);
    _kegiatanController.addListener(_markDirty);
    _asesmenController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _kegiatanController.dispose();
    _asesmenController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!mounted || _dirty) return;
    setState(() => _dirty = true);
  }

  void _update(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
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
      message:
          'Perubahan yang belum disimpan akan hilang. Yakin ingin keluar dari form ini?',
      confirmLabel: 'Buang',
      cancelLabel: 'Lanjut mengedit',
      icon: Icons.undo_rounded,
    );
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _validateJudul(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Judul modul wajib diisi.';
    if (text.length < 5) return 'Judul minimal 5 karakter.';
    return null;
  }

  String? _validateTeks(String? value, String label, int minLength) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label wajib diisi.';
    if (text.length < minLength) {
      return '$label minimal $minLength karakter.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitted = true);

    final formValid = _formKey.currentState?.validate() ?? false;
    final listsValid = _tujuan.isNotEmpty && _materi.isNotEmpty;
    if (!formValid || !listsValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Lengkapi bagian yang ditandai sebelum menyimpan.'),
          ),
        );
      return;
    }

    setState(() => _saving = true);
    final controller = AppScope.read(context);
    final now = DateTime.now();
    final original = widget.modul;

    final modul = ModulAjar(
      id: original?.id ?? '',
      judul: _judulController.text.trim(),
      mataPelajaran: _mataPelajaran,
      kelas: _kelas,
      semester: _semester,
      alokasiJp: _alokasiJp,
      deskripsi: _deskripsiController.text.trim(),
      tujuanPembelajaran: List.unmodifiable(_tujuan),
      materiPokok: List.unmodifiable(_materi),
      kegiatanPembelajaran: _kegiatanController.text.trim(),
      asesmen: _asesmenController.text.trim(),
      status: _status,
      favorit: original?.favorit ?? false,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final saved = original == null
          ? await controller.tambahModul(modul)
          : await controller.perbaruiModul(modul);
      if (!mounted) return;
      if (saved == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modul tidak ditemukan. Mungkin sudah dihapus.'),
          ),
        );
        setState(() => _saving = false);
        return;
      }
      Navigator.of(context).pop(saved);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fase = ModulOptions.faseUntukKelas(_kelas);

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
          title: Text(widget.isEdit ? 'Edit Modul' : 'Modul Baru'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Simpan'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 6, bottom: 32),
            child: PageWidth(
              maxWidth: 820,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormSection(
                    icon: Icons.info_outline_rounded,
                    title: 'Informasi umum',
                    subtitle: 'Identitas modul ajar yang akan dipakai di kelas.',
                    child: Column(
                      children: [
                        TextFormField(
                          key: const ValueKey('field-judul'),
                          controller: _judulController,
                          validator: _validateJudul,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 120,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Judul modul',
                            hintText: 'Contoh: Persamaan dan Fungsi Kuadrat',
                            prefixIcon: Icon(Icons.auto_stories_rounded),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 540;
                            final mapel = _LabeledDropdown<String>(
                              label: 'Mata pelajaran',
                              value: _mataPelajaran,
                              prefixIcon: Icons.menu_book_rounded,
                              items: _mapelOptions
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => _update(
                                () => _mataPelajaran = value,
                              ),
                            );
                            final kelas = _LabeledDropdown<String>(
                              label: 'Kelas',
                              value: _kelas,
                              prefixIcon: Icons.groups_2_rounded,
                              items: ModulOptions.kelas
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        'Kelas $item '
                                        '(Fase ${ModulOptions.faseUntukKelas(item)})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => _update(
                                () => _kelas = value,
                              ),
                            );
                            if (!wide) {
                              return Column(
                                children: [
                                  mapel,
                                  const SizedBox(height: 14),
                                  kelas,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: mapel),
                                const SizedBox(width: 12),
                                Expanded(child: kelas),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.07,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Fase $fase · Semester $_semester · '
                                  'Kurikulum Merdeka',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 540;
                            final semester = _LabeledDropdown<String>(
                              label: 'Semester',
                              value: _semester,
                              prefixIcon: Icons.calendar_month_rounded,
                              items: ModulOptions.semester
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => _update(
                                () => _semester = value,
                              ),
                            );
                            final alokasi = _JpStepper(
                              value: _alokasiJp,
                              onChanged: (value) =>
                                  _update(() => _alokasiJp = value),
                            );
                            if (!wide) {
                              return Column(
                                children: [
                                  semester,
                                  const SizedBox(height: 14),
                                  alokasi,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: semester),
                                const SizedBox(width: 12),
                                Expanded(child: alokasi),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey('field-deskripsi'),
                          controller: _deskripsiController,
                          validator: (value) =>
                              _validateTeks(value, 'Deskripsi', 20),
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi singkat',
                            hintText:
                                'Ringkasan materi dan fokus pembelajaran modul.',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FormSection(
                    icon: Icons.flag_outlined,
                    title: 'Tujuan & materi',
                    subtitle:
                        'Rumuskan capaian pembelajaran dan materi pokok.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(text: 'Tujuan pembelajaran'),
                        StringListEditor(
                          values: _tujuan,
                          inputKey: const ValueKey('field-tujuan-input'),
                          hintText: 'Tambahkan tujuan pembelajaran...',
                          emptyText:
                              'Belum ada tujuan. Tambahkan minimal satu tujuan.',
                          errorText: _submitted && _tujuan.isEmpty
                              ? 'Tujuan pembelajaran wajib diisi.'
                              : null,
                          onChanged: (values) =>
                              _update(() => _tujuan = values),
                        ),
                        const SizedBox(height: 18),
                        _FieldLabel(text: 'Materi pokok'),
                        StringListEditor(
                          values: _materi,
                          inputKey: const ValueKey('field-materi-input'),
                          hintText: 'Tambahkan materi pokok...',
                          emptyText:
                              'Belum ada materi. Tambahkan minimal satu materi.',
                          errorText: _submitted && _materi.isEmpty
                              ? 'Materi pokok wajib diisi.'
                              : null,
                          onChanged: (values) =>
                              _update(() => _materi = values),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FormSection(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Kegiatan & asesmen',
                    subtitle:
                        'Gambarkan alur pembelajaran dan cara menilai siswa.',
                    child: Column(
                      children: [
                        TextFormField(
                          key: const ValueKey('field-kegiatan'),
                          controller: _kegiatanController,
                          validator: (value) =>
                              _validateTeks(value, 'Kegiatan pembelajaran', 15),
                          minLines: 4,
                          maxLines: 8,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Kegiatan pembelajaran',
                            hintText:
                                'Tuliskan langkah kegiatan per pertemuan...',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey('field-asesmen'),
                          controller: _asesmenController,
                          validator: (value) =>
                              _validateTeks(value, 'Asesmen', 10),
                          minLines: 3,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Asesmen',
                            hintText:
                                'Formatif, sumatif, proyek, atau rubrik penilaian...',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FormSection(
                    icon: Icons.public_rounded,
                    title: 'Publikasi',
                    subtitle:
                        'Modul draft dapat dilengkapi dulu sebelum diterbitkan.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SegmentedButton<ModulStatus>(
                          segments: const [
                            ButtonSegment(
                              value: ModulStatus.draft,
                              label: Text('Draft'),
                              icon: Icon(Icons.edit_note_rounded, size: 18),
                            ),
                            ButtonSegment(
                              value: ModulStatus.terbit,
                              label: Text('Terbit'),
                              icon: Icon(Icons.check_circle_outline_rounded, size: 18),
                            ),
                          ],
                          selected: {_status},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) => _update(
                            () => _status = selection.first,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                _status == ModulStatus.terbit
                                    ? 'Modul akan langsung dihitung sebagai modul terbit di beranda.'
                                    : 'Modul tetap tersimpan sebagai draft dan bisa diterbitkan kapan saja.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('tombol-simpan-modul'),
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
                        _saving
                            ? 'Menyimpan...'
                            : widget.isEdit
                            ? 'Simpan Perubahan'
                            : 'Simpan Modul',
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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.prefixIcon,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _JpStepper extends StatelessWidget {
  const _JpStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Alokasi waktu',
        prefixIcon: Icon(Icons.timer_outlined, size: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kurangi JP',
            visualDensity: VisualDensity.compact,
            onPressed: value <= ModulOptions.minAlokasiJp
                ? null
                : () => onChanged(value - 1),
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          ),
          Expanded(
            child: Text(
              '$value JP',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tambah JP',
            visualDensity: VisualDensity.compact,
            onPressed: value >= ModulOptions.maxAlokasiJp
                ? null
                : () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
