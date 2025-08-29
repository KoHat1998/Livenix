import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/webrtc_config.dart';

class MediaService {
  MediaService._();

  static final instance = MediaService._();

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _inited = false;

  Future<void> _ensureInit() async {
    if (_inited) return;
    await localRenderer.initialize();
    _inited = true;
  }

  Future<void> joinAsBroadcaster() async {
    await _ensureInit();
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
        'frameRate': {'ideal': 30},
      }
    });
    _localStream = stream;
    localRenderer.srcObject = stream;
  }

  Future<void> leave() async {
    final s = _localStream;
    if (s != null) {
      for (final t in s.getTracks()) {
        try {
          await t.stop();
        } catch (_) {}
      }
      await s.dispose();
    }
    _localStream = null;
    localRenderer.srcObject = null;
  }

  Future<void> setMicOn(bool on) async {
    final tracks = _localStream?.getAudioTracks();
    if (tracks != null && tracks.isNotEmpty) {
      tracks.first.enabled = on;
    }
  }

  Future<void> setCameraOn(bool on) async {
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      tracks.first.enabled = on;
    }
  }

  Future<void> switchCamera() async {
    final tracks = _localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      await Helper.switchCamera(tracks.first);
    }
  }

  /// Expose the current local stream (after joinAsBroadcaster)
  MediaStream? get localStream => _localStream;

  Future<RTCPeerConnection> newPeerConnection({bool addLocalTracks = true}) async {
    // This calls the SDK's top-level function (no recursion now)
    final pc = await createPeerConnection(rtcConfiguration);

    if (addLocalTracks && _localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    // Debug logs
    pc.onIceConnectionState = (state) {
      debugPrint('ICE state: $state');
    };
    pc.onConnectionState = (state) {
      debugPrint('PeerConnection state: $state');
    };

    return pc;
  }

}
