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

  Future<GameProgressData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final localData = _loadFromPrefs(prefs);

    final cloudData = await _loadCloudProgress();
    if (cloudData == null) {
      await _saveCloudProgress(localData);
      return localData;
    }

    final mergedData = _mergeProgress(localData, cloudData);
    await _saveToPrefs(prefs, data: mergedData);
    await _saveCloudProgress(mergedData);
    return mergedData;
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
    await prefs.setStringList(
        _unlockedMonsterIdsKey, unlockedMonsterIds.toList());
    await prefs.setStringList(
      _unlockedAccessoryIdsKey,
      unlockedAccessoryIds.toList(),
    );
    await prefs.setString(
      _equippedAccessoryByTargetKey,
      jsonEncode(equippedAccessoryByTarget),
    );

    await _saveCloudProgress(
      GameProgressData(
        totalCoins: totalCoins,
        unlockedLevel: unlockedLevel,
        bestStarsByLevel: bestStarsByLevel,
        selectedLevel: selectedLevel,
        selectedMonsterId: selectedMonsterId,
        unlockedMonsterIds: unlockedMonsterIds,
        unlockedAccessoryIds: unlockedAccessoryIds,
        equippedAccessoryByTarget: equippedAccessoryByTarget,
      ),
    );
  }

  GameProgressData _loadFromPrefs(SharedPreferences prefs) {
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

    final starsUnlockedLevel = _highestUnlockedFromStars(bestStarsByLevel);
    unlockedLevel = max(unlockedLevel, starsUnlockedLevel);

    final persistedLevel = GameLevel.fromId(prefs.getString(_selectedLevelKey));
    final selectedLevel =
        persistedLevel != null && persistedLevel.levelNumber <= unlockedLevel
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

    final unlockedAccessoryIds = <String>{};
    final rawUnlockedAccessoryIds =
        prefs.getStringList(_unlockedAccessoryIdsKey) ?? const <String>[];
    for (final rawId in rawUnlockedAccessoryIds) {
      if (AccessoryCatalog.byId(rawId) != null) {
        unlockedAccessoryIds.add(rawId);
      }
    }

    final equippedAccessoryByTarget = <String, String>{};
    final encodedEquipped = prefs.getString(_equippedAccessoryByTargetKey);
    if (encodedEquipped != null && encodedEquipped.isNotEmpty) {
      final decoded = jsonDecode(encodedEquipped);
      if (decoded is Map<String, dynamic>) {
        decoded.forEach((key, value) {
          if (value is String) {
            if (AccessoryCatalog.byId(value) != null) {
              equippedAccessoryByTarget[key] = value;
            }
          }
        });
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

  Future<void> _saveToPrefs(
    SharedPreferences prefs, {
    required GameProgressData data,
  }) async {
    await save(
      totalCoins: data.totalCoins,
      selectedLevel: data.selectedLevel,
      unlockedLevel: data.unlockedLevel,
      bestStarsByLevel: data.bestStarsByLevel,
      selectedMonsterId: data.selectedMonsterId,
      unlockedMonsterIds: data.unlockedMonsterIds,
      unlockedAccessoryIds: data.unlockedAccessoryIds,
      equippedAccessoryByTarget: data.equippedAccessoryByTarget,
    );
  }

  int _highestUnlockedFromStars(Map<String, int> bestStarsByLevel) {
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
    return starsUnlockedLevel;
  }

  GameProgressData _mergeProgress(
    GameProgressData local,
    GameProgressData cloud,
  ) {
    final mergedBestStars = <String, int>{};
    for (final level in GameLevel.values) {
      final localStars = local.bestStarsByLevel[level.id] ?? 0;
      final cloudStars = cloud.bestStarsByLevel[level.id] ?? 0;
      final mergedStars = max(localStars, cloudStars).clamp(0, 3).toInt();
      if (mergedStars > 0) {
        mergedBestStars[level.id] = mergedStars;
      }
    }

    final mergedUnlockedMonsters = <String>{
      ...local.unlockedMonsterIds,
      ...cloud.unlockedMonsterIds,
      MonsterCatalog.defaultMonsterId,
    };
    final mergedUnlockedAccessories = <String>{
      ...local.unlockedAccessoryIds,
      ...cloud.unlockedAccessoryIds,
    };
    final mergedEquipped = <String, String>{
      ...cloud.equippedAccessoryByTarget,
    };
    local.equippedAccessoryByTarget.forEach((key, value) {
      mergedEquipped.putIfAbsent(key, () => value);
    });

    final mergedUnlockedLevel = max(
      max(local.unlockedLevel, cloud.unlockedLevel),
      _highestUnlockedFromStars(mergedBestStars),
    );

    final selectedLevel = _pickSelectedLevel(
      preferred: cloud.selectedLevel,
      fallback: local.selectedLevel,
      unlockedLevel: mergedUnlockedLevel,
    );
    final selectedMonsterId = _pickSelectedMonster(
      preferred: cloud.selectedMonsterId,
      fallback: local.selectedMonsterId,
      unlockedMonsterIds: mergedUnlockedMonsters,
    );

    return GameProgressData(
      totalCoins: max(local.totalCoins, cloud.totalCoins),
      unlockedLevel: mergedUnlockedLevel,
      bestStarsByLevel: mergedBestStars,
      selectedLevel: selectedLevel,
      selectedMonsterId: selectedMonsterId,
      unlockedMonsterIds: mergedUnlockedMonsters,
      unlockedAccessoryIds: mergedUnlockedAccessories,
      equippedAccessoryByTarget: mergedEquipped,
    );
  }

  GameLevel _pickSelectedLevel({
    required GameLevel preferred,
    required GameLevel fallback,
    required int unlockedLevel,
  }) {
    if (preferred.levelNumber <= unlockedLevel) return preferred;
    if (fallback.levelNumber <= unlockedLevel) return fallback;
    return GameLevel.level1;
  }

  String _pickSelectedMonster({
    required String preferred,
    required String fallback,
    required Set<String> unlockedMonsterIds,
  }) {
    if (unlockedMonsterIds.contains(preferred) &&
        MonsterCatalog.byId(preferred) != null) {
      return preferred;
    }
    if (unlockedMonsterIds.contains(fallback) &&
        MonsterCatalog.byId(fallback) != null) {
      return fallback;
    }
    return MonsterCatalog.defaultMonsterId;
  }

  String? _currentUserId() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<GameProgressData?> _loadCloudProgress() async {
    final uid = _currentUserId();
    if (uid == null) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('game')
          .doc('progress')
          .get();
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return _fromCloudMap(data);
    } catch (e) {
      debugPrint('Cloud load failed: $e');
      return null;
    }
  }

  Future<void> _saveCloudProgress(GameProgressData data) async {
    final uid = _currentUserId();
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('game')
          .doc('progress')
          .set(_toCloudMap(data), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Cloud save failed: $e');
    }
  }

  Map<String, dynamic> _toCloudMap(GameProgressData data) {
    return <String, dynamic>{
      'totalCoins': data.totalCoins,
      'unlockedLevel': data.unlockedLevel,
      'bestStarsByLevel': data.bestStarsByLevel,
      'selectedLevel': data.selectedLevel.id,
      'selectedMonsterId': data.selectedMonsterId,
      'unlockedMonsterIds': data.unlockedMonsterIds.toList(),
      'unlockedAccessoryIds': data.unlockedAccessoryIds.toList(),
      'equippedAccessoryByTarget': data.equippedAccessoryByTarget,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  GameProgressData? _fromCloudMap(Map<String, dynamic> data) {
    final totalCoins = _asInt(data['totalCoins']);
    final unlockedLevelValue = _asInt(data['unlockedLevel']);
    if (totalCoins == null || unlockedLevelValue == null) {
      return null;
    }

    final bestStarsByLevel = <String, int>{};
    final rawStars = data['bestStarsByLevel'];
    if (rawStars is Map<String, dynamic>) {
      rawStars.forEach((key, value) {
        final stars = _asInt(value);
        if (stars != null) {
          bestStarsByLevel[key] = stars.clamp(0, 3).toInt();
        }
      });
    }

    final starsUnlockedLevel = _highestUnlockedFromStars(bestStarsByLevel);
    final unlockedLevel = max(1, max(unlockedLevelValue, starsUnlockedLevel));

    final selectedLevelRaw = data['selectedLevel'];
    final selectedLevelParsed =
        selectedLevelRaw is String ? GameLevel.fromId(selectedLevelRaw) : null;
    final selectedLevel = selectedLevelParsed != null &&
            selectedLevelParsed.levelNumber <= unlockedLevel
        ? selectedLevelParsed
        : GameLevel.level1;

    final unlockedMonsterIds = <String>{};
    final rawMonsters = data['unlockedMonsterIds'];
    if (rawMonsters is List) {
      for (final value in rawMonsters) {
        if (value is String) unlockedMonsterIds.add(value);
      }
    }
    unlockedMonsterIds.add(MonsterCatalog.defaultMonsterId);

    var selectedMonsterId = data['selectedMonsterId'];
    if (selectedMonsterId is! String ||
        MonsterCatalog.byId(selectedMonsterId) == null ||
        !unlockedMonsterIds.contains(selectedMonsterId)) {
      selectedMonsterId = MonsterCatalog.defaultMonsterId;
    }

    final unlockedAccessoryIds = <String>{};
    final rawAccessories = data['unlockedAccessoryIds'];
    if (rawAccessories is List) {
      for (final value in rawAccessories) {
        if (value is String && AccessoryCatalog.byId(value) != null) {
          unlockedAccessoryIds.add(value);
        }
      }
    }

    final equippedAccessoryByTarget = <String, String>{};
    final rawEquipped = data['equippedAccessoryByTarget'];
    if (rawEquipped is Map<String, dynamic>) {
      rawEquipped.forEach((key, value) {
        if (value is String) {
          if (AccessoryCatalog.byId(value) != null) {
            equippedAccessoryByTarget[key] = value;
          }
        }
      });
    }

    return GameProgressData(
      totalCoins: max(0, totalCoins),
      unlockedLevel: unlockedLevel,
      bestStarsByLevel: bestStarsByLevel,
      selectedLevel: selectedLevel,
      selectedMonsterId: selectedMonsterId,
      unlockedMonsterIds: unlockedMonsterIds,
      unlockedAccessoryIds: unlockedAccessoryIds,
      equippedAccessoryByTarget: equippedAccessoryByTarget,
    );
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
