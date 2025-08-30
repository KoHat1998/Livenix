import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/live_room.dart';
import '../../data/models/message.dart';
import '../../services/live_service.dart';
import '../../services/signal_service.dart';
import '../../theme/theme.dart';
import '../../widgets/chat_composer.dart';
import '../../widgets/live_badge.dart';

class ViewerPanelScreen extends StatefulWidget {
  final LiveRoom? room;
  const ViewerPanelScreen({super.key, this.room});

  @override
  State<ViewerPanelScreen> createState() => _ViewerPanelScreenState();
}

class _ViewerPanelScreenState extends State<ViewerPanelScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  late List<Message> messages;
  bool muted = false;

  final _signal = SignalService.instance;
  final _live = LiveService.instance;

  String? _roomId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initRenderer();
    _bootstrap();

    messages = List.generate(
      12,
          (i) => Message(
        id: '$i',
        from: i % 3 == 0 ? 'Host' : 'User $i',
        text: i % 3 == 0 ? 'Welcome to the stream!' : 'Hello everyone 👋',
        ts: DateTime.now().subtract(Duration(minutes: 12 - i)),
        isHost: i % 3 == 0,
      ),
    );
  }

  Future<void> _initRenderer() async {
    await _remoteRenderer.initialize();
  }

  Future<void> _bootstrap() async {
    _roomId = widget.room?.id ?? 'test-room';
    final authUser = Supabase.instance.client.auth.currentUser;
    _userId = authUser?.id ?? 'guest-${Random().nextInt(999999)}';

    try {
      await _signal.connect();
      await _signal.joinAsViewer();

      _signal.onBroadcasterStarted((_) {
        // If broadcaster already live or just started, attempt consume flow
        _consumeVideo();
      });

      _signal.onProducerClosed((data) {
        // { kind: 'video' } etc.
        debugPrint('[Viewer] Producer closed: $data');
      });

      await _live.incrementViewers(_roomId!);
    } catch (e) {
      debugPrint('[Viewer] bootstrap error: $e');
    }
  }

  Future<void> _consumeVideo() async {
    try {
      final caps = await _signal.getRouterRtpCapabilities();

      final tResp = await _signal.createTransport('recv');

      // NOTE:
      // In a real mediasoup client, your local RecvTransport generates its own
      // DTLS parameters. Here we just echo server’s DTLS parameters as a placeholder
      // so the signaling path completes (no media decode yet).
      await _signal.connectTransport(
        tResp['id'],
        tResp['dtlsParameters'],
      );

      final v = await _signal.consume(
        tResp['id'],
        'video',
        caps,
      );

      await _signal.resume(v['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to SFU (media playback pending client lib).'),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Viewer] consume flow error: $e');
    }
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    if (_roomId != null) {
      _live.decrementViewers(_roomId!);
    }
    _signal.disconnect();
    super.dispose();
  }

  void _send(String text) {
    setState(() {
      messages.add(
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          from: 'Me',
          text: text,
          ts: DateTime.now(),
          isHost: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Scaffold(
      appBar: AppBar(
        title: Text(room?.title ?? 'Live Stream'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => muted = !muted);
              // Hook to actual audio track volume when media is present.
            },
            icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
            tooltip: muted ? 'Unmute' : 'Mute',
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: LiveBadge(isLive: room?.isLive ?? true),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text('${room?.viewersCount ?? 0}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) => _ChatBubble(msg: messages[i]),
            ),
          ),
          ChatComposer(onSend: _send),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Message msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isHost = msg.isHost;
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
              msg.from.characters.first.toUpperCase(),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isHost ? AppTheme.surfaceVariant : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.from,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isHost
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(msg.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
