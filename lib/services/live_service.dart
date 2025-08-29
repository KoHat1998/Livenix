import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/live_room.dart';

class LiveService {
  LiveService._();
  static final instance = LiveService._();

  final _db = Supabase.instance.client;

  /// Start or update a live room
  Future<void> startLive(LiveRoom room) async {
    final payload = {
      'id': room.id,                                  // uuid
      'title': room.title,
      'host_user_id': room.hostUserId,                // uuid (FK to auth.users)
      // If your table also stores a display name, uncomment the next line and add the column:
      // 'host_name': room.hostName,
      'status': room.status,                          // 'live' / 'preparing' / 'ended'
      'started_at': (room.startedAt ?? DateTime.now()).toIso8601String(),
      'thumbnail_url': room.thumbnailUrl ?? '',       // <-- important (NOT NULL)
      'viewers_peak': room.viewersCount,              // int (defaults to 0)
    };

    // upsert will insert or update based on primary key (id)
    await _db.from('live_rooms').upsert(payload).select().single();
  }

  /// End a live room
  Future<void> endLive(String roomId) async {
    await _db
        .from('live_rooms')
        .update({
      'status': 'ended',
      'ended_at': DateTime.now().toIso8601String(),
    })
        .eq('id', roomId);
  }

  /// Increment viewers count (simple version)
  Future<void> incrementViewers(String roomId) async {
    final row = await _db
        .from('live_rooms')
        .select('viewers_peak')
        .eq('id', roomId)
        .maybeSingle();

    final current = (row?['viewers_peak'] as int?) ?? 0;

    await _db
        .from('live_rooms')
        .update({'viewers_peak': current + 1})
        .eq('id', roomId);
  }

  /// Decrement viewers count (simple version)
  Future<void> decrementViewers(String roomId) async {
    final row = await _db
        .from('live_rooms')
        .select('viewers_peak')
        .eq('id', roomId)
        .maybeSingle();

    final current = (row?['viewers_peak'] as int?) ?? 0;
    final next = current > 0 ? current - 1 : 0;

    await _db
        .from('live_rooms')
        .update({'viewers_peak': next})
        .eq('id', roomId);
  }
}
