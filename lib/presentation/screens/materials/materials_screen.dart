import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/material_item.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);
    final hasPaid = ref.watch(hasPaidProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'LIBRARY',
            style: TextStyle(
              color: Color(0xFF065F2F),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.1,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Top Green Banner (Matching UnitsScreen)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF065F2F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.menu_book, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Learning Content',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          materialsAsync.when(
                            data: (materials) {
                              final docs = materials.where((m) => m.type != 'video').length;
                              final vids = materials.where((m) => m.type == 'video').length;
                              return Text(
                                '$docs Documents • $vids Videos',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              );
                            },
                            loading: () => const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.auto_awesome, color: Colors.white70, size: 24),
                  ],
                ),
              ),
            ),

            // Tab Bar
            const TabBar(
              indicatorColor: Color(0xFF065F2F),
              labelColor: Color(0xFF065F2F),
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(text: 'Documents'),
                Tab(text: 'Videos'),
              ],
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            Expanded(
              child: TabBarView(
                children: [
                  _FilteredMaterialsView(
                    types: const ['notes', 'diagram', 'road_signs'],
                    materialsAsync: materialsAsync,
                    hasPaid: hasPaid,
                  ),
                  _FilteredMaterialsView(
                    types: const ['video'],
                    materialsAsync: materialsAsync,
                    hasPaid: hasPaid,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilteredMaterialsView extends StatelessWidget {
  const _FilteredMaterialsView({
    required this.types,
    required this.materialsAsync,
    required this.hasPaid,
  });

  final List<String> types;
  final AsyncValue<List<MaterialItem>> materialsAsync;
  final bool hasPaid;

  @override
  Widget build(BuildContext context) {
    return materialsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => materialsAsync, // Riverpod handles state, ideally we would invalidate provider
      ),
      data: (materials) {
        final filtered = materials
            .where((m) => types.contains(m.type.toLowerCase()))
            .toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No materials available in this category.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _MaterialItemTile(
            item: filtered[index],
            hasPaid: hasPaid,
          ),
        );
      },
    );
  }
}

class _MaterialItemTile extends StatelessWidget {
  const _MaterialItemTile({required this.item, required this.hasPaid});
  final MaterialItem item;
  final bool hasPaid;

  @override
  Widget build(BuildContext context) {
    final locked = !item.isAccessible(hasPaid);
    final isVideo = item.type.toLowerCase() == 'video';

    return InkWell(
      onTap: () async {
        if (locked) {
          context.push('/unlock?from=${Uri.encodeComponent('/materials')}');
          return;
        }
        final uri = Uri.parse(item.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            // Icon Box (Matching UnitsScreen number box style)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF065F2F),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                isVideo ? Icons.play_arrow : Icons.description,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVideo ? 'Video Lesson' : '${item.type.replaceAll('_', ' ').toUpperCase()} Document',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Status Icon
            Icon(
              locked ? Icons.lock_outline : Icons.chevron_right,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
