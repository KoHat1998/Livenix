// lib/data/models/live_room.dart

class LiveRoom {
  final String id;              // live_rooms.id (uuid)
  final String title;           // live_rooms.title
  final String hostName;        // derived (for now: host_user_id; later join profiles.display_name)
  final int viewersCount;       // live_rooms.viewers_peak
  final bool isLive;            // derived from live_rooms.status == 'live'
  final String? thumbnailUrl;   // live_rooms.thumbnail_url
  final DateTime? startedAt;    // live_rooms.started_at
  final DateTime? endedAt;      // live_rooms.ended_at
  final String status;          // live_rooms.status: 'preparing' | 'live' | 'ended'
  final String hostUserId;      // live_rooms.host_user_id (uuid)

  const LiveRoom({
    required this.id,
    required this.title,
    required this.hostName,
    required this.viewersCount,
    required this.isLive,
    required this.status,
    required this.hostUserId,
    this.thumbnailUrl,
    this.startedAt,
    this.endedAt,
  });

  LiveRoom copyWith({
    String? id,
    String? title,
    String? hostName,
    int? viewersCount,
    bool? isLive,
    String? status,
    String? hostUserId,
    String? thumbnailUrl,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return LiveRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      viewersCount: viewersCount ?? this.viewersCount,
      isLive: isLive ?? this.isLive,
      status: status ?? this.status,
      hostUserId: hostUserId ?? this.hostUserId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  /// Parse from a Supabase row (Map) returned by .select() on 'live_rooms'
  factory LiveRoom.fromMap(Map<String, dynamic> map) {
    final status = (map['status'] as String?) ?? 'ended';
    final hostUserId = (map['host_user_id'] as String?) ?? '';

    // For now, use host_user_id as hostName.
    // Later we can join profiles to show display_name.
    final hostName = map['host_display_name'] as String? ?? hostUserId;

    DateTime? tryParseTs(dynamic v) {
      if (v == null) return null;
      // Supabase returns ISO 8601 strings for timestamptz
      return DateTime.tryParse(v.toString());
    }

    return LiveRoom(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Untitled',
      hostName: hostName,
      status: status,
      hostUserId: hostUserId,
      viewersCount: (map['viewers_peak'] as int?) ?? 0,
      isLive: status == 'live',
      thumbnailUrl: map['thumbnail_url'] as String?,
      startedAt: tryParseTs(map['started_at']),
      endedAt: tryParseTs(map['ended_at']),
    );
  }

  /// Handy if you want to insert/update back to Supabase
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'host_user_id': hostUserId,
    'status': status,
    'viewers_peak': viewersCount,
    'thumbnail_url': thumbnailUrl,
    'started_at': startedAt?.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    // Note: host_display_name is not a real column (we’d join from profiles)
  };
}
