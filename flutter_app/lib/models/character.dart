typedef RechargeType = String; // "none" | "short" | "long" | "daily"
typedef ModifierStat = String; // "ac" | "speed" | "hpMax" | "attack" | "damage" | "save"
typedef ModifierDuration =
    String; // "permanent" | "encounter" | "shortRest" | "longRest" | "custom"

class Weapon {
  Weapon({
    required this.id,
    required this.name,
    required this.damageDice,
    required this.damageType,
    required this.range,
    required this.properties,
    this.notes,
  });

  final String id;
  final String name;
  final String damageDice;
  final String damageType;
  final String range;
  final String properties;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'damageDice': damageDice,
        'damageType': damageType,
        'range': range,
        'properties': properties,
        'notes': notes,
      };

  factory Weapon.fromJson(Map<String, dynamic> json) => Weapon(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        damageDice: (json['damageDice'] as String?) ?? '',
        damageType: (json['damageType'] as String?) ?? '',
        range: (json['range'] as String?) ?? '',
        properties: (json['properties'] as String?) ?? '',
        notes: json['notes'] as String?,
      );
}

class Spell {
  Spell({
    required this.id,
    required this.name,
    required this.level,
    required this.school,
    required this.castingTime,
    required this.range,
    required this.components,
    this.duration,
    this.damageDice,
    required this.description,
    required this.slotsUsed,
  });

  final String id;
  final String name;
  final int level;
  final String school;
  final String castingTime;
  final String range;
  final String components;
  final String? duration;
  final String? damageDice;
  final String description;
  final int slotsUsed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'school': school,
        'castingTime': castingTime,
        'range': range,
        'components': components,
        'duration': duration,
        'damageDice': damageDice,
        'description': description,
        'slotsUsed': slotsUsed,
      };

  factory Spell.fromJson(Map<String, dynamic> json) => Spell(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        level: (json['level'] as num?)?.toInt() ?? 0,
        school: (json['school'] as String?) ?? '',
        castingTime: (json['castingTime'] as String?) ?? '',
        range: (json['range'] as String?) ?? '',
        components: (json['components'] as String?) ?? '',
        duration: json['duration'] as String?,
        damageDice: json['damageDice'] as String?,
        description: (json['description'] as String?) ?? '',
        slotsUsed: (json['slotsUsed'] as num?)?.toInt() ?? 0,
      );
}

class ItemEffect {
  ItemEffect({
    required this.id,
    required this.name,
    required this.description,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String description;
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'enabled': enabled,
      };

  factory ItemEffect.fromJson(Map<String, dynamic> json) => ItemEffect(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        enabled: (json['enabled'] as bool?) ?? true,
      );
}

class Charges {
  Charges({required this.current, required this.max});

  final int current;
  final int max;

  Map<String, dynamic> toJson() => {'current': current, 'max': max};

  factory Charges.fromJson(Map<String, dynamic> json) => Charges(
        current: (json['current'] as num?)?.toInt() ?? 0,
        max: (json['max'] as num?)?.toInt() ?? 0,
      );
}

class ItemModifier {
  ItemModifier({
    required this.stat,
    required this.value,
    this.enabled = true,
  });

  final ModifierStat stat; // "ac" | "speed" | "hpMax" | "attack" | "damage" | "save"
  final int value;
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'stat': stat,
        'value': value,
        'enabled': enabled,
      };

  factory ItemModifier.fromJson(Map<String, dynamic> json) => ItemModifier(
        stat: (json['stat'] as String?) ?? 'ac',
        value: (json['value'] as num?)?.toInt() ?? 0,
        enabled: (json['enabled'] as bool?) ?? true,
      );
}

class Item {
  Item({
    required this.id,
    required this.name,
    required this.quantity,
    required this.weight,
    required this.description,
    this.charges,
    this.recharge,
    this.equippable,
    this.equipped,
    this.acBonus,
    this.speedBonus,
    this.modifiers,
    this.effects,
  });

