import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/models/modul_ajar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/modul_card.dart';
import '../../widgets/page_width.dart';
import '../../widgets/section_header.dart';
import '../modul/modul_detail_screen.dart';

class ModulSearchScreen extends StatefulWidget {
  const ModulSearchScreen({super.key});

  @override
  State<ModulSearchScreen> createState() => _ModulSearchScreenState();
}

class _ModulSearchScreenState extends State<ModulSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(ModulAjar modul) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModulDetailScreen(modulId: modul.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final query = _searchController.text;
    final results = controller.filterModul(query: query);
    final favorites = controller.modulTerbaru.where((m) => m.favorit).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Modul')),
      body: PageWidth(
        maxWidth: 820,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari judul, mata pelajaran, atau materi...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
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
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (query.trim().isEmpty) ...[
                      if (favorites.isNotEmpty) ...[
                        SectionHeader(
                          title: 'Favorit kamu',
                          subtitle:
                              '${favorites.length} modul ditandai favorit',
                        ),
                        const SizedBox(height: 10),
                        ...favorites
                            .take(3)
                            .map(
                              (modul) => ModulCard(
                                modul: modul,
                                margin: const EdgeInsets.only(bottom: 10),
                                showMenu: false,
                                onTap: () => _openDetail(modul),
                              ),
                            ),
                        const SizedBox(height: 16),
                      ],
                      SectionHeader(
                        title: 'Terbaru diperbarui',
                        subtitle: '${controller.totalModul} modul tersimpan',
                      ),
                      const SizedBox(height: 10),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${results.length} hasil untuk "${query.trim()}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (results.isEmpty)
                      EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Tidak ada hasil',
                        message: 'Coba kata kunci lain, misalnya nama mata pelajaran atau materi pokok.',
                        actionLabel: query.isEmpty
                            ? null
                            : 'Bersihkan pencarian',
                        onAction: query.isEmpty
                            ? null
                            : () {
                                _searchController.clear();
                                setState(() {});
                              },
                      )
                    else
                      ...results.map(
                        (modul) => ModulCard(
                          modul: modul,
                          margin: const EdgeInsets.only(bottom: 10),
                          showMenu: false,
                          onTap: () => _openDetail(modul),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
