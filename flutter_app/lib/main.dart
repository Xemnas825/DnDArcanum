import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'models/character.dart';
import 'state/character_controller.dart';
import 'theme/app_theme.dart';
import 'utils/uid.dart';
import 'widgets/fantasy_card.dart';
import 'storage/hive_characters_repository.dart';
import 'storage/local_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDb.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dungeon Companion',
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final CharacterController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = CharacterController(HiveCharactersRepository());
    ctrl.init();
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final c = ctrl.character;
        return Scaffold(
          appBar: AppBar(
            title: Text(c == null ? 'Dungeon Companion' : c.name),
            actions: [
              IconButton(
                tooltip: 'Personajes',
                onPressed: ctrl.loading
                    ? null
                    : () async {
                        await showCharactersSheet(context, ctrl);
                      },
                icon: const Icon(Icons.people_alt),
              ),
              IconButton(
                tooltip: 'Backup',
                onPressed: ctrl.loading
                    ? null
                    : () async {
                        await showBackupSheet(context, ctrl);
                      },
                icon: const Icon(Icons.cloud_download),
              ),
              IconButton(
                tooltip: 'Reset',
                onPressed: ctrl.loading
                    ? null
                    : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reset'),
                            content: const Text(
                              '¿Restablecer al personaje de ejemplo?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) await ctrl.reset();
                      },
                icon: const Icon(Icons.restart_alt),
              ),
            ],
          ),
          body: ctrl.loading || c == null
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _CharacterHeader(character: c, ctrl: ctrl),
                      _CoinsPanel(ctrl: ctrl),
                      _HpAdjustPanel(ctrl: ctrl),
                    _StatsModsPanel(ctrl: ctrl),
                      _ActiveEffectsPanel(ctrl: ctrl),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionsGrid(ctrl: ctrl),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _CoinsPanel extends StatelessWidget {
  const _CoinsPanel({required this.ctrl});

  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = ctrl.character!.coins;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: FantasyCard(
        onTap: () async {
          final next = await showCoinsDialog(context, c);
          if (next != null) await ctrl.updateCoins(next);
        },
        child: Row(
          children: [
            const Icon(Icons.payments, color: AppTheme.goldSoft),
            const SizedBox(width: 10),
            const Text('Monedas'),
            const Spacer(),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _CoinPill('PP', c.pp),
                _CoinPill('GP', c.gp),
                _CoinPill('SP', c.sp),
                _CoinPill('CP', c.cp),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF120D0E),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF4A3A2D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: const Color(0xFFB6A48A)),
          ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppTheme.gold),
          ),
        ],
      ),
    );
  }
}

class _HpAdjustPanel extends StatefulWidget {
  const _HpAdjustPanel({required this.ctrl});
  final CharacterController ctrl;

  @override
  State<_HpAdjustPanel> createState() => _HpAdjustPanelState();
}

class _HpAdjustPanelState extends State<_HpAdjustPanel> {
  final _ctrl = TextEditingController(text: '0');

  int _parse() => int.tryParse(_ctrl.text.trim()) ?? 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.ctrl.character!;
    final max = widget.ctrl.effectiveHpMax;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: FantasyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: AppTheme.goldSoft),
                const SizedBox(width: 10),
                const Text('PG'),
                const Spacer(),
                Text(
                  '${c.hp.current}/$max',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.gold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      hintText: 'Ej: 5',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final v = _parse().abs();
                    await widget.ctrl.applyHpDelta(-v);
                  },
                  child: const Text('Daño'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final v = _parse().abs();
                    await widget.ctrl.applyHpDelta(v);
                  },
                  child: const Text('Curar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsModsPanel extends StatelessWidget {
  const _StatsModsPanel({required this.ctrl});
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    String fmt(int v) => v == 0 ? '0' : (v > 0 ? '+$v' : '$v');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: FantasyCard(
        child: Row(
          children: [
            const Icon(Icons.tune, color: AppTheme.goldSoft),
            const SizedBox(width: 10),
            const Text('Modificadores'),
            const Spacer(),
            _MiniStat(label: 'Ataque', value: fmt(ctrl.effectiveAttackMod)),
            const SizedBox(width: 10),
            _MiniStat(label: 'Daño', value: fmt(ctrl.effectiveDamageMod)),
            const SizedBox(width: 10),
            _MiniStat(label: 'Salv.', value: fmt(ctrl.effectiveSaveMod)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: const Color(0xFFB6A48A)),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: AppTheme.gold),
        ),
      ],
    );
  }
}

