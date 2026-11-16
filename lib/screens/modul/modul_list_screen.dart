import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models/modul_ajar.dart';
import '../../state/app_controller.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/modul_card.dart';
import '../../widgets/page_width.dart';
import 'modul_detail_screen.dart';
import 'modul_form_screen.dart';

class ModulListScreen extends StatefulWidget {
  const ModulListScreen({super.key});

  @override
  State<ModulListScreen> createState() => _ModulListScreenState();
}

class _ModulListScreenState extends State<ModulListScreen> {
  final TextEditingController _searchController = TextEditingController();

  ModulFilter _filter = ModulFilter.semua;
  ModulSort _sort = ModulSort.terbaru;
  String? _mapel;
  String? _kelas;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilter =>
      _filter != ModulFilter.semua || _mapel != null || _kelas != null;

  Future<void> _openDetail(ModulAjar modul) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ModulDetailScreen(modulId: modul.id),
      ),
    );
  }

  Future<void> _openForm({ModulAjar? modul}) async {
    final saved = await Navigator.of(context).push<ModulAjar>(
      MaterialPageRoute<ModulAjar>(
        builder: (_) => ModulFormScreen(modul: modul),
      ),
    );
    if (saved == null || !mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            modul == null
                ? 'Modul "${saved.judul}" berhasil dibuat.'
                : 'Perubahan pada "${saved.judul}" tersimpan.',
          ),
        ),
      );
    if (modul == null) {
      await _openDetail(saved);
    }
  }

  Future<void> _deleteModul(ModulAjar modul, {bool ask = true}) async {
    if (ask) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Hapus modul?',
        message:
            '"${modul.judul}" akan dihapus dari daftar. Kamu masih bisa mengurungkannya sesaat setelah ini.',
        confirmLabel: 'Hapus',
      );
      if (!confirmed || !mounted) return;
    }

    final removed = await AppScope.read(context).hapusModul(modul.id);
    if (!mounted || removed == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${removed.judul}" dihapus.'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () {
              AppScope.read(context).pulihkanModul(removed);
            },
          ),
        ),
      );
  }

  Future<void> _duplicateModul(ModulAjar modul) async {
    final copy = await AppScope.read(context).duplikatModul(modul.id);
    if (!mounted || copy == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Salinan "${modul.judul}" dibuat.'),
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () => _openDetail(copy),
          ),
        ),
      );
  }

  void _handleAction(ModulAjar modul, ModulCardAction action) {
    switch (action) {
      case ModulCardAction.favorit:
        _toggleFavorit(modul);
      case ModulCardAction.edit:
        _openForm(modul: modul);
      case ModulCardAction.duplikat:
        _duplicateModul(modul);
      case ModulCardAction.hapus:
        _deleteModul(modul);
    }
  }

  Future<void> _toggleFavorit(ModulAjar modul) async {
    final controller = AppScope.read(context);
    final wasFavorite = modul.favorit;
    final berhasil = await controller.toggleFavorit(modul.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            !berhasil
                ? (controller.storageError ??
                      'Status favorit gagal disimpan ke server.')
                : wasFavorite
                ? 'Modul dihapus dari favorit.'
                : 'Modul ditambahkan ke favorit.',
          ),
        ),
      );
  }

  Future<void> _openFilterSheet() async {
    final controller = AppScope.read(context);
    final mapelOptions = controller.daftarMapel.isEmpty
        ? ModulOptions.mapel
        : controller.daftarMapel;
    var selectedMapel = _mapel;
    var selectedKelas = _kelas;

    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter modul',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Mata pelajaran', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mapelOptions.map((mapel) {
                      return ChoiceChip(
                        label: Text(mapel),
                        selected: selectedMapel == mapel,
                        onSelected: (selected) {
                          setSheetState(() {
                            selectedMapel = selected ? mapel : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Kelas', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ModulOptions.kelas.map((kelas) {
                      return ChoiceChip(
                        label: Text('Kelas $kelas'),
                        selected: selectedKelas == kelas,
                        onSelected: (selected) {
                          setSheetState(() {
                            selectedKelas = selected ? kelas : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              selectedMapel = null;
                              selectedKelas = null;
                            });
                          },
                          child: const Text('Atur ulang'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(
                            _FilterResult(
                              mapel: selectedMapel,
                              kelas: selectedKelas,
                            ),
                          ),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() {
      _mapel = result.mapel;
      _kelas = result.kelas;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final results = controller.filterModul(
      query: _searchController.text,
      filter: _filter,
      mapel: _mapel,
      kelas: _kelas,
      sort: _sort,
    );
    final filterCount = (_mapel != null ? 1 : 0) + (_kelas != null ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modul Ajar'),
            Text(
              '${controller.totalModul} modul · ${controller.totalTerbit} terbit',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<ModulSort>(
            tooltip: 'Urutkan modul',
            icon: const Icon(Icons.swap_vert_rounded),
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => ModulSort.values.map((sort) {
              final selected = sort == _sort;
              return PopupMenuItem(
                value: sort,
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(sort.label),
                  ],
                ),
              );
            }).toList(),
          ),
          Badge.count(
            count: filterCount,
            isLabelVisible: filterCount > 0,
            child: IconButton(
              tooltip: 'Filter modul',
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('fab-tambah-modul'),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Modul Baru'),
      ),
      body: Column(
        children: [
          PageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                TextField(
                  key: const ValueKey('cari-modul'),
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari modul atau materi...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ModulFilter.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = ModulFilter.values[index];
                      final selected = _filter == filter;
                      return ChoiceChip(
                        label: Text(filter.label),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = filter),
                      );
                    },
                  ),
                ),
                if (_mapel != null || _kelas != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_mapel != null)
                        InputChip(
                          label: Text(_mapel!),
                          onDeleted: () => setState(() => _mapel = null),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (_kelas != null)
                        InputChip(
                          label: Text('Kelas $_kelas'),
                          onDeleted: () => setState(() => _kelas = null),
                          deleteIcon: const Icon(Icons.close_rounded, size: 16),
                          visualDensity: VisualDensity.compact,
                        ),
                      TextButton(
                        onPressed: () => setState(() {
                          _mapel = null;
                          _kelas = null;
                        }),
                        child: const Text('Bersihkan filter'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${results.length} modul ditemukan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        _sort.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: results.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          EmptyState(
                            icon: _hasFilter
                                ? Icons.filter_alt_off_rounded
                                : Icons.auto_stories_outlined,
                            title:
                                _hasFilter || _searchController.text.isNotEmpty
                                ? 'Tidak ada modul yang cocok'
                                : 'Belum ada modul ajar',
                            message:
                                _hasFilter || _searchController.text.isNotEmpty
                                ? 'Coba ubah kata kunci atau bersihkan filter yang aktif.'
                                : 'Mulai susun modul ajar pertamamu untuk kelas yang kamu ampu.',
                            actionLabel:
                                _hasFilter || _searchController.text.isNotEmpty
                                ? 'Bersihkan pencarian'
                                : 'Buat Modul Pertama',
                            onAction:
                                _hasFilter || _searchController.text.isNotEmpty
                                ? () => setState(() {
                                    _searchController.clear();
                                    _filter = ModulFilter.semua;
                                    _mapel = null;
                                    _kelas = null;
                                  })
                                : () => _openForm(),
                            compact: true,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final modul = results[index];
                          return Dismissible(
                            key: ValueKey('dismiss-${modul.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              return showConfirmDialog(
                                context,
                                title: 'Hapus modul?',
                                message:
                                    '"${modul.judul}" akan dihapus dari daftar.',
                                confirmLabel: 'Hapus',
                              );
                            },
                            onDismissed: (_) => _deleteModul(modul, ask: false),
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.only(right: 20),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            child: ModulCard(
                              key: ValueKey('modul-card-${modul.id}'),
                              modul: modul,
                              margin: const EdgeInsets.only(bottom: 10),
                              onTap: () => _openDetail(modul),
                              onAction: (action) =>
                                  _handleAction(modul, action),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterResult {
  const _FilterResult({this.mapel, this.kelas});

  final String? mapel;
  final String? kelas;
}
