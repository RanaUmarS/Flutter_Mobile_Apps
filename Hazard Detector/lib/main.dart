// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/fire_alarm_state.dart';
import 'providers/providers.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Immersive status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Init notifications
  await NotificationService().init();

  // Init shared prefs — eagerly so we can pass it in via override
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // FutureProvider override — must return a Future
        sharedPrefsProvider.overrideWith((ref) async => prefs),
      ],
      child: const FireAlarmApp(),
    ),
  );
}

class FireAlarmApp extends ConsumerStatefulWidget {
  const FireAlarmApp({super.key});

  @override
  ConsumerState<FireAlarmApp> createState() => _FireAlarmAppState();
}

class _FireAlarmAppState extends ConsumerState<FireAlarmApp> {
  Future<void>? _pushInit;
  ProviderSubscription<AsyncValue<FireAlarmState>>? _alarmSubscription;

  @override
  void initState() {
    super.initState();
    _pushInit ??= _initPushNotifications();
    _alarmSubscription ??=
        ref.listenManual<AsyncValue<FireAlarmState>>(sensorStateProvider,
                (_, next) {
              next.whenData((sensorState) {
                ref.read(alarmServiceProvider.notifier).handleSensorState(sensorState);
              });
            });
  }

  @override
  void dispose() {
    _alarmSubscription?.close();
    super.dispose();
  }

  Future<void> _initPushNotifications() async {
    final router = ref.read(routerProvider);
    final push = ref.read(pushNotificationServiceProvider);

    await push.init(
      onNotificationTap: () => _openAlarmScreen(router),
    );
  }

  void _openAlarmScreen(GoRouter router) {
    if (!mounted) return;
    router.go('/alarm');
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Hazard Detector',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}