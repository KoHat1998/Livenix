import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/live_registry.dart';
import '../../data/models/live_room.dart';
import '../../theme/theme.dart';
import '../../widgets/live_badge.dart';

class LivesListScreen extends StatefulWidget {
  const LivesListScreen({super.key});

  @override
  State<LivesListScreen> createState() => _LivesListScreenState();
}

class _LivesListScreenState extends State<LivesListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Streams')),
      body: Column(
        children: [
          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Search by title or Room ID',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          // live list
          Expanded(
            child: ValueListenableBuilder<List<LiveRoom>>(
              valueListenable: LiveRegistry.instance.lives,
              builder: (context, rooms, _) {
                // only rooms that are live, and match search
                final filtered = rooms.where((r) {
                  if (!(r.isLive ?? true)) return false;
                  if (_query.isEmpty) return true;
                  final t = (r.title ?? '').toLowerCase();
                  return t.contains(_query) || (r.id ?? '').toLowerCase().contains(_query);
                }).toList()
                  ..sort((a, b) => (b.viewersCount ?? 0).compareTo(a.viewersCount ?? 0));

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No live streams right now'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final room = filtered[i];
                    return _LiveCard(room: room);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final LiveRoom room;
  const _LiveCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/lives/${room.id}', extra: room),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // thumbnail area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(decoration: BoxDecoration(gradient: AppTheme.primaryGradient)),
                    ),
                    Positioned(left: 12, top: 12, child: LiveBadge(isLive: room.isLive ?? true)),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_red_eye_outlined, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              '${room.viewersCount ?? 0}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // meta + button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.title ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(room.hostName ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/lives/${room.id}', extra: room),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch Now'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(10, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
