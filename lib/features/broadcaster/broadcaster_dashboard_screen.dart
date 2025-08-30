import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../services/media_service.dart';
import '../../services/live_service.dart';
import '../../services/signal_service.dart';
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
  final _media = MediaService.instance;
  final _live = LiveService.instance;
  final _signal = SignalService.instance;

  bool isLive = false;
  bool micOn = true;
  bool camOn = true;

  Map<String, dynamic>? _routerRtpCapabilities;

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
    _stopLive();
    super.dispose();
  }

  Future<void> _stopLive() async {
    try {
      await _media.leave();
    } catch (_) {}
    try {
      final id = widget.room?.id;
      if (id != null) await _live.endLive(id);
    } catch (_) {}
    try {
      _signal.disconnect();
    } catch (_) {}
    if (mounted) setState(() => isLive = false);
  }

  Future<void> _goLiveToggle() async {
    if (!isLive) {
      // 1) Permissions
      final statuses =
      await [Permission.camera, Permission.microphone].request();
      final camOk = statuses[Permission.camera]?.isGranted ?? false;
      final micOk = statuses[Permission.microphone]?.isGranted ?? false;
      if (!camOk || !micOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera/Mic permission required')),
        );
        return;
      }

      // 2) Auth
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be signed in to go live.')),
        );
        return;
      }

      try {
        // 3) Local preview
        await _media.joinAsBroadcaster();

        // 4) Connect signaling & join role
        await _signal.connect();
        await _signal.joinAsBroadcaster();

        // Optional logs
        _signal.onBroadcasterStarted((_) => debugPrint('[Broadcaster] started'));
        _signal.onBroadcasterLeft((_) => debugPrint('[Broadcaster] left'));

        // 5) Fetch router RTP caps (we’ll use these when adding Mediasoup client)
        _routerRtpCapabilities = await _signal.getRouterRtpCapabilities();
        debugPrint('[Broadcaster] Router caps: $_routerRtpCapabilities');

        // 6) Publish room metadata to DB so viewers see the card
        final liveRoom = LiveRoom(
          id: widget.room?.id ?? 'test-room',
          title: widget.room?.title ?? 'My Live',
          hostName: widget.room?.hostName ?? 'Broadcaster',
          viewersCount: 0,
          isLive: true,
          status: 'live',
          hostUserId: userId,
          thumbnailUrl: null,
          startedAt: DateTime.now(),
        );
        await _live.startLive(liveRoom);

        if (!mounted) return;
        setState(() => isLive = true);

        // 7) Apply mic/cam toggles
        await _media.setMicOn(micOn);
        await _media.setCameraOn(camOn);

        // NOTE: Producing to mediasoup requires a client library that Flutter lacks.
        // When we add a flutter-compatible mediasoup client, we’ll:
        //   - create a SEND transport,
        //   - connect it,
        //   - produce audio/video using local tracks from MediaService.
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to go live: $e')),
        );
      }
    } else {
      await _stopLive();
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
    ).then((_) {
      if (mounted) setState(() {});
    });
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
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: isLive
                          ? RTCVideoView(
                        _media.localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit
                            .RTCVideoViewObjectFitCover,
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
                        padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  onTap: () async {
                    setState(() => micOn = !micOn);
                    if (isLive) await _media.setMicOn(micOn);
                  },
                ),
                ControlTile(
                  icon: camOn ? Icons.videocam : Icons.videocam_off,
                  label: camOn ? 'Turn Camera Off' : 'Turn Camera On',
                  onTap: () async {
                    setState(() => camOn = !camOn);
                    if (isLive) await _media.setCameraOn(camOn);
                  },
                ),
                ControlTile(
                  icon: isLive ? Icons.pause_circle : Icons.play_circle,
                  label: isLive ? 'Stop Live' : 'Go Live',
                  onTap: _goLiveToggle,
                  highlight: true,
                ),
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
                    await _media.switchCamera();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                if (isLive) await _stopLive();
                if (mounted) context.pop();
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

/// Chat bottom sheet
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
    setState(() {});
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
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
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
            ChatComposer(onSend: _handleSend),
          ],
        ),
      ),
    );
  }
}
