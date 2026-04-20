import 'package:flutter/foundation.dart';

import '../models/character.dart';
import '../storage/characters_repository.dart';
import '../utils/uid.dart';

class CharacterController extends ChangeNotifier {
  CharacterController(this._repo);

  final CharactersRepository _repo;

  Character? _character;
  List<Character> _characters = const [];
  String? _activeId;
  bool _loading = true;

  bool get loading => _loading;
  Character? get character => _character;
  List<Character> get characters => _characters;
  String? get activeCharacterId => _activeId;

  int _sumEquippedItemModifiers(String stat) => (_character?.items ?? const [])
      .where((i) => i.equippable == true && i.equipped == true)
      .fold<int>(0, (s, i) {
        final mods = i.modifiers;
        if (mods != null && mods.isNotEmpty) {
          return s +
              mods
                  .where((m) => m.enabled && m.stat == stat)
                  .fold<int>(0, (ss, m) => ss + m.value);
        }
        // legacy fallback
        if (stat == 'ac') return s + (i.acBonus ?? 0);
        if (stat == 'speed') return s + (i.speedBonus ?? 0);
        return s;
      });

  int _sumActiveEffects(String stat) => (_character?.effects ?? const [])
      .where((e) => e.active && e.stat == stat)
      .fold<int>(0, (s, e) => s + e.value);

  int effectiveStat(String stat) => _sumEquippedItemModifiers(stat) + _sumActiveEffects(stat);

  int get effectiveAc =>
      (_character?.ac ?? 10) + _sumEquippedItemModifiers('ac') + _sumActiveEffects('ac');

  int get effectiveSpeed => (_character?.speed ?? 30) +
      _sumEquippedItemModifiers('speed') +
      _sumActiveEffects('speed');

  int get effectiveHpMax =>
      (_character?.hp.max ?? 0) + _sumEquippedItemModifiers('hpMax') + _sumActiveEffects('hpMax');

  int get effectiveAttackMod => effectiveStat('attack');
  int get effectiveDamageMod => effectiveStat('damage');
  int get effectiveSaveMod => effectiveStat('save');

  double get totalWeight => (_character?.items ?? const [])
      .fold<double>(0, (s, i) => s + (i.weight * i.quantity));

  Future<void> init() async {
    _characters = await _repo.list();
    _activeId = await _repo.getLastActiveId();

    if (_characters.isEmpty) {
      final created = await _repo.createFromTemplate();
      _characters = [created];
      _activeId = created.id;
      await _repo.setLastActiveId(created.id);
    }

    final id = _activeId ?? _characters.first.id;
    _character = _normalize(await _repo.get(id));
    _activeId = id;
    _loading = false;
    notifyListeners();
  }

  Future<void> reset() async {
    final id = _activeId;
    if (id == null) return;
    final resetChar = await _repo.resetToTemplate(id);
    _character = _normalize(resetChar);
    _characters = await _repo.list();
    notifyListeners();
  }

  Character _rebuild(
    Character c, {
    String? name,
    String? race,
    String? characterClass,
    int? level,
    Hp? hp,
    int? ac,
    int? speed,
    Coins? coins,
    AbilityScores? abilities,
    int? proficiencyBonus,
    List<SkillProficiency>? skills,
    List<Weapon>? weapons,
    List<Spell>? spells,
    List<Item>? items,
    List<Extra>? extras,
    List<Trait>? traits,
    List<ActiveEffect>? effects,
  }) {
    return Character(
      id: c.id.isEmpty ? uid(12) : c.id,
      name: name ?? c.name,
      race: race ?? c.race,
      characterClass: characterClass ?? c.characterClass,
      level: level ?? c.level,
      hp: hp ?? c.hp,
      ac: ac ?? c.ac,
      speed: speed ?? c.speed,
      coins: coins ?? c.coins,
      abilities: abilities ?? c.abilities,
      proficiencyBonus: proficiencyBonus ?? c.proficiencyBonus,
      skills: skills ?? c.skills,
      weapons: weapons ?? c.weapons,
      spells: spells ?? c.spells,
      items: items ?? c.items,
      extras: extras ?? c.extras,
      traits: traits ?? c.traits,
      effects: effects ?? c.effects,
    );
  }

  Future<void> _set(Character next) async {
    _character = _normalize(next);
    notifyListeners();
    await _repo.upsert(_character!);
    _characters = await _repo.list();
  }

  Character _normalize(Character c) {
    final max = c.hp.max +
        c.effects
            .where((e) => e.active && e.stat == 'hpMax')
            .fold<int>(0, (s, e) => s + e.value);
    final clampedCurrent = c.hp.current > max ? max : c.hp.current;
    return _rebuild(
      c,
      hp: Hp(current: clampedCurrent, max: c.hp.max),
    );
  }

