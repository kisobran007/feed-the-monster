part of '../../main.dart';

enum AccessorySlot {
  hat,
  shoes,
  outfit,
}

class AccessoryItem {
  final String id;
  final String label;
  final String monsterId;
  final GameLevel level;
  final AccessorySlot slot;
  final int cost;
  final String assetPath;

  AccessoryItem({
    required this.id,
    required this.label,
    required this.monsterId,
    required this.level,
    required this.slot,
    required this.cost,
    required this.assetPath,
  });
}

class AccessoryCatalog {
  static const String monsterMainId = MonsterCatalog.monsterMainId;
  static const String world1PartyHatId = 'world1_monster_main_hat_party';
  static const String world1CrownHatId = 'world1_monster_main_hat_crown';
  static const String world1WizardHatId = 'world1_monster_main_hat_wizard';

  static final List<AccessoryItem> items = [
    AccessoryItem(
      id: world1PartyHatId,
      label: 'Party Hat',
      monsterId: monsterMainId,
      level: GameLevel.level1,
      slot: AccessorySlot.hat,
      cost: 150,
      assetPath: 'characters/monster_main/accessories/hat_party.png',
    ),
    AccessoryItem(
      id: world1CrownHatId,
      label: 'Crown Hat',
      monsterId: monsterMainId,
      level: GameLevel.level1,
      slot: AccessorySlot.hat,
      cost: 250,
      assetPath: 'characters/monster_main/accessories/hat_crown.png',
    ),
    AccessoryItem(
      id: world1WizardHatId,
      label: 'Wizard Hat',
      monsterId: monsterMainId,
      level: GameLevel.level1,
      slot: AccessorySlot.hat,
      cost: 400,
      assetPath: 'characters/monster_main/accessories/hat_wizard.png',
    ),
  ];

  static AccessoryItem? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<AccessoryItem> forMonster({
    required GameLevel level,
    required String monsterId,
  }) {
    return items
        .where((item) => item.level == level && item.monsterId == monsterId)
        .toList();
  }
}
