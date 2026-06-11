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
import '../home/home_shell.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);
    final hasPaid = ref.watch(hasPaidProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              badge: 'Materials',
              title: 'Learning Materials',
              subtitle: hasPaid
                  ? 'Tap any item to open.'
                  : 'Free items are open to all — paid items unlock with full access.',
            ),
          ),
          materialsAsync.when(
            loading: () => const SliverFillRemaining(child: LoadingView()),
            error: (e, _) => SliverFillRemaining(
              child: ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(materialsProvider),
              ),
            ),
            data: (materials) {
              if (materials.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No materials uploaded yet.')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _MaterialCard(
                      item: materials[index],
                      hasPaid: hasPaid,
                      onOpen: () => _openMaterial(context, materials[index], hasPaid),
                    ),
                    childCount: materials.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openMaterial(
    BuildContext context,
    MaterialItem item,
    bool hasPaid,
  ) async {
    if (!item.isAccessible(hasPaid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlock full access to open this material.')),
      );
      context.push('/unlock');
      return;
    }
    final uri = Uri.parse(item.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.item,
    required this.hasPaid,
    required this.onOpen,
  });

  final MaterialItem item;
  final bool hasPaid;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final locked = !item.isAccessible(hasPaid);
    final isVideo = item.type == 'video';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(
                  locked
                      ? Icons.lock_outline
                      : isVideo
                          ? Icons.play_circle_outline
                          : Icons.description_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (item.unitNumber != null)
                      Text(
                        'Unit ${item.unitNumber}${item.unitTitle != null ? ' — ${item.unitTitle}' : ''}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    Text(
                      locked ? 'Locked' : item.type.toUpperCase(),
                      style: TextStyle(
                        color: locked ? Colors.orange : AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
