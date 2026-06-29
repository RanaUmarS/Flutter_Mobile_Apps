import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'game/dino_run.dart';
import 'widgets/hud.dart';
import 'widgets/pause_menu.dart';
import 'widgets/game_over_menu.dart';
import 'widgets/main_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  // Initialize Hive
  await Hive.initFlutter();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dino Run',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Dino Run'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final DinoRun game;

  @override
  void initState() {
    super.initState();
    game = DinoRun();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          Hud.id: (BuildContext context, DinoRun game) => Hud(game: game),
          PauseMenu.id: (BuildContext context, DinoRun game) => PauseMenu(game: game),
          GameOverMenu.id: (BuildContext context, DinoRun game) => GameOverMenu(game: game),
          MainMenu.id: (BuildContext context, DinoRun game) => MainMenu(game: game),
        },
      ),
    );
  }
}
