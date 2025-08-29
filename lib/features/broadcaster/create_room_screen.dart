import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for Clipboard
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // <-- NEW

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
  late String roomId; // UUID

  @override
  void initState() {
    super.initState();
    // Generate a UUID that matches the DB column type
    roomId = const Uuid().v4();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  void _start() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to create a room.')),
      );
      return;
    }

    final room = LiveRoom(
      id: roomId, // <-- UUID now
      title: titleCtrl.text.isEmpty ? 'My Live' : titleCtrl.text.trim(),
      hostName: nameCtrl.text.isEmpty ? 'Broadcaster' : nameCtrl.text.trim(),
      viewersCount: 0,
      isLive: false,
      status: 'preparing',
      hostUserId: userId,
      thumbnailUrl: null,
      // startedAt/endedAt set when going live / ending
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

                // Optional: show/allow editing display name (hidden UI for now)
                // TextField(controller: nameCtrl, ...)

                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Live Title (optional)',
                    prefixIcon: Icon(Icons.title),
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
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: roomId));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room ID copied')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy ID'),
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
          Text(
            '$label: ',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(width: 4),
          SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
