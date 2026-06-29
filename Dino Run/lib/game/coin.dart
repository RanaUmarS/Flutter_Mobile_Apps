import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'dino_run.dart';
import 'dino.dart';


class Coin extends SpriteAnimationComponent with CollisionCallbacks, HasGameReference<DinoRun> {

  Coin({required Vector2 position})
      : super(size: Vector2.all(40), position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final image = await game.images.load('Coins/coin2_20x20.png');
    animation = SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.sequenced(
        amount: 6, // Assuming 6 frames for the coin
        stepTime: 0.1,
        textureSize: Vector2.all(20),
      ),
    );
    add(CircleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Move same speed as world/enemies
    position.x -= (game.virtualSize.x / 2) * dt * 0.5;

    if (position.x < -50) {
      removeFromParent();
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Dino) {
      game.playerData.currentScore += 10;
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
