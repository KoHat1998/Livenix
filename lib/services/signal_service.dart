import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Socket.IO signaling for Livenix SFU Bridge.
/// Endpoint is your Caddy domain that reverse-proxies to the Node bridge.
class SignalService {
  SignalService._();
  static final instance = SignalService._();

  // Change if you host on a different domain/path.
  static const String _endpoint = 'https://livenix.htetaungthant.com';

  IO.Socket? _socket;
  bool get isConnected => _socket?.connected == true;

  /// Connect to the SFU bridge.
  Future<void> connect() async {
    if (isConnected) return;

    final completer = Completer<void>();

    _socket = IO.io(
      _endpoint,
      IO.OptionBuilder()
          .setTransports(['websocket']) // force ws/wss
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      // Connected
      if (!completer.isCompleted) completer.complete();
      // Optional: print logs
      // print('[Signal] connected');
    });

    _socket!.onConnectError((err) {
      if (!completer.isCompleted) completer.completeError(err.toString());
    });

    _socket!.onError((err) {
      // print('[Signal] error: $err');
    });

    return completer.future;
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ---------- Join roles ----------
  Future<void> joinAsBroadcaster() {
    final c = Completer<void>();
    _socket?.emitWithAck('join', {'role': 'broadcaster'}, ack: (resp) {
      if (resp is Map && resp['error'] != null) {
        c.completeError(resp['error']);
      } else {
        c.complete();
      }
    });
    return c.future;
  }

  Future<void> joinAsViewer() {
    final c = Completer<void>();
    _socket?.emitWithAck('join', {'role': 'viewer'}, ack: (resp) {
      if (resp is Map && resp['error'] != null) {
        c.completeError(resp['error']);
      } else {
        c.complete();
      }
    });
    return c.future;
  }

  // ---------- Queries / actions ----------
  Future<Map<String, dynamic>> getRouterRtpCapabilities() {
    final c = Completer<Map<String, dynamic>>();
    _socket?.emitWithAck('getRouterRtpCapabilities', null, ack: (data) {
      if (data is Map) {
        c.complete(Map<String, dynamic>.from(data));
      } else {
        c.completeError('Invalid router caps');
      }
    });
    return c.future;
  }

  Future<Map<String, dynamic>> createTransport(String direction) {
    final c = Completer<Map<String, dynamic>>();
    _socket?.emitWithAck('createTransport', {'direction': direction}, ack: (data) {
      if (data is Map && data['error'] == null) {
        c.complete(Map<String, dynamic>.from(data));
      } else {
        c.completeError(data?['error'] ?? 'createTransport failed');
      }
    });
    return c.future;
  }

  Future<void> connectTransport(String transportId, dynamic dtlsParameters) {
    final c = Completer<void>();
    _socket?.emitWithAck(
      'connectTransport',
      {'transportId': transportId, 'dtlsParameters': dtlsParameters},
      ack: (data) {
        if (data is Map && data['error'] != null) {
          c.completeError(data['error']);
        } else {
          c.complete();
        }
      },
    );
    return c.future;
  }

  Future<Map<String, dynamic>> consume(
      String transportId,
      String kind,
      dynamic rtpCapabilities,
      ) {
    final c = Completer<Map<String, dynamic>>();
    _socket?.emitWithAck(
      'consume',
      {
        'transportId': transportId,
        'kind': kind,
        'rtpCapabilities': rtpCapabilities,
      },
      ack: (data) {
        if (data is Map && data['error'] == null) {
          c.complete(Map<String, dynamic>.from(data));
        } else {
          c.completeError(data?['error'] ?? 'consume failed');
        }
      },
    );
    return c.future;
  }

  Future<void> resume(String consumerId) {
    final c = Completer<void>();
    _socket?.emitWithAck('resume', {'consumerId': consumerId}, ack: (data) {
      if (data is Map && data['error'] != null) {
        c.completeError(data['error']);
      } else {
        c.complete();
      }
    });
    return c.future;
  }

  /// For future (when we add send flow with mediasoup client on Flutter)
  Future<Map<String, dynamic>> produce(
      String transportId,
      String kind,
      dynamic rtpParameters,
      ) {
    final c = Completer<Map<String, dynamic>>();
    _socket?.emitWithAck(
      'produce',
      {'transportId': transportId, 'kind': kind, 'rtpParameters': rtpParameters},
      ack: (data) {
        if (data is Map && data['error'] == null) {
          c.complete(Map<String, dynamic>.from(data));
        } else {
          c.completeError(data?['error'] ?? 'produce failed');
        }
      },
    );
    return c.future;
  }

  // ---------- Listeners ----------
  void onBroadcasterStarted(Function(dynamic) cb) {
    _socket?.on('broadcaster-started', cb);
  }

  void onBroadcasterLeft(Function(dynamic) cb) {
    _socket?.on('broadcaster-left', cb);
  }

  void onProducerClosed(Function(dynamic) cb) {
    _socket?.on('producer-closed', cb);
  }
}
