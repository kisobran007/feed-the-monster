part of '../../main.dart';

class GameProgressData {
  final int totalCoins;
  final int unlockedLevel;
  final Map<String, int> bestStarsByLevel;
  final GameLevel selectedLevel;
  final String selectedMonsterId;
  final Set<String> unlockedMonsterIds;
  final Set<String> unlockedAccessoryIds;
  final Map<String, String> equippedAccessoryByTarget;

  const GameProgressData({
    required this.totalCoins,
    required this.unlockedLevel,
    required this.bestStarsByLevel,
    required this.selectedLevel,
    required this.selectedMonsterId,
    required this.unlockedMonsterIds,
    required this.unlockedAccessoryIds,
    required this.equippedAccessoryByTarget,
  });
}

class GameProgressRepository {
  static const String _coinsKey = 'coins_total';
  static const String _selectedLevelKey = 'selected_level';
  static const String _unlockedLevelKey = 'unlockedLevel';
  static const String _legacyUnlockedLevelIdsKey = 'unlocked_level_ids';
  static const String _bestStarsByLevelKey = 'best_stars_by_level';
  static const String _unlockedAccessoryIdsKey = 'unlocked_accessory_ids';
  static const String _equippedAccessoryByTargetKey =
      'equipped_accessory_by_target';
  static const String _selectedMonsterIdKey = 'selected_monster_id';
  static const String _unlockedMonsterIdsKey = 'unlocked_monster_ids';
  static const String _world1HatUnlockedKey = 'skin_world1_hat_unlocked';
  static const String _world1HatEquippedKey = 'skin_world1_hat_equipped';

  Future<GameProgressData> load() async {
    final prefs = await SharedPreferences.getInstance();

    final totalCoins = prefs.getInt(_coinsKey) ?? 0;
    final bestStarsByLevel = <String, int>{};
    final encodedStars = prefs.getString(_bestStarsByLevelKey);
    if (encodedStars != null && encodedStars.isNotEmpty) {
      final decoded = jsonDecode(encodedStars);
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((key, value) {
          if (value is int) {
            bestStarsByLevel[key] = value.clamp(0, 3).toInt();
          }
        });
      }
    }

    final persistedUnlockedLevel = prefs.getInt(_unlockedLevelKey);
    var unlockedLevel = max(1, persistedUnlockedLevel ?? 1);
    final legacyUnlockedIds = prefs.getStringList(_legacyUnlockedLevelIdsKey);
    if (persistedUnlockedLevel == null &&
        legacyUnlockedIds != null &&
        legacyUnlockedIds.isNotEmpty) {
      var legacyMax = 1;
      for (final id in legacyUnlockedIds) {
        final level = GameLevel.fromId(id);
        if (level != null) {
          legacyMax = max(legacyMax, level.levelNumber);
        }
      }
      unlockedLevel = max(unlockedLevel, legacyMax);
    }

    if (bestStarsByLevel.isEmpty && unlockedLevel > 1) {
      for (final level in GameLevel.values) {
        if (level.levelNumber < unlockedLevel) {
          bestStarsByLevel[level.id] = 1;
        }
      }
    }

    var starsUnlockedLevel = 1;
    for (var levelNumber = 2;
        levelNumber <= GameLevel.values.length;
        levelNumber++) {
      final previous = GameLevel.fromLevelNumber(levelNumber - 1);
      if (previous == null) continue;
      final previousStars = bestStarsByLevel[previous.id] ?? 0;
      if (previousStars >= 1) {
        starsUnlockedLevel = levelNumber;
      } else {
        break;
      }
    }
    unlockedLevel = max(unlockedLevel, starsUnlockedLevel);

    final persistedLevel = GameLevel.fromId(prefs.getString(_selectedLevelKey));
    final selectedLevel = persistedLevel != null &&
            persistedLevel.levelNumber <= unlockedLevel
        ? persistedLevel
        : GameLevel.level1;

    final unlockedMonsterIds =
        (prefs.getStringList(_unlockedMonsterIdsKey) ?? const <String>[])
            .toSet();
    if (unlockedMonsterIds.isEmpty) {
      unlockedMonsterIds.add(MonsterCatalog.defaultMonsterId);
    }

