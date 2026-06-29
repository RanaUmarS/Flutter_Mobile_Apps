// This is a basic Flutter widget test.
//
// The default Flutter template test expects a counter app.
// This project uses Flame's GameWidget, so we do a simple smoke test instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dino_run/main.dart';

void main() {
  testWidgets('App boots and shows the Dino Run shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Dino Run'), findsWidgets); // AppBar title + MaterialApp title usage
  });
}
