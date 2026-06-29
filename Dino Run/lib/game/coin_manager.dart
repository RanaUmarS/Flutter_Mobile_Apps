import 'dart:math';
import 'package:flame/components.dart';
import 'dino_run.dart';
import 'coin.dart';

class CoinManager extends Component with HasGameReference<DinoRun> {
  final Random _random = Random();
  final Timer _timer = Timer(3, repeat: true);

  CoinManager() {
    _timer.onTick = spawnCoin;
    _timer.start();
  }

  void spawnCoin() {
    try {
      // Ground is at game.virtualSize.y - 50
      final double groundY = game.virtualSize.y - 50;
      // Spawn coins between ground level and max jump height
      // Adjusted: -10 to spawn lower coins collectable by ducking
      final double yPos = groundY - 10 - _random.nextDouble() * 140;
      final double xPos = game.virtualSize.x + 50;

      game.world.add(Coin(position: Vector2(xPos, yPos)));

      _timer.stop();
      _timer.limit = 1 + _random.nextDouble() * 4;
      _timer.start();
    } catch(e) {
      print(e);
    }
  }

  @override
  void update(double dt) {
    _timer.update(dt);
    super.update(dt);
  }

  void removeAllCoins() {
    game.world.children.whereType<Coin>().forEach((coin) => coin.removeFromParent());
  }
}
