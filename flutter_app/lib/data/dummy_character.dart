import '../models/character.dart';

final dummyCharacter = Character(
  id: 'c_dummy',
  name: 'Eldrin Vael',
  race: 'Elfo Alto',
  characterClass: 'Mago (Evocación)',
  level: 5,
  hp: Hp(current: 28, max: 32),
  ac: 12,
  speed: 30,
  coins: Coins(pp: 2, gp: 145, sp: 38, cp: 76),
  abilities: AbilityScores(str: 8, dex: 14, con: 14, intl: 18, wis: 12, cha: 10),
  proficiencyBonus: 3,
  skills: const [],
  weapons: [
    Weapon(
      id: 'w1',
      name: 'Bastón de Roble Rúnico',
      damageDice: '1d6 + 1',
      damageType: 'Contundente',
      range: 'Cuerpo a cuerpo',
      properties: 'Versátil (1d8), Foco arcano',
      notes: 'Tallado con runas élficas. +1 a tiradas de hechizo.',
    ),
    Weapon(
      id: 'w2',
      name: 'Daga Plateada',
      damageDice: '1d4 + 2',
      damageType: 'Perforante',
      range: '20/60 ft',
      properties: 'Sutil, Arrojadiza, Ligera',
      notes: 'Bendecida contra no-muertos.',
    ),
  ],
  spells: [
    Spell(
      id: 's1',
      name: 'Bola de Fuego',
      level: 3,
      school: 'Evocación',
      castingTime: '1 acción',
      range: '150 ft',
      components: 'V, S, M (una bolita de guano de murciélago y azufre)',
      duration: 'Instantáneo',
      damageDice: '8d6',
      description:
          'Una brillante perla de luz sale disparada de tu dedo y estalla en una explosión de fuego. '
          'Cada criatura en una esfera de 20 ft de radio debe hacer una salvación de Destreza. '
          'Sufre 8d6 de daño de fuego si falla, la mitad si tiene éxito.',
      slotsUsed: 1,
    ),
    Spell(
      id: 's2',
      name: 'Misil Mágico',
      level: 1,
      school: 'Evocación',
      castingTime: '1 acción',
      range: '120 ft',
      components: 'V, S',
      duration: 'Instantáneo',
      damageDice: '3 x (1d4 + 1)',
      description:
          'Creas tres dardos brillantes de fuerza mágica. Cada dardo impacta a una criatura de tu elección '
          'y causa 1d4+1 de daño de fuerza. Los dardos impactan simultáneamente y puedes dirigirlos '
          'al mismo o a distintos blancos.',
      slotsUsed: 0,
    ),
    Spell(
      id: 's3',
      name: 'Rayo de Escarcha',
      level: 0,
      school: 'Evocación',
      castingTime: '1 acción',
      range: '60 ft',
      components: 'V, S',
      duration: 'Instantáneo',
      damageDice: '1d8',
      description:
          'Un rayo de luz blanco-azulada sale despedido hacia una criatura. Realiza un ataque de hechizo a distancia. '
          'En un impacto, el blanco sufre 1d8 de daño de frío y su velocidad se reduce 10 ft hasta el inicio de tu próximo turno.',
      slotsUsed: 0,
    ),
  ],
  items: [
    Item(
      id: 'i1',
      name: 'Poción de Curación',
      quantity: 3,
      weight: 0.5,
      description: 'Restaura 2d4 + 2 puntos de golpe al beberla.',
      recharge: 'none',
    ),
    Item(
      id: 'i2',
      name: 'Armadura de Cuero Tachonado',
      quantity: 1,
      weight: 13,
      description: 'Armadura ligera estándar.',
      recharge: 'none',
      equippable: true,
      equipped: true,
      modifiers: [ItemModifier(stat: 'ac', value: 2, enabled: true)],
    ),
    Item(
      id: 'i3',
      name: 'Varita de Misiles Mágicos',
      quantity: 1,
      weight: 1,
      description: 'Permite lanzar Misil Mágico a distintos niveles consumiendo cargas.',
      charges: Charges(current: 7, max: 7),
      recharge: 'long',
      effects: [
        ItemEffect(id: 'ef1', name: 'Misil Mágico Nv.1', description: 'Gasta 1 carga.', enabled: true),
        ItemEffect(id: 'ef2', name: 'Misil Mágico Nv.2', description: 'Gasta 2 cargas.', enabled: true),
        ItemEffect(id: 'ef3', name: 'Misil Mágico Nv.3', description: 'Gasta 3 cargas.', enabled: true),
      ],
    ),
    Item(
      id: 'i4',
      name: 'Pergamino de Identificar',
      quantity: 1,
      weight: 0,
      description: 'Pergamino de hechizo de Identificar. Consumible.',
      recharge: 'none',
    ),
    Item(
      id: 'i5',
      name: 'Raciones de viaje',
      quantity: 7,
      weight: 2,
      description: 'Comida seca para un día de viaje.',
      recharge: 'none',
    ),
  ],
  extras: [
    Extra(
      id: 'e1',
      type: 'mascota',
      name: 'Sombra',
      stats: 'CA 12 · PG 8 · Vel. 40 ft · Percepción +4',
      description:
          'Familiar: lechuza espectral. Puede explorar y entregar mensajes. '
          'Comparte sus sentidos con Eldrin a 100 ft.',
    ),
    Extra(
      id: 'e2',
      type: 'rasgo',
      name: 'Recuperación Arcana',
      description:
          'Una vez al día, durante un descanso corto, recupera espacios de hechizo cuya suma de niveles sea ≤ 3 '
          '(ningún espacio de nivel 6+).',
    ),
  ],
  traits: const [],
  effects: [
    ActiveEffect(
      id: 'ae1',
      name: 'Escudo de Fe',
      stat: 'ac',
      value: 2,
      duration: 'encounter',
      notes: 'Concentración, hasta 10 min.',
      active: false,
    ),
    ActiveEffect(
      id: 'ae2',
      name: 'Bendición del Druida',
      stat: 'speed',
      value: 10,
      duration: 'shortRest',
      active: false,
    ),
  ],
);

