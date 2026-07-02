// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fire_alarm_app/main.dart';
import 'package:fire_alarm_app/providers/providers.dart';
import 'package:fire_alarm_app/services/websocket_service.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Mock shared preferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWith((ref) async => prefs),
          // Prevent real WebSocket connections + reconnect timers in widget tests.
          wsServiceProvider.overrideWith((ref) {
            return _TestWebSocketService(uri: 'ws://test');
          }),
        ],
        child: const FireAlarmApp(),
      ),
    );

    // Just verify the app widget renders without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class _TestWebSocketService extends WebSocketService {
  _TestWebSocketService({required super.uri});

  @override
  Future<void> connect() async {
    // no-op for tests
  }

  @override
  Future<void> disconnect() async {
    // no-op for tests
  }
}
