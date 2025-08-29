import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Global ICE configuration for WebRTC.
/// STUN is fine for development; we'll add TURN later for NAT traversal.
final Map<String, dynamic> rtcConfiguration = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ],
  'sdpSemantics': 'unified-plan',
};

/// Offer/answer constraints (keep defaults simple for now)
final Map<String, dynamic> defaultOfferConstraints = {
  'offerToReceiveAudio': true,
  'offerToReceiveVideo': true,
};
