import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  late Future<List<LiveRoom>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchLives();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<LiveRoom>> _fetchLives() async {
    final rows = await Supabase.instance.client
        .from('live_rooms')
        .select()
        .eq('status', 'live')
        .order('started_at', ascending: false);

    final list = (rows as List)
        .map((e) => LiveRoom.fromMap(e as Map<String, dynamic>))
        .toList();
    return list;
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetchLives());
    await _future;
  }

  Future<void> _joinByRoomId() async {
    final ctrl = TextEditingController();
    final id = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join by Room ID'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Enter room id (e.g. 123456)',
            ),
            onSubmitted: (_) => Navigator.of(context).pop(ctrl.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );

    if (id == null || id.isEmpty) return;

    // Navigate with a minimal placeholder model (works for viewer)
    if (!mounted) return;
    context.push(
      '/lives/$id',
      extra: LiveRoom(
        id: id,
        title: 'Live: $id',
        hostName: '—',
        viewersCount: 0,
        isLive: true,
        status: 'live',
        hostUserId: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Streams')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _joinByRoomId,
        icon: const Icon(Icons.link),
        label: const Text('Join by Room ID'),
      ),
      body: Column(
        children: [
          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by title or Room ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  tooltip: 'Clear',
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),

          // live list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<LiveRoom>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final rooms = snapshot.data ?? [];

                  final filtered = rooms.where((r) {
                    if (!r.isLive) return false;
                    if (_query.isEmpty) return true;
                    final t = r.title.toLowerCase();
                    final id = r.id.toLowerCase();
                    final host = r.hostName.toLowerCase();
                    return t.contains(_query) || id.contains(_query) || host.contains(_query);
                  }).toList()
                    ..sort((a, b) => b.viewersCount.compareTo(a.viewersCount));

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No live streams right now'));
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _LiveCard(room: filtered[i]),
                  );
                },
              ),
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
                      child: Container(
                        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                      ),
                    ),
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: LiveBadge(isLive: true),
                    ),
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
                              '${room.viewersCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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
                        Text(
                          room.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.hostName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
