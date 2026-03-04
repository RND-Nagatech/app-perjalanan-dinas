import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../bloc/history_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  int _toInt(dynamic v, [int fallback = 0]) {
    try {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) {
        final cleaned = v.replaceAll(RegExp(r'[^0-9\-]'), '');
        return int.tryParse(cleaned) ?? fallback;
      }
    } catch (_) {}
    return fallback;
  }

  String _formatCurrency(int value) {
    final s = value.abs().toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    final withDots = s.replaceAllMapped(reg, (m) => '.');
    return (value < 0 ? '-$withDots' : withDots);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I.get<HistoryBloc>()..add(LoadHistory()),
      child: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, hstate) {
          final sections = (hstate is HistoryLoadSuccess)
              ? hstate.items
              : <dynamic>[];
          final currentFilter = (hstate is HistoryLoadSuccess)
              ? hstate.filter
              : 'Semua';

          return Scaffold(
            backgroundColor: const Color(0xFFF6F8F8),
            body: SafeArea(
              child: Column(
                children: [
                  // header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0E7C7B), Color(0xFF0AA7A5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        const Text(
                          'Riwayat Perjalanan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _segmentButton(context, 'Semua', currentFilter),
                              const SizedBox(width: 8),
                              _segmentButton(
                                context,
                                'Berjalan',
                                currentFilter,
                              ),
                              const SizedBox(width: 8),
                              _segmentButton(context, 'Selesai', currentFilter),
                              const SizedBox(width: 8),
                              _segmentButton(context, 'Audit', currentFilter),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        onChanged: (v) =>
                            context.read<HistoryBloc>().add(ChangeQuery(v)),
                        decoration: InputDecoration(
                          hintText: 'Cari perjalanan...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: sections.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/png/empty.png',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Menampilkan semua riwayat perjalanan dinas Anda.',
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: sections.length,
                            itemBuilder: (context, si) {
                              final section = sections[si];
                              final List items = section.items;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Column(
                                    children: List.generate(items.length, (i) {
                                      final d = items[i];
                                      final name =
                                          (d as dynamic).name as String? ?? '-';
                                      final destination =
                                          (d as dynamic).destination
                                              as String? ??
                                          '-';
                                      final operational =
                                          (d as dynamic).operational;
                                      final opInt = _toInt(operational, 0);
                                      final formattedOp = _formatCurrency(
                                        opInt,
                                      );
                                      final DateTime? fromTs =
                                          (d as dynamic).dateFrom as DateTime?;
                                      final dateFrom = fromTs == null
                                          ? '-'
                                          : fromTs
                                                .toLocal()
                                                .toString()
                                                .split(' ')
                                                .first;
                                      final status =
                                          (d as dynamic).status as String? ??
                                          '';

                                      return Padding(
                                        padding: EdgeInsets.only(
                                          bottom: i == items.length - 1
                                              ? 0
                                              : 12,
                                        ),
                                        child: GestureDetector(
                                          onTap: () =>
                                              context.push('/trip', extra: d),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color.fromRGBO(
                                                    0,
                                                    0,
                                                    0,
                                                    0.04,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 52,
                                                  height: 52,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFEFF9F8,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.flight,
                                                    color: Color(0xFF0E7C7B),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              name,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  status
                                                                      .toLowerCase()
                                                                      .contains(
                                                                        'berjalan',
                                                                      )
                                                                  ? const Color(
                                                                      0xFFE8FFF8,
                                                                    )
                                                                  : const Color(
                                                                      0xFFF2F4F5,
                                                                    ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              status
                                                                  .toUpperCase(),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        '$dateFrom • $destination',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Rp $formattedOp',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _segmentButton(
    BuildContext context,
    String label,
    String currentFilter,
  ) {
    final active = currentFilter == label;
    return GestureDetector(
      onTap: () => context.read<HistoryBloc>().add(ChangeFilter(label)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Colors.white
              : const Color.fromRGBO(255, 255, 255, 0.12),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF0E7C7B) : Colors.white,
          ),
        ),
      ),
    );
  }
}
