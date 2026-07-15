import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/unit.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({super.key});

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(testAttemptsProvider);
    await ref.read(unitsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(unitsProvider);
    final attemptsAsync = ref.watch(testAttemptsProvider);
    final hasPaid = ref.watch(hasPaidProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search units...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                )
              : const Text(
                  'TESTS',
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
              icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
          ],
        ),
        body: unitsAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: _onRefresh,
          ),
          data: (units) {
            return attemptsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: _onRefresh,
              ),
              data: (attempts) {
                // ── 1. Calculate LATEST score for each unit ──────────────────
                final latestScoresMap = <String, double>{};
                final sortedAttempts = [...attempts]
                  ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
                
                for (final a in sortedAttempts) {
                  if (!latestScoresMap.containsKey(a.unitId)) {
                    latestScoresMap[a.unitId] = a.total == 0 ? 0.0 : a.score / a.total;
                  }
                }

                // ── 2. Calculate overall progress based on latest scores ──────────
                final sum = latestScoresMap.values.fold(0.0, (a, b) => a + b);
                final overallProgress = units.isEmpty ? 0.0 : sum / units.length;
                final overallPct = (overallProgress * 100).round();

                // ── 3. Filtering and Sorting logic ──────────────────────────────
                final filteredUnits = units.where((u) {
                  if (_searchQuery.isEmpty) return true;
                  return u.title.toLowerCase().contains(_searchQuery) ||
                         u.unitNumber.toString().contains(_searchQuery);
                }).toList();

                // Sort explicitly by unitNumber ascending (1 to 16)
                filteredUnits.sort((a, b) => a.unitNumber.compareTo(b.unitNumber));

                final freeUnits = filteredUnits.where((u) => u.isFreePreview).toList();
                final allUnits = filteredUnits;

                return Column(
                  children: [
                    // Top Course Progress Banner
                    if (!_isSearching)
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
                                child: const Icon(Icons.description, color: Colors.white, size: 30),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Course Progress',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${units.length} Units • Learning Progress',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: 48,
                                    width: 48,
                                    child: CircularProgressIndicator(
                                      value: overallProgress,
                                      strokeWidth: 4,
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '$overallPct%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
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
                        Tab(text: 'Free Units'),
                        Tab(text: 'All Units'),
                      ],
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Free Units
                          RefreshIndicator(
                            onRefresh: _onRefresh,
                            child: freeUnits.isEmpty
                                ? ListView(
                                    children: [
                                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                      Center(child: Text(_searchQuery.isEmpty ? 'No free units available' : 'No results found')),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: freeUnits.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final unit = freeUnits[index];
                                      return _UnitListItem(
                                        unit: unit,
                                        hasPaid: hasPaid,
                                        progress: latestScoresMap[unit.id],
                                        onTap: () => context.go('/tests/${unit.id}'),
                                      );
                                    },
                                  ),
                          ),

                          // Tab 2: All Units
                          RefreshIndicator(
                            onRefresh: _onRefresh,
                            child: allUnits.isEmpty
                                ? ListView(
                                    children: [
                                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                      const Center(child: Text('No results found')),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    itemCount: allUnits.length + (hasPaid || _searchQuery.isNotEmpty ? 0 : 1),
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      if (index == allUnits.length && !hasPaid && _searchQuery.isEmpty) {
                                        return _UnlockBanner(
                                          unitCount: units.length,
                                          onTap: () => context.push(
                                            '/unlock?from=${Uri.encodeComponent('/tests')}',
                                          ),
                                        );
                                      }
                                      if (index >= allUnits.length) return const SizedBox.shrink();

                                      final unit = allUnits[index];
                                      return _UnitListItem(
                                        unit: unit,
                                        hasPaid: hasPaid,
                                        progress: latestScoresMap[unit.id],
                                        onTap: () {
                                          final target = '/tests/${unit.id}';
                                          if (!unit.isAccessible(hasPaid)) {
                                            context.push('/unlock?from=${Uri.encodeComponent(target)}');
                                            return;
                                          }
                                          context.go(target);
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UnitListItem extends StatelessWidget {
  const _UnitListItem({
    required this.unit,
    required this.hasPaid,
    required this.onTap,
    this.progress,
  });

  final Unit unit;
  final bool hasPaid;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final locked = !unit.isAccessible(hasPaid);
    
    // Color logic: Green for pass (70%+), Orange for mid, Red for fail (<50%)
    final Color scoreColor = progress == null 
        ? const Color(0xFF059669) 
        : progress! >= 0.7 
            ? const Color(0xFF059669) 
            : (progress! >= 0.5 ? Colors.orange : Colors.redAccent);

    return InkWell(
      onTap: onTap,
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
            // Number Box
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: locked ? const Color(0xFF94A3B8) : const Color(0xFF065F2F),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${unit.unitNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: locked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locked ? 'Unlock to access' : 'Practice Quiz',
                    style: TextStyle(
                      color: locked ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20)
            else if (progress != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress! * 100).round()}%',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (progress == 1.0)
                    Icon(Icons.check_circle_outline, color: scoreColor, size: 20)
                  else
                    SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                ],
              )
            else
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _UnlockBanner extends StatelessWidget {
  const _UnlockBanner({required this.onTap, required this.unitCount});
  final VoidCallback onTap;
  final int unitCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Unlock all $unitCount units and tests',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF065F2F)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Master the NTSA theory test today.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Unlock Full Access'),
          ),
        ],
      ),
    );
  }
}
