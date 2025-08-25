import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../core/agora_config.dart';

class AgoraService {
  AgoraService._internal();
  static final AgoraService instance = AgoraService._internal();

  late final RtcEngine _engine;
  bool _initialized = false;
  String? currentChannelId;

  /// remote user ids in the current channel
  final ValueNotifier<Set<int>> remoteUids = ValueNotifier(<int>{});

  RtcEngine get engine => _engine;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(appId: agoraAppId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          currentChannelId = connection.channelId;
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          final s = Set<int>.from(remoteUids.value)..add(remoteUid);
          remoteUids.value = s;
        },
        onUserOffline:
            (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          final s = Set<int>.from(remoteUids.value)..remove(remoteUid);
          remoteUids.value = s;
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          remoteUids.value = <int>{};
          currentChannelId = null;
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );

    _initialized = true;
  }

  Future<void> joinAsBroadcaster({
    required String channelId,
    String token = agoraTempToken,
    int uid = 0,
  }) async {
    await _ensureInitialized();
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  Future<void> joinAsAudience({
    required String channelId,
    String token = agoraTempToken,
    int uid = 0,
  }) async {
    await _ensureInitialized();
    await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleAudience,
        publishCameraTrack: false,
        publishMicrophoneTrack: false,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  Future<void> setMicOn(bool on) async {
    await _engine.muteLocalAudioStream(!on);
  }

  Future<void> setCameraOn(bool on) async {
    await _engine.muteLocalVideoStream(!on);
    if (on) {
      await _engine.startPreview();
    } else {
      await _engine.stopPreview();
    }
  }

  Future<void> switchCamera() => _engine.switchCamera();

  Future<void> leave() async {
    await _engine.leaveChannel();
  }
}
