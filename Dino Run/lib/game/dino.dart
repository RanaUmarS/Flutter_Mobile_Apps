import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import '../models/player_data.dart';

import 'enemy.dart';
import 'dino_run.dart';
import 'audio_manager.dart';

import 'bullet.dart';

enum DinoAnimationStates { idle, run, kick, hit, sprint }

class Dino extends SpriteAnimationGroupComponent<DinoAnimationStates>
    with CollisionCallbacks, HasGameReference<DinoRun> {
  final PlayerData playerData;

  double speedY = 0.0;
  final double gravity = 1000.0;
  late double _groundY;
  bool _isLoaded = false;

  late RectangleHitbox _hitbox;
  final Timer _hitTimer = Timer(1);
  final Timer _duckTimer = Timer(1);
  bool isHit = false;

  // Weapon energy constants
  final double _energyPerShot = 1.0 / 4.0; // 4 shots to empty
  final double _chargeRate = 1.0 / 10.0; // 10 seconds to full charge
  final double _maxEnergy = 1.0;

  Dino(this.playerData) : super(size: Vector2.all(125), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Determine asset name based on selected skin
    String skinName = playerData.dinoSkin.toLowerCase();
    // Validate skin to avoid asset errors
    if (!['mort', 'doux', 'tard', 'vita'].contains(skinName)) {
      skinName = 'mort';
    }

    // Load the correct asset
    final image = await game.images.load('DinoSprites - $skinName.png');
    final spriteSheet = SpriteSheet(
      image: image,
      srcSize: Vector2.all(24),
    );

    // Create animations
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

    current = DinoAnimationStates.run;

    _hitbox = RectangleHitbox(
      position: Vector2(size.x * 0.25, size.y * 0.25),
      size: Vector2(size.x * 0.45, size.y * 0.55),
    );
    add(_hitbox);

    _hitTimer.onTick = () {
      current = DinoAnimationStates.run;
      isHit = false;
    };

    _duckTimer.onTick = () {
      // Restore hitbox
      _hitbox.size = Vector2(size.x * 0.6, size.y * 0.7);
      _hitbox.position = Vector2(size.x * 0.2, size.y * 0.2);
      current = DinoAnimationStates.run;
    };

    return super.onLoad();
  }

  @override
  void onMount() {
    super.onMount();
    // We set the ground level to be where the dino was initially placed.
    _groundY = y;
    _isLoaded = true;
  }

  void jump() {
    if (_isLoaded && y >= _groundY && !_duckTimer.isRunning()) {
      speedY = -583;
      current = DinoAnimationStates.idle;
      AudioManager.instance.playSfx('jump14.wav');
    }
  }

  void duck() {
    if (!_duckTimer.isRunning() && isOnGround) {
      _duckTimer.start();
      current = DinoAnimationStates.sprint; // Use sprint as duck/crouch
      // Lower hitbox
      _hitbox.size = Vector2(size.x * 0.6, size.y * 0.4);
      _hitbox.position = Vector2(size.x * 0.2, size.y * 0.5);
    }
  }

  void shoot() {
    // Check energy before shooting
    if (playerData.weaponEnergy >= _energyPerShot) {
      // Adjust spawn position to 'mouth' (approx right-center of dino)
      final bullet = Bullet(position: position.clone() + Vector2(size.x * 0.5, -size.y * 0.3));
      game.world.add(bullet);
      current = DinoAnimationStates.kick;

      // Decrease energy
      playerData.weaponEnergy = (playerData.weaponEnergy - _energyPerShot).clamp(0.0, _maxEnergy);
    }
  }

  bool get isOnGround => y >= _groundY;

  void hit() {
    if (!isHit) {
      isHit = true;
      AudioManager.instance.playSfx('hurt7.wav');
      current = DinoAnimationStates.hit;
      _hitTimer.start();
      playerData.lives -= 1;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Apply gravity
    speedY += gravity * dt;
    y += speedY * dt;

    if (_isLoaded && y > _groundY) {
      y = _groundY;
      speedY = 0.0;
      if ((current != DinoAnimationStates.hit) &&
          (current != DinoAnimationStates.run) &&
          !_duckTimer.isRunning()) {
        current = DinoAnimationStates.run;
      }
    }

    _hitTimer.update(dt);
    _duckTimer.update(dt);

    // Recharge weapon energy logic
    if (playerData.weaponEnergy < _maxEnergy) {
      playerData.weaponEnergy = (playerData.weaponEnergy + (_chargeRate * dt)).clamp(0.0, _maxEnergy);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Enemy) {
      hit();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
