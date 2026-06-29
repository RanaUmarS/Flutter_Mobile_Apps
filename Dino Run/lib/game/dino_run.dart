import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'dino.dart';
import '../widgets/hud.dart';
import '../models/settings.dart';
import 'audio_manager.dart';
import 'enemy_manager.dart';
import 'coin_manager.dart';
import '../models/player_data.dart';
import '../widgets/pause_menu.dart';
import '../widgets/game_over_menu.dart';
import '../widgets/main_menu.dart';

// This is the main flame game class.
class DinoRun extends FlameGame with TapCallbacks, HasCollisionDetection {
  DinoRun({super.camera});

  // List of all the image assets.
  static const _imageAssets = [
    'DinoSprites - mort.png',
    'DinoSprites - doux.png',
    'DinoSprites - tard.png',
    'DinoSprites - vita.png',
    'AngryPig/Walk (36x30).png',
    'Bat/Flying (46x30).png',
    'Rino/Run (52x34).png',
    'parallax/plx-1.png',
    'parallax/plx-2.png',
    'parallax/plx-3.png',
    'parallax/plx-4.png',
    'parallax/plx-5.png',
    'parallax/plx-6.png',
  ];

  // List of all the audio assets.
  static const _audioAssets = [
    '8BitPlatformerLoop.wav',
    'hurt7.wav',
    'jump14.wav',
  ];

  late Dino _dino;
  Dino get dino => _dino;
  late Settings settings;
  late PlayerData playerData;
  late EnemyManager _enemyManager;
  late CoinManager _coinManager;

  Vector2 get virtualSize => camera.viewport.virtualSize;

  // This method get called while flame is preparing this game.
  @override
  Future<void> onLoad() async {
    // Makes the game full screen and landscape only.
    await Flame.device.fullScreen();
    await Flame.device.setLandscape();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlayerDataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SettingsAdapter());
    }

    /// Read [PlayerData] and [Settings] from hive.
    playerData = await _readPlayerData();
    // Ensure we start with fresh lives and score on every app launch
    playerData.lives = 5;
    playerData.currentScore = 0;

    settings = await _readSettings();

    /// Initilize [AudioManager].
    try {
      await AudioManager.instance.init(_audioAssets, settings);
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }

    // Cache all the images.
    await images.loadAll(_imageAssets);

    // This makes the camera look at the center of the viewport.
    camera.viewfinder.position = camera.viewport.virtualSize * 0.5;

    /// Create a [ParallaxComponent] and add it to game.
    final parallaxBackground = await loadParallaxComponent(
      [
        ParallaxImageData('parallax/plx-1.png'),
        ParallaxImageData('parallax/plx-2.png'),
        ParallaxImageData('parallax/plx-3.png'),
        ParallaxImageData('parallax/plx-4.png'),
        ParallaxImageData('parallax/plx-5.png'),
        ParallaxImageData('parallax/plx-6.png'),
      ],
      baseVelocity: Vector2(10, 0),
      velocityMultiplierDelta: Vector2(1.4, 0),
    );

    // Add the parallax as the backdrop.
    camera.backdrop.add(parallaxBackground);

    // Initial state
    overlays.add(MainMenu.id);
  }

  /// This method add the already created [Dino]
  /// and [EnemyManager] to this game.
  void startGamePlay() {
    _dino = Dino(playerData);
    // Set dino position relative to viewport
    _dino.position = Vector2(100, virtualSize.y - 28);
    _dino.anchor = Anchor.bottomLeft;

    _enemyManager = EnemyManager();
    _coinManager = CoinManager();

    world.add(_dino);
    world.add(_enemyManager);
    world.add(_coinManager);

    AudioManager.instance.startBgm('8BitPlatformerLoop.wav');
  }

  // This method remove all the actors from the game.
  void _disconnectActors() {
    _dino.removeFromParent();
    _enemyManager.removeAllEnemies();
    _enemyManager.removeFromParent();
    _coinManager.removeAllCoins();
    _coinManager.removeFromParent();
  }

  // This method reset the whole game world to initial state.
  void reset() {
    // First disconnect all actions from game world.
    _disconnectActors();

    // Reset player data to inital values.
    playerData.currentScore = 0;
    playerData.lives = 5;
  }

  // This method gets called for each tick/frame of the game.
  @override
  void update(double dt) {
    // If number of lives is 0 or less, game is over.
    if (playerData.lives <= 0) {
      overlays.add(GameOverMenu.id);
      overlays.remove(Hud.id);
      pauseEngine();
      AudioManager.instance.pauseBgm();

      // Update high score
      if (playerData.currentScore > playerData.highScore) {
        playerData.highScore = playerData.currentScore;
        playerData.save();
      }
    }
    super.update(dt);
  }

  // This will get called for each tap on the screen.
  @override
  void onTapDown(TapDownEvent event) {
    // Only used or empty if we move everything to buttons.
    // Making it empty to disable tap-to-jump
    super.onTapDown(event);
  }

  /// This method reads [PlayerData] from the hive box.
  Future<PlayerData> _readPlayerData() async {
    final playerDataBox = await Hive.openBox<PlayerData>(
      'DinoRun.PlayerDataBox',
    );
    final playerData = playerDataBox.get('DinoRun.PlayerData');

    // If data is null, this is probably a fresh launch of the game.
    if (playerData == null) {
      // In such cases store default values in hive.
      await playerDataBox.put('DinoRun.PlayerData', PlayerData());
    }

    // Now it is safe to return the stored value.
    return playerDataBox.get('DinoRun.PlayerData')!;
  }

  /// This method reads [Settings] from the hive box.
  Future<Settings> _readSettings() async {
    final settingsBox = await Hive.openBox<Settings>('DinoRun.SettingsBox');
    final settings = settingsBox.get('DinoRun.Settings');

    // If data is null, this is probably a fresh launch of the game.
    if (settings == null) {
      // In such cases store default values in hive.
      await settingsBox.put('DinoRun.Settings', Settings(bgm: true, sfx: true));
    }

    // Now it is safe to return the stored value.
    return settingsBox.get('DinoRun.Settings')!;
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // On resume, if active overlay is not PauseMenu,
      // resume the engine (lets the parallax effect play).
        if (!(overlays.isActive(PauseMenu.id)) &&
            !(overlays.isActive(GameOverMenu.id))) {
          resumeEngine();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      // If game is active, then remove Hud and add PauseMenu
      // before pausing the game.
        if (overlays.isActive(Hud.id)) {
          overlays.remove(Hud.id);
          overlays.add(PauseMenu.id);
        }
        pauseEngine();
        break;
    }
    super.lifecycleStateChange(state);
  }

  CoinManager get coinManager => _coinManager;
  EnemyManager get enemyManager => _enemyManager;
}
