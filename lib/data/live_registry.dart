import 'package:flutter/foundation.dart';
import 'models/live_room.dart';

/// In-memory live directory used by LivesListScreen.
/// No backend/database; UI listens to [lives] ValueListenable.
class LiveRegistry {
  LiveRegistry._();
  static final LiveRegistry instance = LiveRegistry._();

  /// Current lives (UI listens to this)
  final ValueNotifier<List<LiveRoom>> lives = ValueNotifier<List<LiveRoom>>([]);

  /// Insert or replace a room. Marks it live unless explicitly set otherwise.
  void upsert(LiveRoom room) {
    final list = List<LiveRoom>.from(lives.value);
    final idx = list.indexWhere((r) => r.id == room.id);
    if (idx >= 0) {
      // Merge basic fields; prefer new values if provided
      final prev = list[idx];
      list[idx] = prev.copyWith(
        title: room.title ?? prev.title,
        hostName: room.hostName ?? prev.hostName,
        thumbnailUrl: room.thumbnailUrl ?? prev.thumbnailUrl,
        isLive: room.isLive ?? true,
        viewersCount: room.viewersCount ?? prev.viewersCount,
      );
    } else {
      list.add(room.copyWith(isLive: room.isLive ?? true, thumbnailUrl: null));
    }
    lives.value = list;
  }

  /// Mark a room as ended (remove from list).
  void end(String roomId) {
    final list = List<LiveRoom>.from(lives.value)
      ..removeWhere((r) => r.id == roomId);
    lives.value = list;
  }

  /// Increment viewer count for a room (no concurrency guarantees; UI-only).
  void incViewers(String roomId, [int delta = 1]) {
    final list = List<LiveRoom>.from(lives.value);
    final idx = list.indexWhere((r) => r.id == roomId);
    if (idx < 0) return;
    final r = list[idx];
    final next = (r.viewersCount ?? 0) + delta;
    list[idx] = r.copyWith(viewersCount: next < 0 ? 0 : next, thumbnailUrl: null);
    lives.value = list;
  }

  /// Decrement viewer count.
  void decViewers(String roomId, [int delta = 1]) => incViewers(roomId, -delta);

  /// Update title/host/thumbnail if needed.
  void updateMeta({
    required String roomId,
    String? title,
    String? hostName,
    String? thumbnailUrl,
  }) {
    final list = List<LiveRoom>.from(lives.value);
    final idx = list.indexWhere((r) => r.id == roomId);
    if (idx < 0) return;
    final r = list[idx];
    list[idx] = r.copyWith(
      title: title ?? r.title,
      hostName: hostName ?? r.hostName,
      thumbnailUrl: thumbnailUrl ?? r.thumbnailUrl,
    );
    lives.value = list;
  }

  /// Clear everything (useful for tests/dev reset).
  void clear() {
    lives.value = <LiveRoom>[];
  }
}
