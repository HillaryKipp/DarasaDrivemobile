import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/material_item.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class MaterialsScreen extends ConsumerWidget {
  const MaterialsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);
    final hasPaid = ref.watch(hasPaidProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
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
            // Top Green Banner
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
              child: materialsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(message: e.toString(), onRetry: () {}),
                data: (materials) => TabBarView(
                  children: [
                    _MaterialsList(
                      items: materials.where((m) => m.type.toLowerCase() != 'video').toList(),
                      hasPaid: hasPaid,
                    ),
                    _MaterialsList(
                      items: materials.where((m) => m.type.toLowerCase() == 'video').toList(),
                      hasPaid: hasPaid,
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

// ── List ──────────────────────────────────────────────────────────────────────

class _MaterialsList extends StatelessWidget {
  const _MaterialsList({required this.items, required this.hasPaid});

  final List<MaterialItem> items;
  final bool hasPaid;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No materials available in this category.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _MaterialTile(item: items[index], hasPaid: hasPaid),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.item, required this.hasPaid});

  final MaterialItem item;
  final bool hasPaid;

  bool get _isVideo => item.type.toLowerCase() == 'video';
  bool get _locked => !item.isAccessible(hasPaid);

  void _onTap(BuildContext context) {
    if (_locked) {
      context.push('/unlock?from=${Uri.encodeComponent('/materials')}');
      return;
    }
    if (_isVideo) {
      final videoId = YoutubePlayerController.convertUrlToId(item.url);
      if (videoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load video.')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _YoutubeViewerScreen(title: item.title, videoId: videoId),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PdfViewerScreen(title: item.title, url: item.url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _locked
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF065F2F),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                _isVideo ? Icons.play_arrow : Icons.picture_as_pdf,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: _locked
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF1E293B),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _locked
                        ? 'Sign in to access'
                        : (_isVideo ? 'Video Lesson' : 'PDF Document'),
                    style: TextStyle(
                      color: _locked
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _locked ? Icons.lock_outline : Icons.chevron_right,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── PDF Viewer ────────────────────────────────────────────────────────────────

class _PdfViewerScreen extends StatefulWidget {
  const _PdfViewerScreen({required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<_PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<_PdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF065F2F),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_currentPage / $_totalPages',
                  style: const TextStyle(
                    color: Color(0xFF065F2F),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SfPdfViewer.network(
        widget.url,
        controller: _pdfController,
        onDocumentLoaded: (details) {
          setState(() => _totalPages = details.document.pages.count);
        },
        onPageChanged: (details) {
          setState(() => _currentPage = details.newPageNumber);
        },
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load PDF: ${details.description}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }
}

// ── YouTube Viewer ────────────────────────────────────────────────────────────

class _YoutubeViewerScreen extends StatefulWidget {
  const _YoutubeViewerScreen({required this.title, required this.videoId});

  final String title;
  final String videoId;

  @override
  State<_YoutubeViewerScreen> createState() => _YoutubeViewerScreenState();
}

class _YoutubeViewerScreenState extends State<_YoutubeViewerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF065F2F),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoutubePlayer(
            controller: _controller,
            aspectRatio: 16 / 9,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Video Lesson',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