    var selectedMonsterId = prefs.getString(_selectedMonsterIdKey);
    if (selectedMonsterId == null ||
        MonsterCatalog.byId(selectedMonsterId) == null ||
        !unlockedMonsterIds.contains(selectedMonsterId)) {
      selectedMonsterId = MonsterCatalog.defaultMonsterId;
      unlockedMonsterIds.add(MonsterCatalog.defaultMonsterId);
    }

    final unlockedAccessoryIds =
        (prefs.getStringList(_unlockedAccessoryIdsKey) ?? const <String>[])
            .toSet();

    final equippedAccessoryByTarget = <String, String>{};
    final encodedEquipped = prefs.getString(_equippedAccessoryByTargetKey);
    if (encodedEquipped != null && encodedEquipped.isNotEmpty) {
      final decoded = jsonDecode(encodedEquipped);
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((key, value) {
          if (value is String) {
            var normalizedKey = key;
            if (normalizedKey.startsWith('world1:')) {
              normalizedKey = normalizedKey.replaceFirst('world1:', 'level1:');
            } else if (normalizedKey.startsWith('world2:')) {
              normalizedKey = normalizedKey.replaceFirst('world2:', 'level2:');
            }
            equippedAccessoryByTarget[normalizedKey] = value;
          }
        });
      }
    }

    final legacyUnlocked = prefs.getBool(_world1HatUnlockedKey) ?? false;
    final legacyEquipped = prefs.getBool(_world1HatEquippedKey) ?? false;
    if (legacyUnlocked) {
      unlockedAccessoryIds.add(AccessoryCatalog.world1PartyHatId);
      if (legacyEquipped) {
        equippedAccessoryByTarget[
                '${GameLevel.level1.id}:${AccessoryCatalog.monsterMainId}'] =
            AccessoryCatalog.world1PartyHatId;
      }
    }

    return GameProgressData(
      totalCoins: totalCoins,
      unlockedLevel: unlockedLevel,
      bestStarsByLevel: bestStarsByLevel,
      selectedLevel: selectedLevel,
      selectedMonsterId: selectedMonsterId,
      unlockedMonsterIds: unlockedMonsterIds,
      unlockedAccessoryIds: unlockedAccessoryIds,
      equippedAccessoryByTarget: equippedAccessoryByTarget,
    );
  }

  Future<void> save({
    required int totalCoins,
    required GameLevel selectedLevel,
    required int unlockedLevel,
    required Map<String, int> bestStarsByLevel,
    required String selectedMonsterId,
    required Set<String> unlockedMonsterIds,
    required Set<String> unlockedAccessoryIds,
    required Map<String, String> equippedAccessoryByTarget,
    required bool world1HatUnlocked,
    required bool world1HatEquipped,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, totalCoins);
    await prefs.setString(_selectedLevelKey, selectedLevel.id);
    await prefs.setInt(_unlockedLevelKey, unlockedLevel);
    await prefs.setString(
      _bestStarsByLevelKey,
      jsonEncode(
        bestStarsByLevel.map(
          (key, value) => MapEntry(key, value.clamp(0, 3).toInt()),
        ),
      ),
    );

    final legacyUnlockedIds = GameLevel.values
        .where((level) => level.levelNumber <= unlockedLevel)
        .map((level) => level.id)
        .toList();
    await prefs.setStringList(_legacyUnlockedLevelIdsKey, legacyUnlockedIds);

    await prefs.setString(_selectedMonsterIdKey, selectedMonsterId);
    await prefs.setStringList(_unlockedMonsterIdsKey, unlockedMonsterIds.toList());
    await prefs.setStringList(
      _unlockedAccessoryIdsKey,
      unlockedAccessoryIds.toList(),
    );
    await prefs.setString(
      _equippedAccessoryByTargetKey,
      jsonEncode(equippedAccessoryByTarget),
    );
    await prefs.setBool(_world1HatUnlockedKey, world1HatUnlocked);
    await prefs.setBool(_world1HatEquippedKey, world1HatEquipped);
  }
}