class _SectionsGrid extends StatelessWidget {
  const _SectionsGrid({required this.ctrl});
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionTile(
                icon: Icons.sports_martial_arts,
                title: 'Combate',
                subtitle: '${ctrl.character!.weapons.length} arma(s)',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CombatScreen(ctrl: ctrl)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SectionTile(
                icon: Icons.auto_stories,
                title: 'Hechizos',
                subtitle: '${ctrl.character!.spells.length} hechizo(s)',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SpellsScreen(ctrl: ctrl)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SectionTile(
                icon: Icons.backpack,
                title: 'Inventario',
                subtitle: '${ctrl.character!.items.length} objeto(s)',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InventoryScreen(ctrl: ctrl)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SectionTile(
                icon: Icons.pets,
                title: 'Extras',
                subtitle: '${ctrl.character!.extras.length} extra(s)',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ExtrasScreen(ctrl: ctrl)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SectionTile(
                icon: Icons.auto_awesome_mosaic,
                title: 'Rasgos',
                subtitle: '${ctrl.character!.traits.length} rasgo(s)',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TraitsScreen(ctrl: ctrl)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SectionTile(
                icon: Icons.school,
                title: 'Competencias',
                subtitle: 'Atributos y skills',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CompetenciesScreen(ctrl: ctrl)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CompetenciesScreen extends StatelessWidget {
  const CompetenciesScreen({super.key, required this.ctrl});
  final CharacterController ctrl;

  static const skillsCatalog = <Map<String, String>>[
    {'key': 'acrobatics', 'name': 'Acrobacias', 'ability': 'dex'},
    {'key': 'animal_handling', 'name': 'Trato con animales', 'ability': 'wis'},
    {'key': 'arcana', 'name': 'Arcana', 'ability': 'int'},
    {'key': 'athletics', 'name': 'Atletismo', 'ability': 'str'},
    {'key': 'deception', 'name': 'Engaño', 'ability': 'cha'},
    {'key': 'history', 'name': 'Historia', 'ability': 'int'},
    {'key': 'insight', 'name': 'Perspicacia', 'ability': 'wis'},
    {'key': 'intimidation', 'name': 'Intimidación', 'ability': 'cha'},
    {'key': 'investigation', 'name': 'Investigación', 'ability': 'int'},
    {'key': 'medicine', 'name': 'Medicina', 'ability': 'wis'},
    {'key': 'nature', 'name': 'Naturaleza', 'ability': 'int'},
    {'key': 'perception', 'name': 'Percepción', 'ability': 'wis'},
    {'key': 'performance', 'name': 'Interpretación', 'ability': 'cha'},
    {'key': 'persuasion', 'name': 'Persuasión', 'ability': 'cha'},
    {'key': 'religion', 'name': 'Religión', 'ability': 'int'},
    {'key': 'sleight_of_hand', 'name': 'Juego de manos', 'ability': 'dex'},
    {'key': 'stealth', 'name': 'Sigilo', 'ability': 'dex'},
    {'key': 'survival', 'name': 'Supervivencia', 'ability': 'wis'},
  ];

  int modForAbility(AbilityScores a, String key) {
    final score = switch (key) {
      'str' => a.str,
      'dex' => a.dex,
      'con' => a.con,
      'int' => a.intl,
      'wis' => a.wis,
      'cha' => a.cha,
      _ => 10,
    };
    return ((score - 10) / 2).floor();
  }

  String fmt(int v) => v == 0 ? '+0' : (v > 0 ? '+$v' : '$v');

  @override
  Widget build(BuildContext context) {
    final c = ctrl.character!;
    final a = c.abilities;
    return Scaffold(
      appBar: AppBar(title: const Text('Competencias')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FantasyCard(
            onTap: () async {
              final next = await showAbilitiesDialog(context, c);
              if (next == null) return;
              await ctrl.updateAbilities(next.abilities);
              await ctrl.updateProficiencyBonus(next.proficiencyBonus);
            },
            child: Row(
              children: [
                const Icon(Icons.stacked_bar_chart, color: AppTheme.goldSoft),
                const SizedBox(width: 12),
                const Expanded(child: Text('Atributos + bono de competencia')),
                Text('PB ${c.proficiencyBonus}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.gold)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppTheme.goldSoft),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FantasyCard(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AbilityPill('FUE', a.str, fmt(modForAbility(a, 'str'))),
                _AbilityPill('DES', a.dex, fmt(modForAbility(a, 'dex'))),
                _AbilityPill('CON', a.con, fmt(modForAbility(a, 'con'))),
                _AbilityPill('INT', a.intl, fmt(modForAbility(a, 'int'))),
                _AbilityPill('SAB', a.wis, fmt(modForAbility(a, 'wis'))),
                _AbilityPill('CAR', a.cha, fmt(modForAbility(a, 'cha'))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Habilidades', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...skillsCatalog.map((row) {
            final key = row['key']!;
            final name = row['name']!;
            final ability = row['ability']!;
            final existing = c.skills.where((s) => s.key == key).isEmpty
                ? null
                : c.skills.firstWhere((s) => s.key == key);
            final s = existing ??
                SkillProficiency(key: key, name: name, ability: ability, proficient: false, expertise: false);
            final base = modForAbility(a, ability);
            final prof = s.proficient ? c.proficiencyBonus : 0;
            final exp = s.expertise ? c.proficiencyBonus : 0;
            final total = s.bonusOverride ?? (base + prof + exp);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FantasyCard(
                onTap: () async {
                  final edited = await showSkillDialog(context, s);
                  if (edited != null) await ctrl.upsertSkill(edited);
                },
                child: Row(
                  children: [
                    const Icon(Icons.checklist, color: AppTheme.goldSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name),
                          const SizedBox(height: 4),
                          Text(
                            '${ability.toUpperCase()} · ${s.proficient ? 'Competente' : 'No competente'}${s.expertise ? ' · Experto' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFB6A48A)),
                          ),
                        ],
                      ),
                    ),
                    Text(fmt(total), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.gold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppTheme.goldSoft),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AbilityPill extends StatelessWidget {
  const _AbilityPill(this.label, this.score, this.mod);
  final String label;
  final int score;
  final String mod;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF120D0E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4A3A2D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFFB6A48A))),
          const SizedBox(height: 4),
          Text('$score ($mod)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.gold)),
        ],
      ),
    );
  }
}

class TraitsScreen extends StatelessWidget {
  const TraitsScreen({super.key, required this.ctrl});
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = ctrl.character!;
    return Scaffold(
      appBar: AppBar(title: const Text('Rasgos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final t = await showTraitDialog(
            context,
            Trait(id: uid(), name: '', description: ''),
          );
          if (t != null) await ctrl.upsertTrait(t);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Rasgo'),
      ),
      body: c.traits.isEmpty
          ? const Center(child: Text('Sin rasgos.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: c.traits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, idx) {
                final t = c.traits[idx];
                return FantasyCard(
                  onTap: () async {
                    final edited = await showTraitDialog(context, t);
                    if (edited != null) await ctrl.upsertTrait(edited);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_mosaic, color: AppTheme.goldSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name.isEmpty ? '(sin nombre)' : t.name),
                            const SizedBox(height: 6),
                            Text(
                              t.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: const Color(0xFFD9C8A9)),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Borrar',
                        onPressed: () async {
                          final ok = await _confirmDelete(context, 'Borrar rasgo', t.name);
                          if (ok) await ctrl.deleteTrait(t.id);
                        },
                        icon: const Icon(Icons.delete, color: Color(0xFFE57373)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FantasyCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.goldSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFFB6A48A)),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppTheme.goldSoft),
        ],
      ),
    );
  }
}

class CombatScreen extends StatelessWidget {
  const CombatScreen({super.key, required this.ctrl});
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = ctrl.character!;
    return Scaffold(
      appBar: AppBar(title: const Text('Combate')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final w = await showWeaponDialog(
            context,
            Weapon(
              id: uid(),
              name: '',
              damageDice: '',
              damageType: '',
              range: '',
              properties: '',
              notes: '',
            ),
          );
          if (w != null) await ctrl.upsertWeapon(w);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Arma'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _StatsModsPanel(ctrl: ctrl),
          ),
          const SizedBox(height: 12),
          Expanded(child: _CombatTab(character: c, ctrl: ctrl)),
        ],
      ),
    );
  }
}

class SpellsScreen extends StatelessWidget {
  const SpellsScreen({super.key, required this.ctrl});
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = ctrl.character!;
    return Scaffold(
      appBar: AppBar(title: const Text('Hechizos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final s = await showSpellDialog(
            context,
            Spell(
              id: uid(),
              name: '',
              level: 1,
              school: '',
              castingTime: '1 acción',
              range: '',
              components: '',
              duration: '',
              damageDice: '',
              description: '',
              slotsUsed: 0,
            ),
          );
          if (s != null) await ctrl.upsertSpell(s);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Hechizo'),
      ),
      body: _SpellsTab(character: c, ctrl: ctrl),
    );
  }
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key, required this.ctrl});
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = ctrl.character!;
    return Scaffold(
      appBar: AppBar(title: const Text('Inventario')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final i = await showItemDialog(
            context,
            Item(
              id: uid(),
              name: '',
              quantity: 1,
              weight: 0,
              description: '',
              recharge: 'none',
              equippable: false,
              equipped: false,
              effects: const [],
            ),
          );
          if (i != null) await ctrl.upsertItem(i);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Objeto'),
      ),
      body: _InventoryTab(character: c, ctrl: ctrl),
    );
  }
}

class ExtrasScreen extends StatelessWidget {
  const ExtrasScreen({super.key, required this.ctrl});
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    final c = ctrl.character!;
    return Scaffold(
      appBar: AppBar(title: const Text('Extras')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final e = await showExtraDialog(
            context,
            Extra(
              id: uid(),
              type: 'rasgo',
              name: '',
              stats: '',
              description: '',
            ),
          );
          if (e != null) await ctrl.upsertExtra(e);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Extra'),
      ),
      body: _ExtrasTab(character: c, ctrl: ctrl),
    );
  }
}