  Future<void> applyHpDelta(int delta) async {
    final c = _character!;
    final max = effectiveHpMax;
    final next = (c.hp.current + delta).clamp(0, max);
    await _set(_rebuild(c, hp: Hp(current: next, max: c.hp.max)));
  }

  Future<void> updateCoins(Coins coins) async {
    final c = _character!;
    await _set(_rebuild(c, coins: coins));
  }

  Future<void> updateBasics({
    required String name,
    required String race,
    required String characterClass,
    required int level,
    required int ac,
    required int speed,
    required int hpCurrent,
    required int hpMax,
  }) async {
    final c = _character!;
    await _set(
      _rebuild(
        c,
        name: name,
        race: race,
        characterClass: characterClass,
        level: level,
        ac: ac,
        speed: speed,
        hp: Hp(current: hpCurrent, max: hpMax),
      ),
    );
  }

  Future<void> updateAbilities(AbilityScores abilities) async {
    final c = _character!;
    await _set(_rebuild(c, abilities: abilities));
  }

  Future<void> updateProficiencyBonus(int pb) async {
    final c = _character!;
    await _set(_rebuild(c, proficiencyBonus: pb));
  }

  Future<void> upsertSkill(SkillProficiency s) async {
    final c = _character!;
    final exists = c.skills.any((x) => x.key == s.key);
    final next = exists
        ? c.skills.map((x) => x.key == s.key ? s : x).toList()
        : [...c.skills, s];
    await _set(_rebuild(c, skills: next));
  }

  // ===== Characters (multi) =====
  Future<void> createNewBlank() async {
    final created = await _repo.createBlank();
    _characters = await _repo.list();
    await selectCharacter(created.id);
  }

  Future<void> duplicateCharacter(String id) async {
    final created = await _repo.duplicate(id);
    _characters = await _repo.list();
    await selectCharacter(created.id);
  }

  Future<void> deleteCharacter(String id) async {
    await _repo.delete(id);
    _characters = await _repo.list();
    if (_characters.isEmpty) {
      final created = await _repo.createFromTemplate();
      _characters = [created];
      _activeId = created.id;
      _character = _normalize(created);
      await _repo.setLastActiveId(created.id);
      notifyListeners();
      return;
    }

    if (_activeId == id) {
      final nextId = _characters.first.id;
      await selectCharacter(nextId);
    } else {
      notifyListeners();
    }
  }

  Future<void> renameCharacter(String id, String name) async {
    final c = await _repo.get(id);
    await _repo.upsert(_rebuild(c, name: name));
    _characters = await _repo.list();
    if (_activeId == id) _character = _normalize(await _repo.get(id));
    notifyListeners();
  }

  Future<void> selectCharacter(String id) async {
    _activeId = id;
    await _repo.setLastActiveId(id);
    _character = _normalize(await _repo.get(id));
    notifyListeners();
  }

  // ===== Backup =====
  Future<String> exportAllToJson() => _repo.exportAllToJson();
  Future<void> importFromJson(String json, {required bool replace}) async {
    await _repo.importFromJson(json, replace: replace);
    _characters = await _repo.list();
    if (_characters.isNotEmpty) {
      final nextId = await _repo.getLastActiveId() ?? _characters.first.id;
      await selectCharacter(nextId);
    } else {
      final created = await _repo.createFromTemplate();
      _characters = [created];
      await selectCharacter(created.id);
    }
  }

  // ===== Weapons =====
  Future<void> upsertWeapon(Weapon w) async {
    final c = _character!;
    final exists = c.weapons.any((x) => x.id == w.id);
    final nextWeapons =
        exists ? c.weapons.map((x) => x.id == w.id ? w : x).toList() : [...c.weapons, w];
    await _set(_rebuild(c, weapons: nextWeapons));
  }

  Future<void> deleteWeapon(String id) async {
    final c = _character!;
    await _set(_rebuild(c, weapons: c.weapons.where((w) => w.id != id).toList()));
  }

  // ===== Spells =====
  Future<void> upsertSpell(Spell s) async {
    final c = _character!;
    final exists = c.spells.any((x) => x.id == s.id);
    final nextSpells =
        exists ? c.spells.map((x) => x.id == s.id ? s : x).toList() : [...c.spells, s];
    await _set(_rebuild(c, spells: nextSpells));
  }

  Future<void> deleteSpell(String id) async {
    final c = _character!;
    await _set(_rebuild(c, spells: c.spells.where((s) => s.id != id).toList()));
  }

