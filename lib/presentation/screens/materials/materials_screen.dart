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
      length: 5,
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
            'LEARNING MATERIALS',
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
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF065F2F),
            labelColor: Color(0xFF065F2F),
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Notes'),
              Tab(text: 'Videos'),
              Tab(text: 'Diagrams'),
              Tab(text: 'Road Signs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AllMaterialsView(materialsAsync: materialsAsync, hasPaid: hasPaid),
            _FilteredMaterialsView(type: 'notes', materialsAsync: materialsAsync, hasPaid: hasPaid),
            _FilteredMaterialsView(type: 'video', materialsAsync: materialsAsync, hasPaid: hasPaid),
            _FilteredMaterialsView(type: 'diagram', materialsAsync: materialsAsync, hasPaid: hasPaid),
            _FilteredMaterialsView(type: 'road_signs', materialsAsync: materialsAsync, hasPaid: hasPaid),
          ],
        ),
      ),
    );
  }
}

class _AllMaterialsView extends StatelessWidget {
  const _AllMaterialsView({required this.materialsAsync, required this.hasPaid});
  final AsyncValue<List<MaterialItem>> materialsAsync;
  final bool hasPaid;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _CategoryCard(
          icon: Icons.book,
          iconColor: Colors.green,
          title: 'Study Notes',
          subtitle: 'Comprehensive notes for all 19 units.',
          onTap: () => DefaultTabController.of(context).animateTo(1),
        ),
        _CategoryCard(
          icon: Icons.play_arrow,
          iconColor: Colors.red,
          title: 'Video Lessons',
          subtitle: 'Watch expert explanations on key topics.',
          onTap: () => DefaultTabController.of(context).animateTo(2),
        ),
        _CategoryCard(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.amber.shade700,
          title: 'Road Signs Guide',
          subtitle: 'Learn all road signs with images and meanings.',
          onTap: () => DefaultTabController.of(context).animateTo(4),
        ),
        _CategoryCard(
          icon: Icons.settings_outlined,
          iconColor: Colors.blue,
          title: 'Driving Basics',
          subtitle: 'Basics of driving, controls, and safety.',
          onTap: () {},
        ),
        _CategoryCard(
          icon: Icons.download_for_offline,
          iconColor: Colors.indigo,
          title: 'Downloads',
          subtitle: 'Download PDFs and resources to study offline.',
          onTap: () {},
        ),
      ],
    );
  }
}

class _FilteredMaterialsView extends StatelessWidget {
  const _FilteredMaterialsView({required this.type, required this.materialsAsync, required this.hasPaid});
  final String type;
  final AsyncValue<List<MaterialItem>> materialsAsync;
  final bool hasPaid;

  @override
  Widget build(BuildContext context) {
    return materialsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (materials) {
        final filtered = materials.where((m) => m.type.toLowerCase() == type.toLowerCase()).toList();
        if (filtered.isEmpty) {
          return Center(child: Text('No $type materials available.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _MaterialItemTile(item: filtered[index], hasPaid: hasPaid),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
            ],
          ),
        ),
      ),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        leading: Icon(
          item.type == 'video' ? Icons.play_circle_outline : Icons.description_outlined,
          color: AppColors.primary,
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(locked ? 'Locked' : item.type.toUpperCase()),
        trailing: Icon(locked ? Icons.lock_outline : Icons.open_in_new, size: 18),
        onTap: () async {
          if (locked) {
             context.push('/unlock');
             return;
          }
          final uri = Uri.parse(item.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