class _CharacterHeader extends StatelessWidget {
  const _CharacterHeader({required this.character, required this.ctrl});

  final Character character;
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: FantasyCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6A5636)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5B1B1B), Color(0xFF2A0E0E)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                character.name.isEmpty ? '?' : character.name[0].toUpperCase(),
                style: t.titleLarge?.copyWith(
                  color: AppTheme.parchment,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(character.name, style: t.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${character.race} · ${character.characterClass} · Nv. ${character.level}',
                    style: t.bodySmall?.copyWith(color: const Color(0xFFB6A48A)),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () async {
                final next = await showCharacterDialog(context, ctrl.character!);
                if (next == null) return;
                await ctrl.updateBasics(
                  name: next.name,
                  race: next.race,
                  characterClass: next.characterClass,
                  level: next.level,
                  ac: next.ac,
                  speed: next.speed,
                  hpCurrent: next.hp.current,
                  hpMax: next.hp.max,
                );
              },
              icon: const Icon(Icons.edit, color: AppTheme.goldSoft),
            ),
            _Pill(label: 'CA', value: '${ctrl.effectiveAc}'),
            const SizedBox(width: 8),
            _Pill(
              label: 'PG',
              value: '${character.hp.current}/${ctrl.effectiveHpMax}',
            ),
            const SizedBox(width: 8),
            _Pill(label: 'Vel', value: '${ctrl.effectiveSpeed}'),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF4A3A2D)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF120D0E),
      ),
      child: Column(
        children: [
          Text(label, style: t.labelSmall?.copyWith(color: const Color(0xFFB6A48A))),
          Text(value, style: t.titleSmall?.copyWith(color: AppTheme.gold)),
        ],
      ),
    );
  }
}

