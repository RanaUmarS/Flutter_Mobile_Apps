import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'enemy.dart';

import 'game.dart';
import 'dino_run.dart';

class Bullet extends SpriteComponent with CollisionCallbacks, HasGameReference<DinoRun> {
  final double speed = 500;

  Bullet({required Vector2 position})
      : super(size: Vector2(38, 24), position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('Fire/Fireball.png');
    // Reduced hitbox size: 0.6 means 60% of the sprite size
    add(RectangleHitbox.relative(Vector2(0.6, 0.6), parentSize: size));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    position.x += speed * dt;
    if (position.x > 3000) {
      removeFromParent();
    }
    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Enemy) {
      other.removeFromParent();
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
