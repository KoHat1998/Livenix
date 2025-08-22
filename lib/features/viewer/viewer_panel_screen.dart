import 'package:flutter/material.dart';
import '../../data/models/live_room.dart';
import '../../data/models/message.dart';
import '../../theme/theme.dart';
import '../../widgets/live_badge.dart';
import '../../widgets/chat_composer.dart';

class ViewerPanelScreen extends StatefulWidget {
  final LiveRoom? room;
  const ViewerPanelScreen({super.key, this.room});

  @override
  State<ViewerPanelScreen> createState() => _ViewerPanelScreenState();
}

class _ViewerPanelScreenState extends State<ViewerPanelScreen> {
  late List<Message> messages;
  bool muted = false;

  @override
  void initState() {
    super.initState();
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

  void _send(String text) {
    setState(() {
      messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        from: 'Me',
        text: text,
        ts: DateTime.now(),
        isHost: false,
      ));
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
            onPressed: () => setState(() => muted = !muted),
            icon: Icon(muted ? Icons.volume_off : Icons.volume_up),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video stage placeholder
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Center(
                    child: Icon(Icons.live_tv_outlined, size: 64),
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text('${room?.viewersCount ?? 128}'),
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
              itemBuilder: (context, i) {
                final m = messages[i];
                return _ChatBubble(msg: m);
              },
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
            backgroundColor: isHost ? AppTheme.primary : AppTheme.surfaceVariant,
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
                  Text(msg.from,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isHost
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      )),
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
