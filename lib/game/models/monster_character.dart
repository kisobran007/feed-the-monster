part of '../../main.dart';

class MonsterCharacter {
  final String id;
  final String label;
  final String assetFolder;
  final int unlockCost;

  const MonsterCharacter({
    required this.id,
    required this.label,
    required this.assetFolder,
    required this.unlockCost,
  });
}

class MonsterCatalog {
  static const String monsterMainId = 'monster_main';
  static const String monsterBuddyId = 'monster_buddy';
  static const String neonMonsterId = 'monster_neon';
  static const String royalMonsterId = 'monster_royal';
  static const String defaultMonsterId = monsterMainId;

  static const List<MonsterCharacter> characters = [
    MonsterCharacter(
      id: monsterMainId,
      label: 'Main Monster',
      assetFolder: monsterMainId,
      unlockCost: 0,
    ),
    MonsterCharacter(
      id: monsterBuddyId,
      label: 'Buddy Monster',
      assetFolder: monsterBuddyId,
      unlockCost: 300,
    ),
    MonsterCharacter(
      id: neonMonsterId,
      label: 'Neon Monster',
      assetFolder: neonMonsterId,
      unlockCost: 500,
    ),
    MonsterCharacter(
      id: royalMonsterId,
      label: 'Royal Monster',
      assetFolder: royalMonsterId,
      unlockCost: 800,
    ),
  ];

  static MonsterCharacter? byId(String id) {
    for (final character in characters) {
      if (character.id == id) return character;
    }
    return null;
  }
}
