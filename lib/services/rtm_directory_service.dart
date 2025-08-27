// lib/services/rtm_directory_service.dart
//
// Stub RTM directory so the app builds/runs without the agora_rtm plugin.
// It mirrors the same API but does everything locally via LiveRegistry.
//
// Later, when you want cross-device discovery again, we can swap this file
// back to the real RTM implementation (or Firebase, etc).

import '../data/live_registry.dart';
import '../data/models/live_room.dart';

class RtmDirectoryService {
  RtmDirectoryService._();
  static final RtmDirectoryService instance = RtmDirectoryService._();

  // Toggle if you want logs while stubbing
  static const bool _log = false;

  Future<void> disconnect() async {
    if (_log) print('[RTM STUB] disconnect()');
  }

  /// “Publish” live locally (so LivesList updates on this device).
  Future<void> publishLive(LiveRoom room) async {
    if (_log) print('[RTM STUB] publishLive: ${room.id}');
    LiveRegistry.instance.upsert(room);
  }

  /// “Unpublish” live locally.
  Future<void> unpublishLive(String roomId) async {
    if (_log) print('[RTM STUB] unpublishLive: $roomId');
    LiveRegistry.instance.end(roomId);
  }

  /// No-op: with no RTM backend there’s nothing to subscribe to.
  Future<void> subscribeDirectory() async {
    if (_log) print('[RTM STUB] subscribeDirectory() – no RTM backend');
  }
}
