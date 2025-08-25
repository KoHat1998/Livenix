import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../../core/agora_config.dart';
import '../../services/agora_service.dart';
import '../../data/models/live_room.dart';
import '../../data/models/message.dart';
import '../../theme/theme.dart';
import '../../widgets/live_badge.dart';
import '../../widgets/control_tile.dart';
import '../../widgets/chat_composer.dart';

class BroadcasterDashboardScreen extends StatefulWidget {
  final LiveRoom? room;
  const BroadcasterDashboardScreen({super.key, this.room});

  @override
  State<BroadcasterDashboardScreen> createState() =>
      _BroadcasterDashboardScreenState();
}

class _BroadcasterDashboardScreenState
    extends State<BroadcasterDashboardScreen> {
  final AgoraService _agora = AgoraService.instance;

  bool isLive = false;
  bool micOn = true;
  bool camOn = true;

  // simple in-memory chat for demo
  late List<Message> messages;

  @override
  void initState() {
    super.initState();
    messages = List.generate(
      12,
          (i) => Message(
        id: '$i',
        from: i % 4 == 0 ? 'Moderator' : 'Viewer $i',
        text: i % 4 == 0 ? 'Welcome to the stream 🎉' : 'Nice stream! #$i',
        ts: DateTime.now().subtract(Duration(minutes: 12 - i)),
        isHost: i % 4 == 0,
      ),
    );
  }

  @override
  void dispose() {
    // make sure we leave the channel if user navigates away while live
    if (isLive) {
      _agora.leave();
    }
    super.dispose();
  }

  Future<void> _goLiveToggle() async {
    if (!isLive) {
      // Request permissions first
      final statuses =
      await [Permission.camera, Permission.microphone].request();
      final camOk = statuses[Permission.camera]?.isGranted ?? false;
      final micOk = statuses[Permission.microphone]?.isGranted ?? false;
      if (!camOk || !micOk) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera/Mic permission required')),
          );
        }
        return;
      }

      final channel = widget.room?.id ?? defaultTestChannel;
      await _agora.joinAsBroadcaster(
        channelId: channel,
        token: agoraTempToken, // empty is OK if your Agora project has no cert
      );
      setState(() => isLive = true);

      // apply current UI toggles to engine
      await _agora.setMicOn(micOn);
      await _agora.setCameraOn(camOn);
    } else {
      await _agora.leave();
      setState(() => isLive = false);
    }
  }

  void _openChatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return _ChatBottomSheet(
              roomTitle: widget.room?.title ?? 'Live Chat',
              scrollController: scrollController,
              messages: messages,
              onSend: (text) {
                messages.add(
                  Message(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    from: 'Host',
                    text: text,
                    ts: DateTime.now(),
                    isHost: true,
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) => setState(() {})); // refresh after closing
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcaster')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Live preview (Agora when live)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Show local camera when live, placeholder otherwise
                    Positioned.fill(
                      child: isLive
                          ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _agora.engine,
                          canvas: const VideoCanvas(uid: 0), // local preview
                        ),
                      )
                          : Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Center(
                          child: Icon(Icons.videocam_outlined, size: 64),
                        ),
                      ),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                // Mic
                ControlTile(
                  icon: micOn ? Icons.mic : Icons.mic_off,
                  label: micOn ? 'Mute Microphone' : 'Unmute Microphone',
                  onTap: () async {
                    setState(() => micOn = !micOn);
                    if (isLive) {
                      await _agora.setMicOn(micOn);
                    }
                  },
                ),
                // Camera
                ControlTile(
                  icon: camOn ? Icons.videocam : Icons.videocam_off,
                  label: camOn ? 'Turn Camera Off' : 'Turn Camera On',
                  onTap: () async {
                    setState(() => camOn = !camOn);
                    if (isLive) {
                      await _agora.setCameraOn(camOn);
                    }
                  },
                ),
                // Go Live / Stop
                ControlTile(
                  icon: isLive ? Icons.pause_circle : Icons.play_circle,
                  label: isLive ? 'Stop Live' : 'Go Live',
                  onTap: _goLiveToggle,
                  highlight: true,
                ),
                // Switch camera
                ControlTile(
                  icon: Icons.flip_camera_android_outlined,
                  label: 'Switch Camera',
                  onTap: () async {
                    if (!isLive) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Go live to switch camera')),
                      );
                      return;
                    }
                    await _agora.switchCamera();
                  },
                ),
                // Share
                ControlTile(
                  icon: Icons.share_outlined,
                  label: 'Share Stream Link',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share coming soon')),
                  ),
                ),
                // Chat
                ControlTile(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat Settings',
                  onTap: _openChatSheet,
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
              onPressed: () async {
                if (isLive) {
                  await _agora.leave();
                  setState(() => isLive = false);
                }
                context.pop(); // back to previous screen
              },
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End Stream'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliding chat bottom sheet
class _ChatBottomSheet extends StatefulWidget {
  final String roomTitle;
  final ScrollController scrollController;
  final List<Message> messages;
  final void Function(String text) onSend;

  const _ChatBottomSheet({
    required this.roomTitle,
    required this.scrollController,
    required this.messages,
    required this.onSend,
  });

  @override
  State<_ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<_ChatBottomSheet> {
  void _handleSend(String text) {
    widget.onSend(text);
    setState(() {}); // refresh list
    // scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // grab handle
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            // header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.forum_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.roomTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.surfaceVariant),

            // messages
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: widget.messages.length,
                itemBuilder: (context, i) {
                  final m = widget.messages[i];
                  final isHost = m.isHost;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                          isHost ? AppTheme.primary : AppTheme.surfaceVariant,
                          child: Text(
                            m.from.characters.first.toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isHost
                                  ? AppTheme.surfaceVariant
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.from,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isHost
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(m.text),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // composer
            ChatComposer(onSend: _handleSend),
          ],
        ),
      ),
    );
  }
}
