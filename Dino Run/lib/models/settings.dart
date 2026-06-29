import 'package:hive/hive.dart';

class Settings extends HiveObject {
  bool bgm;
  bool sfx;

  Settings({this.bgm = true, this.sfx = true});
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 1;

  @override
  Settings read(BinaryReader reader) {
    return Settings(
      bgm: reader.readBool(),
      sfx: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer.writeBool(obj.bgm);
    writer.writeBool(obj.sfx);
  }
}
