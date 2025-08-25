import 'package:flutter/foundation.dart';
import 'models/live_room.dart';

class LiveRegistry {
  LiveRegistry._();
  static final LiveRegistry instance = LiveRegistry._();

  /// Current lives (UI listens to this)
  final ValueNotifier<List<LiveRoom>> lives = ValueNotifier<List<LiveRoom>>([]);

  void upsert(LiveRoom room) {
    final list = List<LiveRoom>.from(lives.value);
    final i = list.indexWhere((r) => r.id == room.id);
    if (i >= 0) {
      list[i] = room;
    } else {
      list.add(room);
    }
    lives.value = list;
  }

  void end(String roomId) {
    final list = List<LiveRoom>.from(lives.value)
      ..removeWhere((r) => r.id == roomId);
    lives.value = list;
  }
}
