import '../models/character.dart';

abstract class CharactersRepository {
  Future<List<Character>> list();
  Future<Character> get(String id);
  Future<void> upsert(Character character);
  Future<void> delete(String id);

  Future<String?> getLastActiveId();
  Future<void> setLastActiveId(String id);

  Future<Character> createBlank();
  Future<Character> createFromTemplate();
  Future<Character> resetToTemplate(String id);
  Future<Character> duplicate(String id);

  Future<String> exportAllToJson();
  Future<void> importFromJson(String json, {required bool replace});
}

