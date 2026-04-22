import 'dart:convert';
import 'dart:async';

import '../cloud/cloud_characters_sync.dart';
import '../data/dummy_character.dart';
import '../models/character.dart';
import '../utils/uid.dart';
import 'characters_repository.dart';
import 'local_db.dart';

class HiveCharactersRepository implements CharactersRepository {
  static const _lastActiveKey = 'lastActiveCharacterId';
  static const _schemaVersionKey = 'schemaVersion';
  static const _schemaVersion = 1;
  static const _updatedAtPrefix = 'characterUpdatedAtMs:';

  final CloudCharactersSync _cloud = CloudCharactersSync();

  @override
  Future<List<Character>> list() async {
    final chars = <Character>[];
    for (final entry in LocalDb.characters.toMap().entries) {
      final id = entry.key.toString();
      final raw = entry.value;
      final c = _decodeCharacter(raw, fallbackId: id);
      chars.add(c);
    }
    chars.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return chars;
  }

  @override
  Future<Character> get(String id) async {
    final raw = LocalDb.characters.get(id);
    if (raw == null || raw.trim().isEmpty) {
      final created = await createFromTemplate();
      return created;
    }
    return _decodeCharacter(raw, fallbackId: id);
  }

  @override
  Future<void> upsert(Character character) async {
    final id = character.id.isEmpty ? uid(12) : character.id;
    final fixed = character.id.isEmpty
        ? Character(
            id: id,
            name: character.name,
            race: character.race,
            characterClass: character.characterClass,
            level: character.level,
            hp: character.hp,
            ac: character.ac,
            speed: character.speed,
            coins: character.coins,
            abilities: character.abilities,
            proficiencyBonus: character.proficiencyBonus,
            skills: character.skills,
            weapons: character.weapons,
            spells: character.spells,
            items: character.items,
            extras: character.extras,
            traits: character.traits,
            effects: character.effects,
          )
        : character;
    await LocalDb.characters.put(id, jsonEncode(fixed.toJson()));
    final now = DateTime.now().millisecondsSinceEpoch;
    await LocalDb.meta.put('$_updatedAtPrefix$id', now);
    // Best-effort cloud sync; never block local save.
    unawaited(_cloud.upsert(fixed, updatedAtMs: now).catchError((_) {}));
    await _ensureSchema();
  }

  @override
  Future<void> delete(String id) async {
    await LocalDb.characters.delete(id);
    final now = DateTime.now().millisecondsSinceEpoch;
    await LocalDb.meta.put('$_updatedAtPrefix$id', now);
    // Best-effort: mark as deleted so other devices remove it.
    unawaited(_cloud.tombstone(id, updatedAtMs: now).catchError((_) {}));
  }

  @override
  Future<String?> getLastActiveId() async {
    final v = LocalDb.meta.get(_lastActiveKey);
    return v is String ? v : null;
  }

  @override
  Future<void> setLastActiveId(String id) async {
    await LocalDb.meta.put(_lastActiveKey, id);
  }

  @override
  Future<Character> createBlank() async {
    final id = uid(12);
    final c = Character(
      id: id,
      name: 'Nuevo personaje',
      race: '',
      characterClass: '',
      level: 1,
      hp: Hp(current: 10, max: 10),
      ac: 10,
      speed: 30,
      coins: Coins(pp: 0, gp: 0, sp: 0, cp: 0),
      abilities: AbilityScores(str: 10, dex: 10, con: 10, intl: 10, wis: 10, cha: 10),
      proficiencyBonus: 2,
      skills: const [],
      weapons: const [],
      spells: const [],
      items: const [],
      extras: const [],
      traits: const [],
      effects: const [],
    );
    await upsert(c);
    return c;
  }

  @override
  Future<Character> createFromTemplate() async {
    final id = uid(12);
    final c = Character(
      id: id,
      name: dummyCharacter.name,
      race: dummyCharacter.race,
      characterClass: dummyCharacter.characterClass,
      level: dummyCharacter.level,
      hp: dummyCharacter.hp,
      ac: dummyCharacter.ac,
      speed: dummyCharacter.speed,
      coins: dummyCharacter.coins,
      abilities: dummyCharacter.abilities,
      proficiencyBonus: dummyCharacter.proficiencyBonus,
      skills: dummyCharacter.skills,
      weapons: dummyCharacter.weapons,
      spells: dummyCharacter.spells,
      items: dummyCharacter.items,
      extras: dummyCharacter.extras,
      traits: dummyCharacter.traits,
      effects: dummyCharacter.effects,
    );
    await upsert(c);
    return c;
  }

  @override
  Future<Character> resetToTemplate(String id) async {
    final c = Character(
      id: id,
      name: dummyCharacter.name,
      race: dummyCharacter.race,
      characterClass: dummyCharacter.characterClass,
      level: dummyCharacter.level,
      hp: dummyCharacter.hp,
      ac: dummyCharacter.ac,
      speed: dummyCharacter.speed,
      coins: dummyCharacter.coins,
      abilities: dummyCharacter.abilities,
      proficiencyBonus: dummyCharacter.proficiencyBonus,
      skills: dummyCharacter.skills,
      weapons: dummyCharacter.weapons,
      spells: dummyCharacter.spells,
      items: dummyCharacter.items,
      extras: dummyCharacter.extras,
      traits: dummyCharacter.traits,
      effects: dummyCharacter.effects,
    );
    await upsert(c);
    return c;
  }

