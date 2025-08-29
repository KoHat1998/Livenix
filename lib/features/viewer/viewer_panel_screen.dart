import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/live_room.dart';
import '../../data/models/message.dart';
import '../../services/media_service.dart';
import '../../services/signal_service.dart';
import '../../services/live_service.dart';
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
  // UI
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late List<Message> messages;
  bool muted = false;

  // WebRTC / signaling
  final _media = MediaService.instance;
  final _signal = SignalService.instance;
  final _live = LiveService.instance;

  RTCPeerConnection? _pc;
  String? _roomId;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initRenderer();
    _bootstrap();

    // demo chat messages (local only for now)
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
    // Resolve IDs
    _roomId = widget.room?.id ?? 'test-room';
    final authUser = Supabase.instance.client.auth.currentUser;
    _userId = authUser?.id ?? 'guest-${Random().nextInt(999999)}';

    // When the broadcaster publishes an SDP offer -> answer it
    _signal.listenOffers(_roomId!, onData: (data) async {
      try {
        // Ignore duplicates if we already built a PC
        if (_pc != null) return;

        // 1) Viewer creates PC without local tracks (receive-only)
        _pc = await _media.newPeerConnection(addLocalTracks: false);

        // Pipe remote media into the UI
        _pc!.onTrack = (evt) {
          final stream = evt.streams.isNotEmpty ? evt.streams.first : null;
          if (stream != null) {
            _remoteRenderer.srcObject = stream;
            setState(() {}); // refresh video
          }
        };

        // Helpful logs (optional)
        _pc!.onConnectionState = (s) => debugPrint('viewer pc state: $s');
        _pc!.onIceConnectionState = (s) => debugPrint('viewer ICE: $s');

        // 2) Trickle ICE back to signaling
        _pc!.onIceCandidate = (candidate) async {
          if (candidate == null) return;
          await _signal.sendIce(
            _roomId!,
            candidate: {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex, // keep this exact key
            },
            from: _userId!,
          );
        };

        // 3) Apply broadcaster's offer
        final sdp = data['sdp'] as String?;
        final type = (data['type'] ?? 'offer') as String;
        if (sdp == null) return;
        await _pc!.setRemoteDescription(RTCSessionDescription(sdp, type));

        // 4) Create + set answer, then send it via signaling
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);

        await _signal.sendAnswer(
          _roomId!,               // <-- positional roomId (fix)
          sdp: answer.sdp!,       // service assumes type='answer'
          from: _userId!,
        );
      } catch (e) {
        debugPrint('viewer listenOffers error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept offer: $e')),
        );
      }
    });

    // Add remote ICE from broadcaster to our PC
    _signal.listenIce(_roomId!, onData: (payload) async {
      try {
        final pc = _pc;
        if (pc == null) return;

        final candMap =
        (payload['candidate'] ?? payload) as Map<String, dynamic>;
        final cand = RTCIceCandidate(
          candMap['candidate'] as String,
          candMap['sdpMid'] as String?,
          (candMap['sdpMLineIndex'] as num?)?.toInt(),
        );
        await pc.addCandidate(cand);
      } catch (_) {}
    });

    // (Optional) bump viewer count
    try {
      await _live.incrementViewers(_roomId!);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cleanupViewer();
    super.dispose();
  }

  Future<void> _cleanupViewer() async {
    try {
      final roomId = _roomId;
      _remoteRenderer.srcObject = null;
      await _remoteRenderer.dispose();

      if (_pc != null) {
        try {
          await _pc!.close();
        } catch (_) {}
      }
      _pc = null;

      if (roomId != null) {
        try {
          await _live.decrementViewers(roomId);
        } catch (_) {}
        // We keep the realtime channel open; SignalService can reuse it.
      }
    } catch (_) {}
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
            onPressed: () async {
              setState(() => muted = !muted);
              // Optional: wire to actual audio control when you manage tracks.
            },
            icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
            tooltip: muted ? 'Unmute' : 'Mute',
          ),
        ],
      ),
      body: Column(
        children: [
          // Video stage
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: RTCVideoView(
                    _remoteRenderer,
                    objectFit:
                    RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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

          // Chat list (local-only placeholder)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) => _ChatBubble(msg: messages[i]),
            ),
          ),

          // Composer (local-only placeholder)
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
