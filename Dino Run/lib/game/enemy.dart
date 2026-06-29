import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/sprite.dart';
import 'dino_run.dart';

class Enemy extends SpriteAnimationComponent with HasGameReference<DinoRun> {
  final EnemyData enemyData;
  double speedMultiplier = 1.0;

  Enemy(this.enemyData) : super(size: enemyData.textureSize);

  @override
  Future<void> onLoad() async {
    final image = await game.images.load(enemyData.imageName);

    // Scale up specific enemies
    double scaleFactor = 1.5;
    if (enemyData.imageName.contains('AngryPig') || enemyData.imageName.contains('Rino')) {
      scaleFactor = 1.8; // Larger for Pig and Rino
    }

    size = enemyData.textureSize * scaleFactor;

    animation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: enemyData.nFrames,
        stepTime: 0.1,
        textureSize: enemyData.textureSize,
      ),
    );

    // Calculate Y based on the scaled size
    // Anchor is BottomLeft, so position.y defines the bottom edge.
    // We want the bottom edge to be near the ground.
    position = Vector2(
        game.virtualSize.x + 100, game.virtualSize.y - 20);

    if(!enemyData.canFly) {
      position.y -= 28; // Adjust for ground
    } else {
      position.y -= 100; // Fly higher
    }

    anchor = Anchor.bottomLeft;

    add(RectangleHitbox());

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Calculate speed based on enemyData and multiplier
    // Score based difficulty scaling is passed via multiplier

    // Base formula was: (game.virtualSize.x / 2) * dt * 0.605
    // Adjusted to use explicit speed:
    position.x -= enemyData.speedX * speedMultiplier * dt;

    // Remove if off screen
    if (position.x < -enemyData.textureSize.x) {
      removeFromParent();
    }

    super.update(dt);
  }
}

class EnemyData {
  final String imageName;
  final Vector2 textureSize;
  final int nFrames;
  final bool canFly;
  final double speedX; // Added speed property

  const EnemyData({
    required this.imageName,
    required this.textureSize,
    required this.nFrames,
    required this.canFly,
    this.speedX = 300.0, // Default speed
  });
}