  final String id;
  final String name;
  final int quantity;
  final double weight;
  final String description;
  final Charges? charges;
  final RechargeType? recharge;
  final bool? equippable;
  final bool? equipped;
  final int? acBonus;
  final int? speedBonus;
  final List<ItemModifier>? modifiers;
  final List<ItemEffect>? effects;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'weight': weight,
        'description': description,
        'charges': charges?.toJson(),
        'recharge': recharge,
        'equippable': equippable,
        'equipped': equipped,
        'acBonus': acBonus,
        'speedBonus': speedBonus,
        'modifiers': modifiers?.map((m) => m.toJson()).toList(),
        'effects': effects?.map((e) => e.toJson()).toList(),
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        description: (json['description'] as String?) ?? '',
        charges: json['charges'] is Map<String, dynamic>
            ? Charges.fromJson(json['charges'] as Map<String, dynamic>)
            : null,
        recharge: json['recharge'] as String?,
        equippable: json['equippable'] as bool?,
        equipped: json['equipped'] as bool?,
        acBonus: (json['acBonus'] as num?)?.toInt(),
        speedBonus: (json['speedBonus'] as num?)?.toInt(),
        modifiers: (json['modifiers'] as List?)
                ?.whereType<Map>()
                .map((m) => ItemModifier.fromJson(m.cast<String, dynamic>()))
                .toList() ??
            _legacyModifiers(
              acBonus: (json['acBonus'] as num?)?.toInt(),
              speedBonus: (json['speedBonus'] as num?)?.toInt(),
            ),
        effects: (json['effects'] as List?)
            ?.whereType<Map>()
            .map((e) => ItemEffect.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );

  static List<ItemModifier>? _legacyModifiers({
    required int? acBonus,
    required int? speedBonus,
  }) {
    final out = <ItemModifier>[];
    if (acBonus != null && acBonus != 0) {
      out.add(ItemModifier(stat: 'ac', value: acBonus, enabled: true));
    }
    if (speedBonus != null && speedBonus != 0) {
      out.add(ItemModifier(stat: 'speed', value: speedBonus, enabled: true));
    }
    return out.isEmpty ? null : out;
  }
}

class Trait {
  Trait({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };

  factory Trait.fromJson(Map<String, dynamic> json) => Trait(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
      );
}

class Extra {
  Extra({
    required this.id,
    required this.type, // "rasgo" | "mascota" | "nota"
    required this.name,
    this.stats,
    required this.description,
  });

  final String id;
  final String type;
  final String name;
  final String? stats;
  final String description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'stats': stats,
        'description': description,
      };

  factory Extra.fromJson(Map<String, dynamic> json) => Extra(
        id: json['id'] as String,
        type: (json['type'] as String?) ?? 'rasgo',
        name: (json['name'] as String?) ?? '',
        stats: json['stats'] as String?,
        description: (json['description'] as String?) ?? '',
      );
}

class ActiveEffect {
  ActiveEffect({
    required this.id,
    required this.name,
    required this.stat,
    required this.value,
    required this.duration,
    this.notes,
    required this.active,
  });

  final String id;
  final String name;
  final ModifierStat stat;
  final int value;
  final ModifierDuration duration;
  final String? notes;
  final bool active;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stat': stat,
        'value': value,
        'duration': duration,
        'notes': notes,
        'active': active,
      };

  factory ActiveEffect.fromJson(Map<String, dynamic> json) => ActiveEffect(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        stat: (json['stat'] as String?) ?? 'ac',
        value: (json['value'] as num?)?.toInt() ?? 0,
        duration: (json['duration'] as String?) ?? 'permanent',
        notes: json['notes'] as String?,
        active: (json['active'] as bool?) ?? false,
      );
}

class Hp {
  Hp({required this.current, required this.max});

  final int current;
  final int max;

  Map<String, dynamic> toJson() => {'current': current, 'max': max};

  factory Hp.fromJson(Map<String, dynamic> json) => Hp(
        current: (json['current'] as num?)?.toInt() ?? 0,
        max: (json['max'] as num?)?.toInt() ?? 0,
      );
}

class Coins {
  Coins({required this.pp, required this.gp, required this.sp, required this.cp});

  final int pp;
  final int gp;
  final int sp;
  final int cp;

  Map<String, dynamic> toJson() => {'pp': pp, 'gp': gp, 'sp': sp, 'cp': cp};

  factory Coins.fromJson(Map<String, dynamic> json) => Coins(
        pp: (json['pp'] as num?)?.toInt() ?? 0,
        gp: (json['gp'] as num?)?.toInt() ?? 0,
        sp: (json['sp'] as num?)?.toInt() ?? 0,
        cp: (json['cp'] as num?)?.toInt() ?? 0,
      );
}

class AbilityScores {
  AbilityScores({
    required this.str,
    required this.dex,
    required this.con,
    required this.intl,
    required this.wis,
    required this.cha,
  });

  final int str;
  final int dex;
  final int con;
  final int intl;
  final int wis;
  final int cha;

  Map<String, dynamic> toJson() => {
        'str': str,
        'dex': dex,
        'con': con,
        'int': intl,
        'wis': wis,
        'cha': cha,
      };

  factory AbilityScores.fromJson(Map<String, dynamic> json) => AbilityScores(
        str: (json['str'] as num?)?.toInt() ?? 10,
        dex: (json['dex'] as num?)?.toInt() ?? 10,
        con: (json['con'] as num?)?.toInt() ?? 10,
        intl: (json['int'] as num?)?.toInt() ?? 10,
        wis: (json['wis'] as num?)?.toInt() ?? 10,
        cha: (json['cha'] as num?)?.toInt() ?? 10,
      );
}

