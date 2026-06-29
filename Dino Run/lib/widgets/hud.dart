import 'package:flutter/material.dart';
import '../game/dino_run.dart';
import 'pause_menu.dart';

class Hud extends StatelessWidget {
  static const id = 'Hud';
  final DinoRun game;

  const Hud({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Stack(
        children: [
          // Score and Lives
          Positioned(
            top: 10,
            left: 10,
            child: ListenableBuilder(
              listenable: game.playerData,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${game.playerData.currentScore}',
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < game.playerData.lives ? Icons.favorite : Icons.favorite_border,
                          color: Colors.red,
                          size: 30,
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    // Weapon Energy Bar
                    Row(
                      children: [
                         const Icon(Icons.flash_on, color: Colors.yellow, size: 24),
                        const SizedBox(width: 5),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 98 * game.playerData.weaponEnergy.clamp(0.0, 1.0),
                              height: 10,
                              decoration: BoxDecoration(
                                color: game.playerData.weaponEnergy >= 1.0
                                  ? Colors.yellowAccent
                                  : (game.playerData.weaponEnergy > 0.15 ? Colors.cyan : Colors.red),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          // Pause
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.pause, color: Colors.white, size: 30),
              onPressed: () {
                game.overlays.remove(Hud.id);
                game.overlays.add(PauseMenu.id);
                game.pauseEngine();
              },
            ),
          ),
          // Controls
          Positioned(
            bottom: 50,
            left: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Jump Button
                GestureDetector(
                  onTap: () => game.dino.jump(),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, size: 30, color: Colors.blueAccent),
                  ),
                ),
                // Duck Button
                GestureDetector(
                  onTapDown: (_) => game.dino.duck(), // Sit when pressed
                  // Note: Assuming duck() starts a timer, we might need a stopDuck logic if we want hold-to-duck.
                  // But current implementation uses a fixed timer in Dino.duck().
                  // The user asked for "interactive buttons for jump and duck".
                  // The provided Dino code has duck() with a timer.
                  // If we want hold behavior, we'd need to change Dino.
                  // For now, simple tap to duck is consistent with existing logic.
                  // But usually duck is hold. Let's stick to simple tap/call for now as requested by "interactive buttons".
                  // Wait, previous HUD used ElevatedButton. GestureDetector gives more control.
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_downward, size: 30, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 50,
            right: 30,
            child: GestureDetector(
              onTap: () => game.dino.shoot(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
