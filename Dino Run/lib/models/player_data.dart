import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class PlayerData extends HiveObject with ChangeNotifier {
  int _lives;
  int _currentScore;
  int highScore;

  // Skin selection (defaults to Mort)
  String _dinoSkin;

  // Weapon Energy (0.0 to 1.0) - 1.0 is full, 0.0 is empty
  double _weaponEnergy;

  PlayerData({
    int lives = 5,
    int currentScore = 0,
    this.highScore = 0,
    String dinoSkin = 'Mort',
    double weaponEnergy = 1.0, // Start full
  }) : _lives = lives,
       _currentScore = currentScore,
       _dinoSkin = dinoSkin,
       _weaponEnergy = weaponEnergy;

  int get lives => _lives;
  set lives(int value) {
    _lives = value;
    notifyListeners();
  }

  int get currentScore => _currentScore;
  set currentScore(int value) {
    _currentScore = value;
    notifyListeners();
  }

  String get dinoSkin => _dinoSkin;
  set dinoSkin(String value) {
    _dinoSkin = value;
    notifyListeners();
  }

  double get weaponHeat => _weaponEnergy; // keeping getter name for compatibility if needed, but logic is changed
  set weaponHeat(double value) {
    _weaponEnergy = value;
    notifyListeners();
  }

  // Proper named getter/setter for new logic
   double get weaponEnergy => _weaponEnergy;
  set weaponEnergy(double value) {
    _weaponEnergy = value;
    notifyListeners();
  }
}

class PlayerDataAdapter extends TypeAdapter<PlayerData> {
  @override
  final int typeId = 0;

  @override
  PlayerData read(BinaryReader reader) {
    return PlayerData(
      lives: reader.readInt(),
      currentScore: reader.readInt(),
      highScore: reader.readInt(),
      dinoSkin: reader.readString(), // Read skin
      // weaponEnergy transient
    );
  }

  @override
  void write(BinaryWriter writer, PlayerData obj) {
    writer.writeInt(obj.lives);
    writer.writeInt(obj.currentScore);
    writer.writeInt(obj.highScore);
    writer.writeString(obj.dinoSkin); // Write skin
  }
}
