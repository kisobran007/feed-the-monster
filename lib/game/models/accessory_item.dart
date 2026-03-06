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
  final AccessorySlot slot;
  final int cost;
  final String assetPath;

  AccessoryItem({
    required this.id,
    required this.label,
    required this.monsterId,
    required this.slot,
    required this.cost,
    required this.assetPath,
  });
}

class AccessoryCatalog {
  static const String monsterMainId = MonsterCatalog.monsterMainId;

  static String _idFrom({
    required String monsterId,
    required AccessorySlot slot,
    required String assetPath,
  }) {
    final fileName = assetPath.split('/').last;
    final baseName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final safeBase = baseName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '${monsterId}_${slot.name}_$safeBase';
  }

  static AccessoryItem _item({
    required String label,
    required String monsterId,
    required AccessorySlot slot,
    required int cost,
    required String assetPath,
  }) {
    return AccessoryItem(
      id: _idFrom(
        monsterId: monsterId,
        slot: slot,
        assetPath: assetPath,
      ),
      label: label,
      monsterId: monsterId,
      slot: slot,
      cost: cost,
      assetPath: assetPath,
    );
  }

  static final List<AccessoryItem> items = [
    _item(
      label: 'Cute Beanie Hat',
      monsterId: monsterMainId,
      slot: AccessorySlot.hat,
      cost: 150,
      assetPath: 'characters/monster_main/accessories/cute_beanie_hat.png',
    )
  ];

  static AccessoryItem? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<AccessoryItem> forMonster({
    required String monsterId,
  }) {
    return items.where((item) => item.monsterId == monsterId).toList();
  }
}
