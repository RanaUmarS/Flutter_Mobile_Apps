import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/dino_run.dart';
import 'hud.dart';

class MainMenu extends StatelessWidget {
  static const id = 'MainMenu';
  final DinoRun game;

  const MainMenu({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(20), // Reduced padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                const Color(0xFF1a1a2e).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFF00eeff),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00eeff).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [
                      Color(0xFF00eeff),
                      Color(0xFF0077ff),
                      Color(0xFF7700ff),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds);
                },
                child: Text(
                  'DINO RUN',
                  style: GoogleFonts.audiowide(
                    fontSize: 40, // Reduced font size
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [
                      const Shadow(
                        color: Color(0xFF00eeff),
                        blurRadius: 15,
                      ),
                    ],
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15), // Reduced spacing

              // Skin Selection
              Text(
                'Select Your Dino',
                style: GoogleFonts.vt323(
                  fontSize: 22,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Color(0xFF0077ff),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              ListenableBuilder(
                listenable: game.playerData,
                builder: (context, child) {
                  const skins = ['Mort', 'Doux', 'Tard', 'Vita'];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: skins.map((skin) {
                      final isSelected = game.playerData.dinoSkin == skin;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            game.playerData.dinoSkin = skin;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF00eeff).withValues(alpha: 0.2) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF00eeff) : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                ? [BoxShadow(color: const Color(0xFF00eeff).withValues(alpha: 0.4), blurRadius: 10)]
                                : [],
                            ),
                            child: Column(
                              children: [
                                Image.asset(
                                  'assets/images/DinoSprites_${skin.toLowerCase()}.gif',
                                  height: 45, // Reduced size
                                  width: 45,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error, color: Colors.white);
                                  },
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  skin,
                                  style: GoogleFonts.vt323(
                                    color: isSelected ? Colors.white : Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20), // Reduced spacing

              // Play Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    game.overlays.remove(MainMenu.id);
                    game.overlays.add(Hud.id);
                    game.startGamePlay();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00eeff), Color(0xFF0077ff)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00eeff).withValues(alpha: 0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      'PLAY',
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
