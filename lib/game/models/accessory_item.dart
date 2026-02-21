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
  static const String _legacySavedPartyHatId = 'legacy_monster_main_hat_party';

  static String _idFrom({
    required String monsterId,
    required GameLevel level,
    required AccessorySlot slot,
    required String assetPath,
  }) {
    final fileName = assetPath.split('/').last;
    final baseName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final safeBase = baseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '${level.id}_${monsterId}_${slot.name}_$safeBase';
  }

  static AccessoryItem _item({
    required String label,
    required String monsterId,
    required GameLevel level,
    required AccessorySlot slot,
    required int cost,
    required String assetPath,
  }) {
    return AccessoryItem(
      id: _idFrom(
        monsterId: monsterId,
        level: level,
        slot: slot,
        assetPath: assetPath,
      ),
      label: label,
      monsterId: monsterId,
      level: level,
      slot: slot,
      cost: cost,
      assetPath: assetPath,
    );
  }

  static final List<AccessoryItem> items = [
    _item(
      label: 'Cute Beanie Hat',
      monsterId: monsterMainId,
      level: GameLevel.level1,
      slot: AccessorySlot.hat,
      cost: 150,
      assetPath: 'characters/monster_main/accessories/cute_beanie_hat.png',
    )
  ];

  static String get legacyHatMigrationTargetId {
    for (final item in items) {
      if (item.monsterId == monsterMainId &&
          item.level == GameLevel.level1 &&
          item.slot == AccessorySlot.hat) {
        return item.id;
      }
    }
    return _legacySavedPartyHatId;
  }

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
