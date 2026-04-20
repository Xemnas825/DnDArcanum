import 'package:hive_flutter/hive_flutter.dart';

class LocalDb {
  static const charactersBoxName = 'characters';
  static const metaBoxName = 'meta';

  static late Box<String> characters;
  static late Box meta;

  static Future<void> init() async {
    await Hive.initFlutter();
    characters = await Hive.openBox<String>(charactersBoxName);
    meta = await Hive.openBox(metaBoxName);
  }
}

