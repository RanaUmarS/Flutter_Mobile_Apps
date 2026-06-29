import '../models/settings.dart';
import 'package:flame_audio/flame_audio.dart';

class AudioManager {
  AudioManager._internal();
  static final AudioManager instance = AudioManager._internal();

  late Settings settings;
  String? _currentBgm;

  Future<void> init(List<String> files, Settings settings) async {
    this.settings = settings;
    FlameAudio.bgm.initialize();
    await FlameAudio.audioCache.loadAll(files);
  }

  void startBgm(String fileName) {
    _currentBgm = fileName;
    if (settings.bgm) {
      // Ensure we stop any paused or playing music before starting fresh
      try {
        FlameAudio.bgm.stop();
      } catch (e) {
        // Ignore error if not playing
      }
      FlameAudio.bgm.play(fileName);
    }
  }

  void pauseBgm() {
    FlameAudio.bgm.pause();
  }

  void playSfx(String fileName) {
    if (settings.sfx) {
      FlameAudio.play(fileName);
    }
  }

  void setBgm(bool isEnabled) {
    settings.bgm = isEnabled;
    settings.save();
    if (isEnabled) {
      if (_currentBgm != null) {
        FlameAudio.bgm.play(_currentBgm!);
      }
    } else {
      FlameAudio.bgm.pause();
    }
  }

  void setSfx(bool isEnabled) {
    settings.sfx = isEnabled;
    settings.save();
  }
}