class SkillProficiency {
  SkillProficiency({
    required this.key,
    required this.name,
    required this.ability, // "str" | "dex" | "con" | "int" | "wis" | "cha"
    this.proficient = false,
    this.expertise = false,
    this.bonusOverride,
  });

  final String key;
  final String name;
  final String ability;
  final bool proficient;
  final bool expertise;
  final int? bonusOverride;

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'ability': ability,
        'proficient': proficient,
        'expertise': expertise,
        'bonusOverride': bonusOverride,
      };

  factory SkillProficiency.fromJson(Map<String, dynamic> json) => SkillProficiency(
        key: (json['key'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        ability: (json['ability'] as String?) ?? 'wis',
        proficient: (json['proficient'] as bool?) ?? false,
        expertise: (json['expertise'] as bool?) ?? false,
        bonusOverride: (json['bonusOverride'] as num?)?.toInt(),
      );
}

class Character {
  Character({
    required this.id,
    required this.name,
    required this.race,
    required this.characterClass,
    required this.level,
    required this.hp,
    required this.ac,
    required this.speed,
    required this.coins,
    required this.abilities,
    required this.proficiencyBonus,
    required this.skills,
    required this.weapons,
    required this.spells,
    required this.items,
    required this.extras,
    required this.traits,
    required this.effects,
  });

  final String id;
  final String name;
  final String race;
  final String characterClass;
  final int level;
  final Hp hp;
  final int ac;
  final int speed;
  final Coins coins;
  final AbilityScores abilities;
  final int proficiencyBonus;
  final List<SkillProficiency> skills;
  final List<Weapon> weapons;
  final List<Spell> spells;
  final List<Item> items;
  final List<Extra> extras;
  final List<Trait> traits;
  final List<ActiveEffect> effects;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'race': race,
        'class': characterClass,
        'level': level,
        'hp': hp.toJson(),
        'ac': ac,
        'speed': speed,
        'coins': coins.toJson(),
        'abilities': abilities.toJson(),
        'proficiencyBonus': proficiencyBonus,
        'skills': skills.map((s) => s.toJson()).toList(),
        'weapons': weapons.map((w) => w.toJson()).toList(),
        'spells': spells.map((s) => s.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'extras': extras.map((e) => e.toJson()).toList(),
        'traits': traits.map((t) => t.toJson()).toList(),
        'effects': effects.map((e) => e.toJson()).toList(),
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        race: (json['race'] as String?) ?? '',
        characterClass: (json['class'] as String?) ?? '',
        level: (json['level'] as num?)?.toInt() ?? 1,
        hp: Hp.fromJson((json['hp'] as Map).cast<String, dynamic>()),
        ac: (json['ac'] as num?)?.toInt() ?? 10,
        speed: (json['speed'] as num?)?.toInt() ?? 30,
        coins: Coins.fromJson((json['coins'] as Map).cast<String, dynamic>()),
        abilities: json['abilities'] is Map
            ? AbilityScores.fromJson((json['abilities'] as Map).cast<String, dynamic>())
            : AbilityScores(str: 10, dex: 10, con: 10, intl: 10, wis: 10, cha: 10),
        proficiencyBonus: (json['proficiencyBonus'] as num?)?.toInt() ?? 2,
        skills: (json['skills'] as List?)
                ?.whereType<Map>()
                .map((s) => SkillProficiency.fromJson(s.cast<String, dynamic>()))
                .toList() ??
            const [],
        weapons: (json['weapons'] as List?)
                ?.whereType<Map>()
                .map((w) => Weapon.fromJson(w.cast<String, dynamic>()))
                .toList() ??
            const [],
        spells: (json['spells'] as List?)
                ?.whereType<Map>()
                .map((s) => Spell.fromJson(s.cast<String, dynamic>()))
                .toList() ??
            const [],
        items: (json['items'] as List?)
                ?.whereType<Map>()
                .map((i) => Item.fromJson(i.cast<String, dynamic>()))
                .toList() ??
            const [],
        extras: (json['extras'] as List?)
                ?.whereType<Map>()
                .map((e) => Extra.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
        traits: (json['traits'] as List?)
                ?.whereType<Map>()
                .map((t) => Trait.fromJson(t.cast<String, dynamic>()))
                .toList() ??
            const [],
        effects: (json['effects'] as List?)
                ?.whereType<Map>()
                .map((e) => ActiveEffect.fromJson(e.cast<String, dynamic>()))
                .toList() ??
            const [],
      );
}

