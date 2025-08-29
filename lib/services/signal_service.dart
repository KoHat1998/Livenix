import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple WebRTC signaling on Supabase Realtime (broadcast).
/// Events: 'offer', 'answer', 'ice'
class SignalService {
  SignalService._();
  static final instance = SignalService._();

  final SupabaseClient _sb = Supabase.instance.client;

  /// Cache channels per room so we don't resubscribe repeatedly.
  final Map<String, RealtimeChannel> _channels = {};

  String _keyFor(String roomId) => 'live:$roomId';

  /// Open (or reuse) a channel for a room.
  Future<RealtimeChannel> open(String roomId) async {
    final key = _keyFor(roomId);
    final existing = _channels[key];
    if (existing != null) return existing;

    // Supabase v2 style:
    final ch = _sb.channel(key);
    await ch.subscribe();
    _channels[key] = ch;
    return ch;
  }

  Future<void> close(String roomId) async {
    final key = _keyFor(roomId);
    final ch = _channels.remove(key);
    if (ch != null) {
      await ch.unsubscribe();
      _sb.removeChannel(ch);
    }
  }

  // ---------------- SEND ----------------

  Future<void> sendOffer(
      String roomId, {
        required String sdp,
        required String from,
      }) async {
    final ch = await open(roomId);
    await ch.sendBroadcastMessage(
      event: 'offer',
      payload: {
        'sdp': sdp,
        'from': from,
        'ts': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> sendAnswer(
      String roomId, {
        required String sdp,
        required String from,
      }) async {
    final ch = await open(roomId);
    await ch.sendBroadcastMessage(
      event: 'answer',
      payload: {
        'sdp': sdp,
        'from': from,
        'ts': DateTime.now().toIso8601String(),
      },
    );
  }

  /// `candidate` should include: candidate, sdpMid, sdpMLineIndex
  Future<void> sendIce(
      String roomId, {
        required Map<String, dynamic> candidate,
        required String from,
      }) async {
    final ch = await open(roomId);
    await ch.sendBroadcastMessage(
      event: 'ice',
      payload: {
        'candidate': candidate,
        'from': from,
        'ts': DateTime.now().toIso8601String(),
      },
    );
  }

  // ---------------- LISTEN ----------------
  // Use these once per screen to receive events.

  void listenOffers(
      String roomId, {
        required void Function(Map<String, dynamic> data) onData,
      }) {
    final ch = _channels[_keyFor(roomId)];
    ch?.onBroadcast(
      event: 'offer',
      callback: (payload, [ref]) =>
          onData(Map<String, dynamic>.from(payload)),
    );
  }

  void listenAnswers(
      String roomId, {
        required void Function(Map<String, dynamic> data) onData,
      }) {
    final ch = _channels[_keyFor(roomId)];
    ch?.onBroadcast(
      event: 'answer',
      callback: (payload, [ref]) =>
          onData(Map<String, dynamic>.from(payload)),
    );
  }

  void listenIce(
      String roomId, {
        required void Function(Map<String, dynamic> data) onData,
      }) {
    final ch = _channels[_keyFor(roomId)];
    ch?.onBroadcast(
      event: 'ice',
      callback: (payload, [ref]) =>
          onData(Map<String, dynamic>.from(payload)),
    );
  }
}
