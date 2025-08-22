import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/live_room.dart';
import '../../theme/theme.dart';
import '../../widgets/live_badge.dart';

class LivesListScreen extends StatefulWidget {
  const LivesListScreen({super.key});

  @override
  State<LivesListScreen> createState() => _LivesListScreenState();
}

class _LivesListScreenState extends State<LivesListScreen> {
  final searchCtrl = TextEditingController();
  late List<LiveRoom> all;
  late List<LiveRoom> filtered;

  @override
  void initState() {
    super.initState();
    all = _dummyRooms();
    filtered = List.from(all);
    searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = searchCtrl.text.toLowerCase().trim();
    setState(() {
      filtered = all.where((r) {
        return r.title.toLowerCase().contains(q) ||
            r.hostName.toLowerCase().contains(q) ||
            r.id.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore Lives')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search by title, host, or room ID…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final room = filtered[i];
                  return _LiveCard(
                    room: room,
                    onWatch: () => context.push('/lives/${room.id}', extra: room),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LiveRoom> _dummyRooms() {
    final rnd = Random();
    return List.generate(8, (i) {
      final id = (100000 + rnd.nextInt(899999)).toString();
      return LiveRoom(
        id: id,
        title: 'Kohat Live #$i',
        hostName: 'Host $i',
        viewersCount: 5 + rnd.nextInt(200),
        isLive: true,
      );
    });
  }
}

class _LiveCard extends StatelessWidget {
  final LiveRoom room;
  final VoidCallback onWatch;

  const _LiveCard({required this.room, required this.onWatch});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onWatch,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Thumbnail placeholder
              Container(
                width: 120,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: AppTheme.primaryGradient,
                ),
                child: const Icon(Icons.play_circle_outline, size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        LiveBadge(isLive: room.isLive),
                        const SizedBox(width: 8),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('${room.viewersCount}',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(room.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('by ${room.hostName}',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: onWatch,
                        icon: const Icon(Icons.live_tv_outlined),
                        label: const Text('Watch Now'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.surfaceVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
