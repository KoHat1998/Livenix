import 'package:flutter/material.dart';
import '../theme/theme.dart';

class LiveBadge extends StatelessWidget {
  final bool isLive;
  const LiveBadge({super.key, required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLive ? AppTheme.liveRed : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.circle : Icons.pause_circle_filled,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(isLive ? 'LIVE' : 'OFF', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
