import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart';
import 'audio_manager.dart';

const double groundHeight = 20;
const int numberOfTilesAlongWidth = 10;
const double gravity = 1000;

enum DinoAnimationStates { idle, run, kick, hit, sprint }

/// -----------------------------------------------------------------------
/// 1. The Dino Class 
/// -----------------------------------------------------------------------
class Dino extends SpriteAnimationGroupComponent<DinoAnimationStates>
    with CollisionCallbacks, HasGameReference<DinoGame> {

  double yMax = 0.0;
  double speedY = 0.0;

  final Timer _hitTimer = Timer(1);
  bool isHit = false;

  int lives = 5;

  Dino({required super.position, required super.size, required super.anchor});

  @override
  Future<void> onLoad() async {
    final image = await game.images.load('DinoSprites - mort.png');
    final spriteSheet = SpriteSheet(
      image: image,
      srcSize: Vector2.all(24),
    );

    // Idle: 4, Run: 6, Kick: 4, Hit: 3, Sprint: 7

    final idleAnim = spriteSheet.createAnimation(row: 0, stepTime: 0.1, from: 0, to: 4);
    final runAnim = spriteSheet.createAnimation(row: 0, stepTime: 0.1, from: 4, to: 10);
    final kickAnim = spriteSheet.createAnimation(row: 0, stepTime: 0.1, from: 10, to: 14);
    final hitAnim = spriteSheet.createAnimation(row: 0, stepTime: 0.1, from: 14, to: 17);
    final sprintAnim = spriteSheet.createAnimation(row: 0, stepTime: 0.1, from: 17, to: 24);

    animations = {
      DinoAnimationStates.idle: idleAnim,
      DinoAnimationStates.run: runAnim,
      DinoAnimationStates.kick: kickAnim,
      DinoAnimationStates.hit: hitAnim,
      DinoAnimationStates.sprint: sprintAnim,
    };

    // Dino ki initial state
    current = DinoAnimationStates.run;

    add(RectangleHitbox(
      position: Vector2(size.x * 0.2, size.y * 0.2),
      size: Vector2(size.x * 0.6, size.y * 0.7),
    ));

    // Setup Timer callback
    _hitTimer.onTick = () {
      current = DinoAnimationStates.run;
      isHit = false;
    };

    // Set initial ground limit based on spawn position
    yMax = y;

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // --- Physics Logic (Ported) ---

    // v = u + at
    speedY += gravity * dt;

    // d = s0 + s * t
    y += speedY * dt;

    // Prevent falling below ground
    if (isOnGround) {
      y = yMax;
      speedY = 0.0;
      if ((current != DinoAnimationStates.hit) &&
          (current != DinoAnimationStates.run)) {
        current = DinoAnimationStates.run;
      }
    }

    _hitTimer.update(dt);
    super.update(dt);
  }

  // Helper to check if on ground
  bool get isOnGround => (y >= yMax);

  void jump() {
    if (isOnGround) {
      // Jump force depends on size to feel right on different screens
      speedY = -500;
      current = DinoAnimationStates.idle; // or jump animation if you have one
      AudioManager.instance.playSfx('jump14.wav');
    }
  }

  void hit() {
    if (!isHit) {
      isHit = true;
      AudioManager.instance.playSfx('hurt7.wav');
      current = DinoAnimationStates.hit;
      _hitTimer.start();
      lives -= 1;
      print("Dino Hit! Lives: $lives");
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Logic to detect Enemy collision
    // if (other is Enemy) {
    //   hit();
    // }
    super.onCollisionStart(intersectionPoints, other);
  }
}

/// -----------------------------------------------------------------------
/// 2. The Game Class
/// -----------------------------------------------------------------------
class DinoGame extends FlameGame with HasCollisionDetection, TapCallbacks {
  late Dino _dino;
  late ParallaxComponent _parallaxComponent;
  bool _isLoaded = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Load Background Layers
    final layers = <ParallaxLayer>[];
    for (var i = 1; i <= 5; i++) {
      layers.add(
        await loadParallaxLayer(
          ParallaxImageData('parallax/plx-$i.png'),
          filterQuality: FilterQuality.none,
          fill: LayerFill.height,
          repeat: ImageRepeat.repeatX,
          velocityMultiplier: Vector2(pow(1.1, i - 1).toDouble(), 1.0),
        ),
      );
    }

    // Load Ground Layer
    layers.add(
      await loadParallaxLayer(
        ParallaxImageData('parallax/plx-6.png'),
        filterQuality: FilterQuality.none,
        fill: LayerFill.none,
        alignment: Alignment.bottomLeft,
        repeat: ImageRepeat.repeatX,
        velocityMultiplier: Vector2(pow(1.1, 5).toDouble(), 1.0),
      ),
    );

    _parallaxComponent = ParallaxComponent(
      parallax: Parallax(
        layers,
        baseVelocity: Vector2(100, 0),
      ),
    );
    add(_parallaxComponent);

    _dino = Dino(
      position: Vector2.zero(),
      size: Vector2.all(128),
      anchor: Anchor.bottomLeft,
    );
    add(_dino);

    _isLoaded = true;
    _updateLayout(size);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _dino.jump();
    super.onTapDown(event);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_isLoaded) {
      _updateLayout(size);
    }
  }

  void _updateLayout(Vector2 size) {
    _parallaxComponent.size = size;
    _updateDinoPosition(size);
  }

  void _updateDinoPosition(Vector2 size) {
    double newWidth = size.x / numberOfTilesAlongWidth;

    _dino.size = Vector2(newWidth, newWidth);
    _dino.x = newWidth;

    // The physics engine needs to know where the floor is
    double newGroundY = size.y - groundHeight;
    _dino.yMax = newGroundY;

    // Only snap dino to ground if he isn't currently jumping
    if (_dino.isOnGround) {
      _dino.y = newGroundY;
    }
  }
}