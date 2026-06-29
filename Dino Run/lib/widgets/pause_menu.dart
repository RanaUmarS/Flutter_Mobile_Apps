import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/dino_run.dart';
import 'hud.dart';
import '../game/audio_manager.dart';
import 'main_menu.dart';

class PauseMenu extends StatefulWidget {
  static const id = 'PauseMenu';
  final DinoRun game;

  const PauseMenu({Key? key, required this.game}) : super(key: key);

  @override
  State<PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<PauseMenu> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.78,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.95),
                const Color(0xFF1a1a2e).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: const Color(0xFF00eeff),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00eeff).withOpacity(0.3),
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
                    Icons.games_rounded,
                    size: 200,
                    color: Colors.white,
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
                          Color(0xFF00eeff),
                          Color(0xFF0077ff),
                          Color(0xFF7700ff),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'GAME PAUSED',
                      style: GoogleFonts.audiowide(
                        fontSize: 48,
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

                  const SizedBox(height: 10),

                  Text(
                    'The adventure awaits...',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 50),

                      // Audio Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Music Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: widget.game.settings.bgm ? const Color(0xFF00eeff) : Colors.grey,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                widget.game.settings.bgm ? Icons.music_note : Icons.music_off,
                                color: widget.game.settings.bgm ? const Color(0xFF00eeff) : Colors.grey,
                              ),
                              onPressed: () {
                                 AudioManager.instance.setBgm(!widget.game.settings.bgm);
                                 setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          // SFX Toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: widget.game.settings.sfx ? const Color(0xFF00eeff) : Colors.grey,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                widget.game.settings.sfx ? Icons.volume_up : Icons.volume_off,
                                color: widget.game.settings.sfx ? const Color(0xFF00eeff) : Colors.grey,
                              ),
                              onPressed: () {
                                 AudioManager.instance.setSfx(!widget.game.settings.sfx);
                                 setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),

                  const SizedBox(height: 50),

                  // Menu Options
                      _buildMenuOption(
                        icon: Icons.play_arrow_rounded,
                        label: 'RESUME',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00eeff), Color(0xFF0077ff)],
                        ),
                        onTap: () {
                          widget.game.overlays.remove(PauseMenu.id);
                          widget.game.overlays.add(Hud.id);
                          widget.game.resumeEngine();
                        },
                      ),

                      const SizedBox(height: 25),

                      _buildMenuOption(
                        icon: Icons.replay_rounded,
                        label: 'RESTART',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff9900), Color(0xFFff5500)],
                        ),
                        onTap: () {
                          widget.game.overlays.remove(PauseMenu.id);
                          widget.game.overlays.add(Hud.id);
                          widget.game.resumeEngine();
                          widget.game.reset();
                          widget.game.startGamePlay();
                        },
                      ),

                      const SizedBox(height: 25),

                      _buildMenuOption(
                        icon: Icons.home_rounded,
                        label: 'MAIN MENU',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFff3366), Color(0xFFff0066)],
                        ),
                        onTap: () {
                          widget.game.overlays.remove(PauseMenu.id);
                          widget.game.resumeEngine();
                          widget.game.reset();
                          widget.game.overlays.add(MainMenu.id);
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
                color: gradient.colors.first.withValues(alpha: 0.5),
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
