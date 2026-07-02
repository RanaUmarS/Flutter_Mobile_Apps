// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/fire_alarm_state.dart';

enum WsConnectionState {
  connecting,
  connected,
  disconnected,
  error,
}

class WebSocketService {
  final String uri;
  WebSocketChannel? _channel;

  final StreamController<WsConnectionState> _connectionStateController =
  StreamController<WsConnectionState>.broadcast();
  final StreamController<FireAlarmState> _sensorStreamController =
  StreamController<FireAlarmState>.broadcast();

  WsConnectionState _currentState = WsConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  Timer? _reconnectTimer;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  WebSocketService({this.uri = 'ws://192.168.4.1:81'});

  Stream<WsConnectionState> get connectionStream =>
      _connectionStateController.stream;
  Stream<FireAlarmState> get sensorStream => _sensorStreamController.stream;
  WsConnectionState get currentState => _currentState;
  bool get isConnected => _currentState == WsConnectionState.connected;

  Future<void> connect() async {
    if (_currentState == WsConnectionState.connected ||
        _currentState == WsConnectionState.connecting) {
      return;
    }

    _updateState(WsConnectionState.connecting);
    _reconnectAttempts = 0;

    try {
      print('[WS] Connecting to $uri');
      _channel = WebSocketChannel.connect(Uri.parse(uri));

      await _channel!.ready.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );

      _updateState(WsConnectionState.connected);
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      sendMessage('test');
    } catch (e) {
      print('[WS] Connection error: $e');
      _updateState(WsConnectionState.error);
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channel?.sink.close();
    _channel = null;
    _updateState(WsConnectionState.disconnected);
  }

  void sendMessage(String message) {
    try {
      if (_channel != null && _currentState == WsConnectionState.connected) {
        _channel!.sink.add(message);
        print('[WS] Sent: $message');
      }
    } catch (e) {
      print('[WS] Error sending: $e');
    }
  }

  void requestSensorData() => sendMessage('getSensors');
  void testConnection() => sendMessage('test');

  /// Sends the silence command to the ESP32.
  /// The ESP32 sets alarmSilenced = true which immediately stops
  /// the buzzer and LED blinking on the hardware.
  void sendSilence() => sendMessage('silence');

  /// Sends a threshold update to the ESP32 at runtime.
  /// [sensor] must be one of: "smoke", "flame", "tempDelta"
  /// [value]  is the new threshold value as a number.
  void sendThreshold(String sensor, num value) =>
      sendMessage('{"cmd":"setThreshold","sensor":"$sensor","value":$value}');

  void _onMessage(dynamic message) {
    try {
      final Map<String, dynamic> json =
      jsonDecode(message as String) as Map<String, dynamic>;
      final type = json['type'] as String? ?? '';

      switch (type) {
        case 'handshake':
        case 'test':
        case 'sensorData':
        case 'update':
          if (!_sensorStreamController.isClosed) {
            _sensorStreamController.add(FireAlarmState.fromJson(json));
          }
          break;
        default:
          if (_looksLikeSensorPayload(json)) {
            if (!_sensorStreamController.isClosed) {
              _sensorStreamController.add(FireAlarmState.fromJson(json));
            }
          } else {
            print('[WS] Unknown message type: $type');
          }
      }
    } catch (e) {
      print('[WS] Error parsing message: $e');
    }
  }

  bool _looksLikeSensorPayload(Map<String, dynamic> json) {
    return json.containsKey('alarms') ||
        json.containsKey('flameAlarm') ||
        json.containsKey('smokeAlarm') ||
        json.containsKey('tempAlarm') ||
        json.containsKey('vibrationAlarm') ||
        json.containsKey('temp') ||
        json.containsKey('smoke') ||
        json.containsKey('flame') ||
        json.containsKey('vibration');
  }

  void _onError(dynamic error) {
    print('[WS] Error: $error');
    _updateState(WsConnectionState.error);
    _scheduleReconnect();
  }

  void _onDone() {
    print('[WS] Connection closed');
    _updateState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[WS] Max reconnect attempts reached');
      _updateState(WsConnectionState.disconnected);
      return;
    }

    _reconnectAttempts++;
    print(
        '[WS] Reconnecting in ${_reconnectDelay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, connect);
  }

  void _updateState(WsConnectionState state) {
    if (_currentState != state) {
      _currentState = state;
      print('[WS] State: ${state.name}');
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(state);
      }
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _connectionStateController.close();
    _sensorStreamController.close();
    _channel?.sink.close();
  }
}