  @override
  Future<Character> duplicate(String id) async {
    final c = await get(id);
    final next = Character(
      id: uid(12),
      name: '${c.name} (copia)',
      race: c.race,
      characterClass: c.characterClass,
      level: c.level,
      hp: c.hp,
      ac: c.ac,
      speed: c.speed,
      coins: c.coins,
      abilities: c.abilities,
      proficiencyBonus: c.proficiencyBonus,
      skills: c.skills,
      weapons: c.weapons,
      spells: c.spells,
      items: c.items,
      extras: c.extras,
      traits: c.traits,
      effects: c.effects,
    );
    await upsert(next);
    return next;
  }

  @override
  Future<String> exportAllToJson() async {
    final all = await list();
    final payload = <String, dynamic>{
      'schemaVersion': _schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'characters': all.map((c) => c.toJson()).toList(),
      'lastActiveId': await getLastActiveId(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  @override
  Future<void> importFromJson(String json, {required bool replace}) async {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) return;
    final chars = decoded['characters'];
    if (chars is! List) return;

    if (replace) {
      await LocalDb.characters.clear();
    }

    for (final item in chars) {
      if (item is! Map) continue;
      final c = Character.fromJson(item.cast<String, dynamic>());
      final fixed = c.id.isEmpty ? _withId(c, uid(12)) : c;
      await upsert(fixed);
    }

    final last = decoded['lastActiveId'];
    if (last is String && last.isNotEmpty) {
      await setLastActiveId(last);
    }
    await _ensureSchema();
  }

  int localUpdatedAtMs(String id) {
    final v = LocalDb.meta.get('$_updatedAtPrefix$id');
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  Future<void> pullFromCloudAndMerge() async {
    final remote = await _cloud.listRemote();
    for (final doc in remote) {
      final id = doc['id'];
      if (id is! String || id.isEmpty) continue;

      final updatedAt = doc['updatedAtMs'];
      final updatedAtMs = updatedAt is num ? updatedAt.toInt() : 0;
      if (updatedAtMs <= localUpdatedAtMs(id)) continue;

      final deleted = doc['deleted'] == true;
      if (deleted) {
        await LocalDb.characters.delete(id);
        await LocalDb.meta.put('$_updatedAtPrefix$id', updatedAtMs);
        continue;
      }

      final payload = doc['character'];
      if (payload is! Map) continue;
      final c = Character.fromJson(payload.cast<String, dynamic>());
      final fixed = c.id.isEmpty ? _withId(c, id) : c;
      await LocalDb.characters.put(id, jsonEncode(fixed.toJson()));
      await LocalDb.meta.put('$_updatedAtPrefix$id', updatedAtMs);
    }
  }

  Future<void> pushAllToCloud() async {
    final entries = LocalDb.characters.toMap().entries;
    for (final entry in entries) {
      final id = entry.key.toString();
      final raw = entry.value;
      final c = _decodeCharacter(raw, fallbackId: id);
      final updatedAtMs = localUpdatedAtMs(id);
      final stamp = updatedAtMs == 0 ? DateTime.now().millisecondsSinceEpoch : updatedAtMs;
      await _cloud.upsert(c, updatedAtMs: stamp);
      if (updatedAtMs == 0) {
        await LocalDb.meta.put('$_updatedAtPrefix$id', stamp);
      }
    }
  }

  /// Pulls remote changes, then pushes local state (best effort "sync now").
  Future<void> syncNow() async {
    await pullFromCloudAndMerge();
    await pushAllToCloud();
  }

  Character _decodeCharacter(String raw, {required String fallbackId}) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return _withId(dummyCharacter, fallbackId);
      final c = Character.fromJson(decoded);
      final fixed = c.id.isEmpty ? _withId(c, fallbackId) : c;
      return fixed;
    } catch (_) {
      return _withId(dummyCharacter, fallbackId);
    }
  }

  Character _withId(Character c, String id) => Character(
        id: id,
        name: c.name,
        race: c.race,
        characterClass: c.characterClass,
        level: c.level,
        hp: c.hp,
        ac: c.ac,
        speed: c.speed,
        coins: c.coins,
        abilities: c.abilities,
        proficiencyBonus: c.proficiencyBonus,
        skills: c.skills,
        weapons: c.weapons,
        spells: c.spells,
        items: c.items,
        extras: c.extras,
        traits: c.traits,
        effects: c.effects,
      );

  Future<void> _ensureSchema() async {
    final current = LocalDb.meta.get(_schemaVersionKey);
    if (current is int && current >= _schemaVersion) return;
    await LocalDb.meta.put(_schemaVersionKey, _schemaVersion);
  }
}

