import 'dart:math';
import 'package:flame/components.dart';
import 'dino_run.dart';
import 'enemy.dart';

class EnemyManager extends Component with HasGameReference<DinoRun> {
  final Random _random = Random();
  final Timer _timer = Timer(2, repeat: true);

  EnemyManager() {
    _timer.onTick = spawnRandomEnemy;
    _timer.start();
  }

  void spawnRandomEnemy() {
    final enemyTypeId = _random.nextInt(3);
    final enemyData = _enemyTypes[enemyTypeId];

    // Calculate difficulty multiplier based on Score
    // e.g. every 50 points, increase speed by 10%
    int currentScore = game.playerData.currentScore;
    double difficultyFactor = 1.0 + (currentScore / 500.0); // 500 score = 2x speed

    final enemy = Enemy(enemyData);
    enemy.speedMultiplier = difficultyFactor;
    game.world.add(enemy);

    _timer.stop();

    // Decrease spawn interval as score increases
    // Minimum spawn time clamps at 0.5s
    double minSpawn = max(0.5, 1.5 - (currentScore / 1000.0));
    double maxSpawn = max(1.0, 3.0 - (currentScore / 1000.0));

    _timer.limit = minSpawn + _random.nextDouble() * (maxSpawn - minSpawn);
    _timer.start();
  }

  @override
  void update(double dt) {
    _timer.update(dt);
    super.update(dt);
  }

  void removeAllEnemies() {
    game.world.children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
  }

  static final List<EnemyData> _enemyTypes = [
    EnemyData(
      imageName: 'AngryPig/Walk (36x30).png',
      nFrames: 16,
      textureSize: Vector2(36, 30),
      canFly: false,
      speedX: 300.0,
    ),
    EnemyData(
      imageName: 'Bat/Flying (46x30).png',
      nFrames: 7,
      textureSize: Vector2(46, 30),
      canFly: true,
      speedX: 350.0,
    ),
    EnemyData(
      imageName: 'Rino/Run (52x34).png',
      nFrames: 6,
      textureSize: Vector2(52, 34),
      canFly: false,
      speedX: 450.0, // Rino is faster
    ),
  ];
}
