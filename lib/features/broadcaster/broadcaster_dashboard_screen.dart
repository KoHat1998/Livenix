import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:livenix/features/home/home_screen.dart';
import '../../data/models/live_room.dart';
import '../../theme/theme.dart';
import '../../widgets/live_badge.dart';
import '../../widgets/control_tile.dart';

class BroadcasterDashboardScreen extends StatefulWidget {
  final LiveRoom? room;
  const BroadcasterDashboardScreen({super.key, this.room});

  @override
  State<BroadcasterDashboardScreen> createState() =>
      _BroadcasterDashboardScreenState();
}

class _BroadcasterDashboardScreenState
    extends State<BroadcasterDashboardScreen> {
  bool isLive = false;
  bool micOn = true;
  bool camOn = true;

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcaster')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Hero preview card
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: AppTheme.primaryGradient,
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.videocam_outlined, size: 64),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: LiveBadge(isLive: isLive),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          room != null ? 'Room: ${room.id}' : 'Room: -',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              room?.title ?? 'My Live',
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              'by ${room?.hostName ?? 'Broadcaster'}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Controls grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                ControlTile(
                  icon: micOn ? Icons.mic : Icons.mic_off,
                  label: micOn ? 'Mute Microphone' : 'Unmute Microphone',
                  onTap: () => setState(() => micOn = !micOn),
                ),
                ControlTile(
                  icon: camOn ? Icons.videocam : Icons.videocam_off,
                  label: camOn ? 'Turn Camera Off' : 'Turn Camera On',
                  onTap: () => setState(() => camOn = !camOn),
                ),
                ControlTile(
                  icon: isLive ? Icons.pause_circle : Icons.play_circle,
                  label: isLive ? 'Pause Stream' : 'Go Live',
                  onTap: () => setState(() => isLive = !isLive),
                  highlight: true,
                ),
                ControlTile(
                  icon: Icons.share_outlined,
                  label: 'Share Stream Link',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share coming soon')),
                    );
                  },
                ),
                ControlTile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat Settings',
                  onTap: () {},
                ),
                ControlTile(
                  icon: Icons.settings_outlined,
                  label: 'Advanced Settings',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // End Stream
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End Stream'),
            ),
          ],
        ),
      ),
    );
  }
}