class _CombatTab extends StatelessWidget {
  const _CombatTab({required this.character, required this.ctrl});
  final Character character;
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    if (character.weapons.isEmpty) {
      return const Center(child: Text('No tienes armas. Añade una.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: character.weapons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final w = character.weapons[idx];
        return FantasyCard(
          onTap: () async {
            final edited = await showWeaponDialog(context, w);
            if (edited != null) await ctrl.upsertWeapon(edited);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.gavel, color: AppTheme.goldSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name.isEmpty ? '(sin nombre)' : w.name),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Chip(text: w.damageDice),
                        _Chip(text: w.damageType, outlined: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${w.range} · ${w.properties}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFFB6A48A)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Borrar',
                onPressed: () async {
                  final ok = await _confirmDelete(context, 'Borrar arma', w.name);
                  if (ok) await ctrl.deleteWeapon(w.id);
                },
                icon: const Icon(Icons.delete, color: Color(0xFFE57373)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpellsTab extends StatelessWidget {
  const _SpellsTab({required this.character, required this.ctrl});
  final Character character;
  final CharacterController ctrl;

  String _levelLabel(int n) => n == 0 ? 'Truco' : 'Nivel $n';

  @override
  Widget build(BuildContext context) {
    if (character.spells.isEmpty) {
      return const Center(child: Text('No tienes hechizos.'));
    }
    final sorted = [...character.spells]
      ..sort((a, b) => a.level.compareTo(b.level));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final s = sorted[idx];
        return FantasyCard(
          onTap: () async {
            final edited = await showSpellDialog(context, s);
            if (edited != null) await ctrl.upsertSpell(edited);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    s.level == 0 ? Icons.auto_awesome : Icons.menu_book,
                    color: AppTheme.goldSoft,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name.isEmpty ? '(sin nombre)' : s.name),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _Chip(text: _levelLabel(s.level)),
                            _Chip(text: s.school, outlined: true),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${s.castingTime} · ${s.range}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFFB6A48A)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Borrar',
                    onPressed: () async {
                      final ok = await _confirmDelete(context, 'Borrar hechizo', s.name);
                      if (ok) await ctrl.deleteSpell(s.id);
                    },
                    icon: const Icon(Icons.delete, color: Color(0xFFE57373)),
                  ),
                ],
              ),
              if (s.level > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Espacios usados',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFFB6A48A)),
                    ),
                    const Spacer(),
                    _IconSquare(
                      icon: Icons.remove,
                      onTap: () => ctrl.adjustSpellSlots(s.id, -1),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${s.slotsUsed}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppTheme.gold),
                    ),
                    const SizedBox(width: 10),
                    _IconSquare(
                      icon: Icons.add,
                      onTap: () => ctrl.adjustSpellSlots(s.id, 1),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab({required this.character, required this.ctrl});
  final Character character;
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    if (character.items.isEmpty) {
      return const Center(child: Text('Inventario vacío.'));
    }
    final totalWeight = character.items.fold<double>(
      0,
      (s, i) => s + (i.weight * i.quantity),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FantasyCard(
          child: Row(
            children: [
              const Icon(Icons.scale, color: AppTheme.goldSoft),
              const SizedBox(width: 10),
              const Text('Peso total'),
              const Spacer(),
              Text(
                '${totalWeight.toStringAsFixed(1)} lb',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.gold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...character.items.map(
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FantasyCard(
              onTap: () async {
                final edited = await showItemDialog(context, i);
                if (edited != null) await ctrl.upsertItem(edited);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.backpack, color: AppTheme.goldSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          i.name.isEmpty ? '(sin nombre)' : i.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (i.equippable == true)
                        IconButton(
                          tooltip: (i.equipped == true) ? 'Quitar' : 'Equipar',
                          onPressed: () => ctrl.toggleEquipped(i.id),
                          icon: Icon(
                            i.equipped == true
                                ? Icons.shield
                                : Icons.shield_outlined,
                            color: i.equipped == true
                                ? AppTheme.gold
                                : const Color(0xFFB6A48A),
                          ),
                        ),
                      IconButton(
                        tooltip: 'Borrar',
                        onPressed: () async {
                          final ok = await _confirmDelete(context, 'Borrar objeto', i.name);
                          if (ok) await ctrl.deleteItem(i.id);
                        },
                        icon: const Icon(Icons.delete, color: Color(0xFFE57373)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Peso: ${i.weight} lb',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(0xFFB6A48A)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Cantidad',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFFB6A48A)),
                      ),
                      const Spacer(),
                      _IconSquare(
                        icon: Icons.remove,
                        onTap: () => ctrl.adjustItemQty(i.id, -1),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${i.quantity}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppTheme.gold),
                      ),
                      const SizedBox(width: 10),
                      _IconSquare(
                        icon: Icons.add,
                        onTap: () => ctrl.adjustItemQty(i.id, 1),
                      ),
                    ],
                  ),
                  if (i.charges != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'Cargas',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFFB6A48A)),
                        ),
                        const Spacer(),
                        _IconSquare(
                          icon: Icons.bolt,
                          onTap: () => ctrl.adjustItemCharges(i.id, -1),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${i.charges!.current}/${i.charges!.max}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.gold),
                        ),
                        const SizedBox(width: 10),
                        _IconSquare(
                          icon: Icons.bolt_outlined,
                          onTap: () => ctrl.adjustItemCharges(i.id, 1),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExtrasTab extends StatelessWidget {
  const _ExtrasTab({required this.character, required this.ctrl});
  final Character character;
  final CharacterController ctrl;

  @override
  Widget build(BuildContext context) {
    if (character.extras.isEmpty) {
      return const Center(child: Text('Sin extras.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: character.extras.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final e = character.extras[idx];
        final icon = e.type == 'mascota'
            ? Icons.pets
            : e.type == 'rasgo'
                ? Icons.star
                : Icons.description;
        return FantasyCard(
          onTap: () async {
            final edited = await showExtraDialog(context, e);
            if (edited != null) await ctrl.upsertExtra(edited);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.goldSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.name.isEmpty ? '(sin nombre)' : e.name),
                        ),
                        _Chip(text: e.type.toUpperCase(), outlined: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if ((e.stats ?? '').trim().isNotEmpty)
                      Text(
                        e.stats!.trim(),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFFB6A48A)),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      e.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFFD9C8A9)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Borrar',
                onPressed: () async {
                  final ok = await _confirmDelete(context, 'Borrar extra', e.name);
                  if (ok) await ctrl.deleteExtra(e.id);
                },
                icon: const Icon(Icons.delete, color: Color(0xFFE57373)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.outlined = false});

  final String text;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bg = outlined ? Colors.transparent : const Color(0xFF2A0E0E);
    final fg = outlined ? AppTheme.goldSoft : AppTheme.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF4A3A2D)),
      ),
      child: Text(
        text.isEmpty ? '-' : text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _IconSquare extends StatelessWidget {
  const _IconSquare({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF120D0E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4A3A2D)),
        ),
        child: Icon(icon, size: 18, color: AppTheme.goldSoft),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String title, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text('¿Seguro que querés borrar "${name.isEmpty ? '(sin nombre)' : name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Borrar')),
      ],
    ),
  );
  return ok == true;
}

class _ActiveEffectsPanel extends StatelessWidget {
  const _ActiveEffectsPanel({required this.ctrl});
  final CharacterController ctrl;

  static const statLabels = {
    'ac': 'CA',
    'speed': 'Velocidad',
    'hpMax': 'PG máx.',
    'attack': 'Ataque',
    'damage': 'Daño',
    'save': 'Salvación',
  };
  static const durationLabels = {
    'permanent': 'Permanente',
    'encounter': 'Encuentro',
    'shortRest': 'Hasta descanso corto',
    'longRest': 'Hasta descanso largo',
    'custom': 'Personalizada',
  };

  @override
  Widget build(BuildContext context) {
    final c = ctrl.character!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Efectos Activos',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final e = await showEffectDialog(
                        context,
                        ActiveEffect(
                          id: uid(),
                          name: '',
                          stat: 'ac',
                          value: 1,
                          duration: 'encounter',
                          notes: '',
                          active: true,
                        ),
                      );
                      if (e != null) await ctrl.upsertEffect(e);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir'),
                  ),
                ],
              ),
              if (c.effects.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Sin efectos. Añade buffs o debuffs temporales.'),
                )
              else
                ...c.effects.map((e) {
                  final sign = e.value >= 0 ? '+' : '';
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.name.isEmpty ? '(sin nombre)' : e.name),
                    subtitle: Text(
                      '$sign${e.value} ${statLabels[e.stat] ?? e.stat} · '
                      '${durationLabels[e.duration] ?? e.duration}'
                      '${(e.notes ?? '').trim().isEmpty ? '' : ' · ${e.notes}'}',
                    ),
                    leading: Switch(
                      value: e.active,
                      onChanged: (_) => ctrl.toggleEffect(e.id),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () async {
                            final edited = await showEffectDialog(context, e);
                            if (edited != null) await ctrl.upsertEffect(edited);
                          },
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: 'Borrar',
                          onPressed: () async {
                            final ok = await _confirmDelete(context, 'Borrar efecto', e.name);
                            if (ok) await ctrl.deleteEffect(e.id);
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Weapon?> showWeaponDialog(BuildContext context, Weapon weapon) async {
  final name = TextEditingController(text: weapon.name);
  final damageDice = TextEditingController(text: weapon.damageDice);
  final damageType = TextEditingController(text: weapon.damageType);
  final range = TextEditingController(text: weapon.range);
  final properties = TextEditingController(text: weapon.properties);
  final notes = TextEditingController(text: weapon.notes ?? '');

  return showDialog<Weapon>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(weapon.name.isEmpty ? 'Arma' : 'Editar Arma'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: damageDice, decoration: const InputDecoration(labelText: 'Dados de daño')),
            TextField(controller: damageType, decoration: const InputDecoration(labelText: 'Tipo de daño')),
            TextField(controller: range, decoration: const InputDecoration(labelText: 'Alcance')),
            TextField(controller: properties, decoration: const InputDecoration(labelText: 'Propiedades')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notas'), minLines: 2, maxLines: 4),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            Weapon(
              id: weapon.id,
              name: name.text.trim(),
              damageDice: damageDice.text.trim(),
              damageType: damageType.text.trim(),
              range: range.text.trim(),
              properties: properties.text.trim(),
              notes: notes.text.trim(),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<Spell?> showSpellDialog(BuildContext context, Spell spell) async {
  final name = TextEditingController(text: spell.name);
  final level = TextEditingController(text: '${spell.level}');
  final school = TextEditingController(text: spell.school);
  final castingTime = TextEditingController(text: spell.castingTime);
  final range = TextEditingController(text: spell.range);
  final components = TextEditingController(text: spell.components);
  final duration = TextEditingController(text: spell.duration ?? '');
  final damageDice = TextEditingController(text: spell.damageDice ?? '');
  final description = TextEditingController(text: spell.description);
  final slotsUsed = TextEditingController(text: '${spell.slotsUsed}');

  int parseIntSafe(String v, int fallback) => int.tryParse(v.trim()) ?? fallback;

  return showDialog<Spell>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(spell.name.isEmpty ? 'Hechizo' : 'Editar Hechizo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: level, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nivel (0=truco)')),
            TextField(controller: school, decoration: const InputDecoration(labelText: 'Escuela')),
            TextField(controller: castingTime, decoration: const InputDecoration(labelText: 'Tiempo de casteo')),
            TextField(controller: range, decoration: const InputDecoration(labelText: 'Alcance')),
            TextField(controller: components, decoration: const InputDecoration(labelText: 'Componentes')),
            TextField(controller: duration, decoration: const InputDecoration(labelText: 'Duración')),
            TextField(controller: damageDice, decoration: const InputDecoration(labelText: 'Dados a tirar')),
            TextField(controller: slotsUsed, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Slots usados')),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Descripción'), minLines: 3, maxLines: 8),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            Spell(
              id: spell.id,
              name: name.text.trim(),
              level: parseIntSafe(level.text, spell.level).clamp(0, 9),
              school: school.text.trim(),
              castingTime: castingTime.text.trim(),
              range: range.text.trim(),
              components: components.text.trim(),
              duration: duration.text.trim(),
              damageDice: damageDice.text.trim(),
              description: description.text.trim(),
              slotsUsed: parseIntSafe(slotsUsed.text, spell.slotsUsed).clamp(0, 999999),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<Item?> showItemDialog(BuildContext context, Item item) async {
  final name = TextEditingController(text: item.name);
  final quantity = TextEditingController(text: '${item.quantity}');
  final weight = TextEditingController(text: '${item.weight}');
  final description = TextEditingController(text: item.description);
  bool equippable = item.equippable ?? false;
  bool equipped = item.equipped ?? false;
  List<ItemModifier> modifiers =
      List<ItemModifier>.from(item.modifiers ?? const []);
  bool hasCharges = item.charges != null;
  int chargesCurrent = item.charges?.current ?? 1;
  int chargesMax = item.charges?.max ?? 1;
  String recharge = item.recharge ?? 'none';
  List<ItemEffect> effects = List<ItemEffect>.from(item.effects ?? const []);

  int parseIntSafe(String v, int fallback) => int.tryParse(v.trim()) ?? fallback;
  double parseDoubleSafe(String v, double fallback) => double.tryParse(v.trim()) ?? fallback;

  final effectNameCtrls = <String, TextEditingController>{};
  final effectDescCtrls = <String, TextEditingController>{};
  void ensureEffectControllers() {
    for (final ef in effects) {
      effectNameCtrls.putIfAbsent(
        ef.id,
        () => TextEditingController(text: ef.name),
      );
      effectDescCtrls.putIfAbsent(
        ef.id,
        () => TextEditingController(text: ef.description),
      );
    }
  }
  ensureEffectControllers();

  return showDialog<Item>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(item.name.isEmpty ? 'Objeto' : 'Editar Objeto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cantidad')),
              TextField(controller: weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Peso (lb)')),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Descripción'), minLines: 2, maxLines: 6),
              const SizedBox(height: 12),
              SwitchListTile(
                value: equippable,
                onChanged: (v) => setState(() => equippable = v),
                title: const Text('Equipable'),
              ),
              if (equippable) ...[
                SwitchListTile(
                  value: equipped,
                  onChanged: (v) => setState(() => equipped = v),
                  title: const Text('Equipado'),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Modificadores al equipar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        modifiers = [
                          ...modifiers,
                          ItemModifier(stat: 'ac', value: 1, enabled: true),
                        ];
                      }),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir'),
                    ),
                  ],
                ),
                if (modifiers.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Añadí uno o más modificadores (CA, Velocidad, PG máx., etc.).'),
                    ),
                  ),
                ...modifiers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final m = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FantasyCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Switch(
                            value: m.enabled,
                            onChanged: (v) => setState(() {
                              final next = [...modifiers];
                              next[idx] = ItemModifier(stat: m.stat, value: m.value, enabled: v);
                              modifiers = next;
                            }),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: m.stat,
                              items: const [
                                DropdownMenuItem(value: 'ac', child: Text('CA')),
                                DropdownMenuItem(value: 'speed', child: Text('Velocidad')),
                                DropdownMenuItem(value: 'hpMax', child: Text('PG máx.')),
                                DropdownMenuItem(value: 'attack', child: Text('Ataque')),
                                DropdownMenuItem(value: 'damage', child: Text('Daño')),
                                DropdownMenuItem(value: 'save', child: Text('Salvación')),
                              ],
                              onChanged: (v) => setState(() {
                                final stat = v ?? m.stat;
                                final next = [...modifiers];
                                next[idx] = ItemModifier(stat: stat, value: m.value, enabled: m.enabled);
                                modifiers = next;
                              }),
                              decoration: const InputDecoration(labelText: 'Stat'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 90,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Valor'),
                              controller: TextEditingController(text: '${m.value}'),
                              onChanged: (v) => setState(() {
                                final nextVal = parseIntSafe(v, m.value);
                                final next = [...modifiers];
                                next[idx] = ItemModifier(stat: m.stat, value: nextVal, enabled: m.enabled);
                                modifiers = next;
                              }),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            onPressed: () => setState(() {
                              final next = [...modifiers]..removeAt(idx);
                              modifiers = next;
                            }),
                            icon: const Icon(Icons.delete, color: Color(0xFFE57373)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 12),
              SwitchListTile(
                value: hasCharges,
                onChanged: (v) => setState(() => hasCharges = v),
                title: const Text('Tiene cargas/usos'),
              ),
              if (hasCharges) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cargas actuales'),
                        controller: TextEditingController(text: '$chargesCurrent'),
                        onChanged: (v) => chargesCurrent = parseIntSafe(v, chargesCurrent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Cargas máximas'),
                        controller: TextEditingController(text: '$chargesMax'),
                        onChanged: (v) => chargesMax = parseIntSafe(v, chargesMax),
                      ),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  value: recharge,
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('Manual')),
                    DropdownMenuItem(value: 'short', child: Text('Descanso corto')),
                    DropdownMenuItem(value: 'long', child: Text('Descanso largo')),
                    DropdownMenuItem(value: 'daily', child: Text('Diaria')),
                  ],
                  onChanged: (v) => setState(() => recharge = v ?? 'none'),
                  decoration: const InputDecoration(labelText: 'Recarga'),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Funciones / efectos del objeto',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      effects = [
                        ...effects,
                        ItemEffect(
                          id: uid(),
                          name: '',
                          description: '',
                          enabled: true,
                        ),
                      ];
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir'),
                  ),
                ],
              ),
              if (effects.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Útil para objetos con varias “cuentas”/acciones (ej. collar con varios hechizos).',
                    ),
                  ),
                ),
              ...effects.map((ef) {
                ensureEffectControllers();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FantasyCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Switch(
                              value: ef.enabled,
                              onChanged: (v) => setState(() {
                                effects = effects
                                    .map((x) => x.id == ef.id
                                        ? ItemEffect(
                                            id: x.id,
                                            name: x.name,
                                            description: x.description,
                                            enabled: v,
                                          )
                                        : x)
                                    .toList();
                              }),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Activo')),
                            IconButton(
                              tooltip: 'Eliminar',
                              onPressed: () => setState(() {
                                effects = effects.where((x) => x.id != ef.id).toList();
                              }),
                              icon: const Icon(Icons.delete, color: Color(0xFFE57373)),
                            ),
                          ],
                        ),
                        TextField(
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          controller: effectNameCtrls[ef.id],
                          onChanged: (v) => setState(() {
                            effects = effects
                                .map((x) => x.id == ef.id
                                    ? ItemEffect(
                                        id: x.id,
                                        name: v,
                                        description: x.description,
                                        enabled: x.enabled,
                                      )
                                    : x)
                                .toList();
                          }),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(labelText: 'Descripción / coste'),
                          controller: effectDescCtrls[ef.id],
                          onChanged: (v) => setState(() {
                            effects = effects
                                .map((x) => x.id == ef.id
                                    ? ItemEffect(
                                        id: x.id,
                                        name: x.name,
                                        description: v,
                                        enabled: x.enabled,
                                      )
                                    : x)
                                .toList();
                          }),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              Item(
                id: item.id,
                name: name.text.trim(),
                quantity: parseIntSafe(quantity.text, item.quantity).clamp(0, 999999),
                weight: parseDoubleSafe(weight.text, item.weight),
                description: description.text.trim(),
                charges: hasCharges ? Charges(current: chargesCurrent, max: chargesMax <= 0 ? 1 : chargesMax) : null,
                recharge: hasCharges ? recharge : (item.recharge ?? 'none'),
                equippable: equippable,
                equipped: equippable ? equipped : false,
                acBonus: item.acBonus,
                speedBonus: item.speedBonus,
                modifiers: equippable ? modifiers : null,
                effects: effects,
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

Future<Extra?> showExtraDialog(BuildContext context, Extra extra) async {
  final name = TextEditingController(text: extra.name);
  final stats = TextEditingController(text: extra.stats ?? '');
  final description = TextEditingController(text: extra.description);
  String type = extra.type;

  return showDialog<Extra>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(extra.name.isEmpty ? 'Extra' : 'Editar Extra'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'rasgo', child: Text('Rasgo')),
                  DropdownMenuItem(value: 'mascota', child: Text('Mascota')),
                  DropdownMenuItem(value: 'nota', child: Text('Nota')),
                ],
                onChanged: (v) => setState(() => type = v ?? 'rasgo'),
                decoration: const InputDecoration(labelText: 'Tipo'),
              ),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: stats, decoration: const InputDecoration(labelText: 'Estadísticas (opcional)')),
              TextField(controller: description, decoration: const InputDecoration(labelText: 'Descripción'), minLines: 3, maxLines: 8),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              Extra(
                id: extra.id,
                type: type,
                name: name.text.trim(),
                stats: stats.text.trim(),
                description: description.text.trim(),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

Future<Character?> showCharacterDialog(BuildContext context, Character character) async {
  final name = TextEditingController(text: character.name);
  final race = TextEditingController(text: character.race);
  final cls = TextEditingController(text: character.characterClass);
  final level = TextEditingController(text: '${character.level}');
  final ac = TextEditingController(text: '${character.ac}');
  final speed = TextEditingController(text: '${character.speed}');
  final hpCurrent = TextEditingController(text: '${character.hp.current}');
  final hpMax = TextEditingController(text: '${character.hp.max}');

  int pi(String v, int fallback) => int.tryParse(v.trim()) ?? fallback;

  return showDialog<Character>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Editar personaje'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: race, decoration: const InputDecoration(labelText: 'Raza')),
            TextField(controller: cls, decoration: const InputDecoration(labelText: 'Clase / Subclase')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: level,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nivel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: speed,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Velocidad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ac,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CA base'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: hpMax,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'PG máx. base'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hpCurrent,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PG actuales'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            Character(
              id: character.id,
              name: name.text.trim(),
              race: race.text.trim(),
              characterClass: cls.text.trim(),
              level: pi(level.text, character.level).clamp(1, 20),
              hp: Hp(
                current: pi(hpCurrent.text, character.hp.current),
                max: pi(hpMax.text, character.hp.max).clamp(1, 999999),
              ),
              ac: pi(ac.text, character.ac).clamp(0, 999999),
              speed: pi(speed.text, character.speed).clamp(0, 999999),
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
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<Trait?> showTraitDialog(BuildContext context, Trait trait) async {
  final name = TextEditingController(text: trait.name);
  final description = TextEditingController(text: trait.description);
  return showDialog<Trait>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rasgo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Descripción'),
              minLines: 3,
              maxLines: 8,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            Trait(
              id: trait.id,
              name: name.text.trim(),
              description: description.text.trim(),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<({AbilityScores abilities, int proficiencyBonus})?> showAbilitiesDialog(
  BuildContext context,
  Character character,
) async {
  final a = character.abilities;
  final str = TextEditingController(text: '${a.str}');
  final dex = TextEditingController(text: '${a.dex}');
  final con = TextEditingController(text: '${a.con}');
  final intl = TextEditingController(text: '${a.intl}');
  final wis = TextEditingController(text: '${a.wis}');
  final cha = TextEditingController(text: '${a.cha}');
  final pb = TextEditingController(text: '${character.proficiencyBonus}');

  int pi(String v, int fallback) => int.tryParse(v.trim()) ?? fallback;

  return showDialog<({AbilityScores abilities, int proficiencyBonus})>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Atributos'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: str, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'FUE'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: dex, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'DES'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: con, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CON'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: intl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'INT'))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: wis, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'SAB'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: cha, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CAR'))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pb,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Bono de competencia (PB)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            (
              abilities: AbilityScores(
                str: pi(str.text, a.str),
                dex: pi(dex.text, a.dex),
                con: pi(con.text, a.con),
                intl: pi(intl.text, a.intl),
                wis: pi(wis.text, a.wis),
                cha: pi(cha.text, a.cha),
              ),
              proficiencyBonus: pi(pb.text, character.proficiencyBonus),
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<SkillProficiency?> showSkillDialog(BuildContext context, SkillProficiency skill) async {
  bool proficient = skill.proficient;
  bool expertise = skill.expertise;
  final override = TextEditingController(text: skill.bonusOverride?.toString() ?? '');

  int? piOpt(String v) => v.trim().isEmpty ? null : int.tryParse(v.trim());

  return showDialog<SkillProficiency>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(skill.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: proficient,
              onChanged: (v) => setState(() => proficient = v),
              title: const Text('Competente'),
            ),
            SwitchListTile(
              value: expertise,
              onChanged: proficient ? (v) => setState(() => expertise = v) : null,
              title: const Text('Experto (doble PB)'),
            ),
            TextField(
              controller: override,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bonus manual (opcional)',
                hintText: 'Dejá vacío para calcular automático',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              SkillProficiency(
                key: skill.key,
                name: skill.name,
                ability: skill.ability,
                proficient: proficient,
                expertise: proficient ? expertise : false,
                bonusOverride: piOpt(override.text),
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

Future<Coins?> showCoinsDialog(BuildContext context, Coins coins) async {
  final pp = TextEditingController(text: '${coins.pp}');
  final gp = TextEditingController(text: '${coins.gp}');
  final sp = TextEditingController(text: '${coins.sp}');
  final cp = TextEditingController(text: '${coins.cp}');

  int p(String v) => int.tryParse(v.trim()) ?? 0;

  return showDialog<Coins>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Monedas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: pp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'PP'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: gp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'GP'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: sp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'SP'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: cp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'CP'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
            ctx,
            Coins(pp: p(pp.text), gp: p(gp.text), sp: p(sp.text), cp: p(cp.text)),
          ),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<ActiveEffect?> showEffectDialog(BuildContext context, ActiveEffect effect) async {
  final name = TextEditingController(text: effect.name);
  final value = TextEditingController(text: '${effect.value}');
  final notes = TextEditingController(text: effect.notes ?? '');
  String stat = effect.stat;
  String duration = effect.duration;
  bool active = effect.active;

  int parseIntSafe(String v, int fallback) => int.tryParse(v.trim()) ?? fallback;

  return showDialog<ActiveEffect>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Efecto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
              DropdownButtonFormField<String>(
                value: stat,
                items: const [
                  DropdownMenuItem(value: 'ac', child: Text('CA')),
                  DropdownMenuItem(value: 'speed', child: Text('Velocidad')),
                  DropdownMenuItem(value: 'hpMax', child: Text('PG máx.')),
                  DropdownMenuItem(value: 'attack', child: Text('Ataque')),
                  DropdownMenuItem(value: 'damage', child: Text('Daño')),
                  DropdownMenuItem(value: 'save', child: Text('Salvación')),
                ],
                onChanged: (v) => setState(() => stat = v ?? 'ac'),
                decoration: const InputDecoration(labelText: 'Stat'),
              ),
              TextField(controller: value, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor')),
              DropdownButtonFormField<String>(
                value: duration,
                items: const [
                  DropdownMenuItem(value: 'permanent', child: Text('Permanente')),
                  DropdownMenuItem(value: 'encounter', child: Text('Encuentro')),
                  DropdownMenuItem(value: 'shortRest', child: Text('Hasta descanso corto')),
                  DropdownMenuItem(value: 'longRest', child: Text('Hasta descanso largo')),
                  DropdownMenuItem(value: 'custom', child: Text('Personalizada')),
                ],
                onChanged: (v) => setState(() => duration = v ?? 'encounter'),
                decoration: const InputDecoration(labelText: 'Duración'),
              ),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notas')),
              SwitchListTile(
                value: active,
                onChanged: (v) => setState(() => active = v),
                title: const Text('Activo ahora'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              ActiveEffect(
                id: effect.id,
                name: name.text.trim(),
                stat: stat,
                value: parseIntSafe(value.text, effect.value),
                duration: duration,
                notes: notes.text.trim(),
                active: active,
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showCharactersSheet(BuildContext context, CharacterController ctrl) async {
  final nameCtrl = TextEditingController();
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final chars = ctrl.characters;
      final active = ctrl.activeCharacterId;
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Personajes', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await ctrl.createNewBlank();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: chars.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final ch = chars[i];
                  final isActive = ch.id == active;
                  return FantasyCard(
                    onTap: () async {
                      await ctrl.selectCharacter(ch.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Row(
                      children: [
                        Icon(isActive ? Icons.check_circle : Icons.circle_outlined, color: isActive ? AppTheme.gold : AppTheme.goldSoft),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ch.name.isEmpty ? '(sin nombre)' : ch.name),
                              const SizedBox(height: 4),
                              Text(
                                '${ch.race} · ${ch.characterClass} · Nv. ${ch.level}',
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: const Color(0xFFB6A48A)),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'rename') {
                              nameCtrl.text = ch.name;
                              final next = await showDialog<String>(
                                context: ctx,
                                builder: (dctx) => AlertDialog(
                                  title: const Text('Renombrar'),
                                  content: TextField(
                                    controller: nameCtrl,
                                    decoration: const InputDecoration(labelText: 'Nombre'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancelar')),
                                    FilledButton(onPressed: () => Navigator.pop(dctx, nameCtrl.text.trim()), child: const Text('Guardar')),
                                  ],
                                ),
                              );
                              if (next != null && next.isNotEmpty) await ctrl.renameCharacter(ch.id, next);
                            } else if (v == 'duplicate') {
                              await ctrl.duplicateCharacter(ch.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } else if (v == 'delete') {
                              final ok = await _confirmDelete(ctx, 'Borrar personaje', ch.name);
                              if (ok) await ctrl.deleteCharacter(ch.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                            PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
                            PopupMenuItem(value: 'delete', child: Text('Borrar')),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showBackupSheet(BuildContext context, CharacterController ctrl) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              Icon(Icons.cloud_download),
              SizedBox(width: 10),
              Expanded(
                child: Text('Backup', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FantasyCard(
            onTap: () async {
              final json = await ctrl.exportAllToJson();
              await Share.share(json, subject: 'Dungeon Companion Backup');
            },
            child: Row(
              children: const [
                Icon(Icons.upload_file, color: AppTheme.goldSoft),
                SizedBox(width: 12),
                Expanded(child: Text('Exportar backup (JSON)')),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FantasyCard(
            onTap: () async {
              final picked = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: const ['json'],
                withData: true,
              );
              final file = picked?.files.single;
              final bytes = file?.bytes;
              if (bytes == null) return;
              final json = String.fromCharCodes(bytes);
              if (!ctx.mounted) return;
              final replace = await showDialog<bool>(
                context: ctx,
                builder: (dctx) => AlertDialog(
                  title: const Text('Importar backup'),
                  content: const Text('¿Querés reemplazar todo (borrar personajes actuales) o mezclar?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Mezclar')),
                    FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Reemplazar')),
                  ],
                ),
              );
              await ctrl.importFromJson(json, replace: replace == true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Row(
              children: const [
                Icon(Icons.download, color: AppTheme.goldSoft),
                SizedBox(width: 12),
                Expanded(child: Text('Importar backup (JSON)')),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
