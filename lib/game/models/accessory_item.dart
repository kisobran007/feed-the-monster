part of '../../main.dart';

enum AccessorySlot {
  hat,
}

class AccessoryItem {
  final String id;
  final String label;
  final String monsterId;
  final GameWorld world;
  final AccessorySlot slot;
  final int cost;
  final String assetPath;

  const AccessoryItem({
    required this.id,
    required this.label,
    required this.monsterId,
    required this.world,
    required this.slot,
    required this.cost,
    required this.assetPath,
  });
}

class AccessoryCatalog {
  static const String monsterMainId = 'monster_main';
  static const String world1PartyHatId = 'world1_monster_main_hat_party';
  static const String world1CrownHatId = 'world1_monster_main_hat_crown';

  static const List<AccessoryItem> items = [
    AccessoryItem(
      id: world1PartyHatId,
      label: 'Party Hat',
      monsterId: monsterMainId,
      world: GameWorld.world1,
      slot: AccessorySlot.hat,
      cost: 60,
      assetPath: 'characters/world1/monster_main/accessories/hat_party.png',
    ),
    AccessoryItem(
      id: world1CrownHatId,
      label: 'Crown Hat',
      monsterId: monsterMainId,
      world: GameWorld.world1,
      slot: AccessorySlot.hat,
      cost: 140,
      assetPath: 'characters/world1/monster_main/accessories/hat_crown.png',
    ),
  ];

  static AccessoryItem? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<AccessoryItem> forMonster({
    required GameWorld world,
    required String monsterId,
  }) {
    return items
        .where((item) => item.world == world && item.monsterId == monsterId)
        .toList();
  }
}
