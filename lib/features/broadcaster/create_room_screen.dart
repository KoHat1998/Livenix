import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/live_room.dart';
import '../../theme/theme.dart';
import '../../widgets/gradient_button.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final titleCtrl = TextEditingController();
  final nameCtrl = TextEditingController(text: 'Broadcaster');
  late String roomId;

  @override
  void initState() {
    super.initState();
    roomId = _generateRoomId();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  String _generateRoomId() {
    final rnd = Random();
    return (100000 + rnd.nextInt(899999)).toString();
  }

  void _start() {
    final room = LiveRoom(
      id: roomId,
      title: titleCtrl.text.isEmpty ? 'My Live' : titleCtrl.text,
      hostName: nameCtrl.text.isEmpty ? 'Broadcaster' : nameCtrl.text,
      viewersCount: 0,
      isLive: false,
    );
    context.push('/broadcast/dashboard', extra: room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InfoTile(label: 'Room ID', value: roomId),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Live Title (optional)',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Your display name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Start',
                  icon: Icons.videocam_outlined,
                  onPressed: _start,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // copy to clipboard later
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room ID copied')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy ID'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // share later
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share coming soon')),
                        );
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text('$label: ',
              style:
              const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(width: 4),
          SelectableText(value,
              style:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}
