import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/dino_run.dart';
import 'hud.dart';
import 'main_menu.dart';

class GameOverMenu extends StatelessWidget {
  static const id = 'GameOverMenu';
  final DinoRun game;

  const GameOverMenu({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check/Update high score
    if (game.playerData.currentScore > game.playerData.highScore) {
      game.playerData.highScore = game.playerData.currentScore;
      game.playerData.save();
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.95),
                const Color(0xFF2e0000).withValues(alpha: 0.95), // Red tint for Game Over
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFFff0000),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFff0000).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              const Positioned(
                right: -50,
                top: -50,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 200,
                    color: Colors.red,
                  ),
                ),
              ),

              // Main content
              Center(
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(5),
                  thickness: 8,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                  ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFFff0000),
                          Color(0xFFff5500),
                          Color(0xFFffaa00),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'GAME OVER',
                      style: GoogleFonts.audiowide(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [
                          const Shadow(
                            color: Color(0xFFff0000),
                            blurRadius: 15,
                          ),
                        ],
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Score Display
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'YOUR SCORE',
                          style: GoogleFonts.orbitron(
                            fontSize: 14,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${game.playerData.currentScore}',
                          style: GoogleFonts.audiowide(
                            fontSize: 40,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 20),
                        Text(
                          'HIGH SCORE: ${game.playerData.highScore}',
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            color: const Color(0xFFffaa00),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Menu Options
                  _buildMenuOption(
                    icon: Icons.replay_rounded,
                    label: 'TRY AGAIN',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff9900), Color(0xFFff5500)],
                    ),
                    onTap: () {
                      game.overlays.remove(GameOverMenu.id);
                      game.overlays.add(Hud.id);
                      game.resumeEngine();
                      game.reset();
                      game.startGamePlay();
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildMenuOption(
                    icon: Icons.home_rounded,
                    label: 'MAIN MENU',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFff3366), Color(0xFFff0066)],
                    ),
                    onTap: () {
                      game.overlays.remove(GameOverMenu.id);
                      game.resumeEngine();
                      game.reset();
                      game.overlays.add(MainMenu.id);
                    },
                  ),
                    ],
                  ),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 15),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 3,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