  Future<void> adjustSpellSlots(String id, int delta) async {
    final c = _character!;
    final nextSpells = c.spells
        .map((s) => s.id == id
            ? Spell(
                id: s.id,
                name: s.name,
                level: s.level,
                school: s.school,
                castingTime: s.castingTime,
                range: s.range,
                components: s.components,
                duration: s.duration,
                damageDice: s.damageDice,
                description: s.description,
                slotsUsed: (s.slotsUsed + delta).clamp(0, 999999),
              )
            : s)
        .toList();
    await _set(_rebuild(c, spells: nextSpells));
  }

  // ===== Items =====
  Future<void> upsertItem(Item i) async {
    final c = _character!;
    final exists = c.items.any((x) => x.id == i.id);
    final nextItems =
        exists ? c.items.map((x) => x.id == i.id ? i : x).toList() : [...c.items, i];
    await _set(_rebuild(c, items: nextItems));
  }

  Future<void> deleteItem(String id) async {
    final c = _character!;
    await _set(_rebuild(c, items: c.items.where((i) => i.id != id).toList()));
  }

  Future<void> adjustItemQty(String id, int delta) async {
    final c = _character!;
    final nextItems = c.items
        .map((i) => i.id == id
            ? Item(
                id: i.id,
                name: i.name,
                quantity: (i.quantity + delta).clamp(0, 999999),
                weight: i.weight,
                description: i.description,
                charges: i.charges,
                recharge: i.recharge,
                equippable: i.equippable,
                equipped: i.equipped,
                acBonus: i.acBonus,
                speedBonus: i.speedBonus,
                effects: i.effects,
              )
            : i)
        .toList();
    await _set(_rebuild(c, items: nextItems));
  }

  Future<void> adjustItemCharges(String id, int delta) async {
    final c = _character!;
    final nextItems = c.items.map((i) {
      if (i.id != id || i.charges == null) return i;
      final next = (i.charges!.current + delta).clamp(0, i.charges!.max);
      return Item(
        id: i.id,
        name: i.name,
        quantity: i.quantity,
        weight: i.weight,
        description: i.description,
        charges: Charges(current: next, max: i.charges!.max),
        recharge: i.recharge,
        equippable: i.equippable,
        equipped: i.equipped,
        acBonus: i.acBonus,
        speedBonus: i.speedBonus,
        effects: i.effects,
      );
    }).toList();
    await _set(_rebuild(c, items: nextItems));
  }

  Future<void> toggleEquipped(String id) async {
    final c = _character!;
    final nextItems = c.items
        .map((i) => i.id == id
            ? Item(
                id: i.id,
                name: i.name,
                quantity: i.quantity,
                weight: i.weight,
                description: i.description,
                charges: i.charges,
                recharge: i.recharge,
                equippable: i.equippable,
                equipped: !(i.equipped ?? false),
                acBonus: i.acBonus,
                speedBonus: i.speedBonus,
                effects: i.effects,
              )
            : i)
        .toList();
    await _set(_rebuild(c, items: nextItems));
  }

  // ===== Extras =====
  Future<void> upsertExtra(Extra e) async {
    final c = _character!;
    final exists = c.extras.any((x) => x.id == e.id);
    final nextExtras =
        exists ? c.extras.map((x) => x.id == e.id ? e : x).toList() : [...c.extras, e];
    await _set(_rebuild(c, extras: nextExtras));
  }

  Future<void> deleteExtra(String id) async {
    final c = _character!;
    await _set(_rebuild(c, extras: c.extras.where((e) => e.id != id).toList()));
  }

  // ===== Traits =====
  Future<void> upsertTrait(Trait t) async {
    final c = _character!;
    final exists = c.traits.any((x) => x.id == t.id);
    final nextTraits =
        exists ? c.traits.map((x) => x.id == t.id ? t : x).toList() : [...c.traits, t];
    await _set(_rebuild(c, traits: nextTraits));
  }

  Future<void> deleteTrait(String id) async {
    final c = _character!;
    await _set(_rebuild(c, traits: c.traits.where((t) => t.id != id).toList()));
  }

  // ===== Effects =====
  Future<void> upsertEffect(ActiveEffect e) async {
    final c = _character!;
    final exists = c.effects.any((x) => x.id == e.id);
    final nextEffects =
        exists ? c.effects.map((x) => x.id == e.id ? e : x).toList() : [...c.effects, e];
    await _set(_rebuild(c, effects: nextEffects));
  }

  Future<void> deleteEffect(String id) async {
    final c = _character!;
    await _set(_rebuild(c, effects: c.effects.where((e) => e.id != id).toList()));
  }

  Future<void> toggleEffect(String id) async {
    final c = _character!;
    final nextEffects = c.effects
        .map((e) => e.id == id
            ? ActiveEffect(
                id: e.id,
                name: e.name,
                stat: e.stat,
                value: e.value,
                duration: e.duration,
                notes: e.notes,
                active: !e.active,
              )
            : e)
        .toList();
    await _set(_rebuild(c, effects: nextEffects));
  }
}

