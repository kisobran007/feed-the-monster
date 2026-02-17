part of '../../main.dart';

class MonsterCharacter {
  final String id;
  final String label;
  final int unlockCost;

  const MonsterCharacter({
    required this.id,
    required this.label,
    required this.unlockCost,
  });
}

class MonsterCatalog {
  static const String monsterMainId = 'monster_main';
  static const String monsterBuddyId = 'monster_buddy';
  static const String defaultMonsterId = monsterMainId;

  static const List<MonsterCharacter> characters = [
    MonsterCharacter(
      id: monsterMainId,
      label: 'Main Monster',
      unlockCost: 0,
    ),
    MonsterCharacter(
      id: monsterBuddyId,
      label: 'Buddy Monster',
      unlockCost: 250,
    ),
  ];

  static MonsterCharacter? byId(String id) {
    for (final character in characters) {
      if (character.id == id) return character;
    }
    return null;
  }
}
