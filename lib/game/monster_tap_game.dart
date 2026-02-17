part of '../main.dart';

// Main game class
class MonsterTapGame extends FlameGame with TapCallbacks {
  late Monster monster;
  late SpriteComponent trashBin;
  late ScoreDisplay scoreDisplay;
  late GameOverDisplay gameOverDisplay;
  late RectangleComponent playAreaBackground;
  late RectangleComponent monsterAreaBackground;
  late RectangleComponent areaDivider;
  late SpriteComponent background;
  static const int maxLives = 4;
  static const double baseSpawnInterval = 1.8;
  static const double minSpawnInterval = 0.95;
  static const double spawnIntervalStep = 0.08;
  static const double difficultyTickSeconds = 15;
  static const double baseFallSpeed = 85;
  static const double maxFallSpeed = 170;
  static const double fallSpeedStep = 8;
  static const double goodItemChance = 0.65;
  static const int goodItemPoints = 8;
  static const int badItemPointsPenalty = 3;
  static const int missedGoodItemPointsPenalty = 4;
  static const int badItemDiscardPoints = 2;
  static const int wrongDropPointsPenalty = 3;
  static const int missedBadItemPointsPenalty = 2;
  static const double _dropZoneScale = 0.72;
  static const String _coinsKey = 'coins_total';
  static const String _selectedLevelKey = 'selected_level';
  static const String _unlockedLevelIdsKey = 'unlocked_level_ids';
  static const String _unlockedAccessoryIdsKey = 'unlocked_accessory_ids';
  static const String _equippedAccessoryByTargetKey =
      'equipped_accessory_by_target';
  static const String _selectedMonsterIdKey = 'selected_monster_id';
  static const String _unlockedMonsterIdsKey = 'unlocked_monster_ids';
  static const String _world1HatUnlockedKey = 'skin_world1_hat_unlocked';
  static const String _world1HatEquippedKey = 'skin_world1_hat_equipped';
  static const String _legacyMonsterMainId = AccessoryCatalog.monsterMainId;
  int score = 0;
  int lives = maxLives;
  int bestScore = 0;
  int goodStreak = 0;
  int totalCoins = 0;
  int lastRunCoinsEarned = 0;
  String selectedMonsterId = MonsterCatalog.defaultMonsterId;
  final Set<String> unlockedMonsterIds = <String>{};
  GameLevel selectedLevel = GameLevel.level1;
  final Set<GameLevel> unlockedLevels = <GameLevel>{};
  final Set<String> unlockedAccessoryIds = <String>{};
  final Map<String, String> equippedAccessoryByTarget = <String, String>{};
  bool isGameOver = false;
  bool isStarted = false;
  bool isPaused = false;
  bool isTransitioning = false;
  double survivalTime = 0;
  double _difficultyTimer = 0;
  double currentSpawnInterval = baseSpawnInterval;
  double currentFallSpeed = baseFallSpeed;
  double spawnTimer = 0;
  double _shakeTime = 0;
  static const double _shakeDuration = 0.14;
  static const double _shakeStrength = 9;
  final Random _fxRandom = Random();
  final Random _musicRandom = Random();
  final List<String> _musicTracks = const [
    'bgm_playful_01.mp3',
    'bgm_playful_02.mp3',
  ];
  bool _musicReady = false;
  bool _trashBinActive = false;
  late Sprite _trashBinIdleSprite;
  late Sprite _trashBinActiveSprite;
  static const double monsterAreaRatio = 0.28;
  static const double _monsterXRatio = 0.22;
  static const double _trashBinXRatio = 0.85;

  double get gameplayBottomY => size.y * (1 - monsterAreaRatio);
  double get monsterAreaTopY => gameplayBottomY;
  double get monsterAreaHeight => size.y - monsterAreaTopY;

  static const int level1UnlockScore = 300;
  static const Map<GameLevel, String> _backgroundByLevel = {
    GameLevel.level1: 'backgrounds/bg_meadow.png',
    GameLevel.level2: 'backgrounds/bg_world2.png',
  };
  static const Map<GameLevel, List<String>> _goodItemsByLevel = {
    GameLevel.level1: ['apple', 'banana', 'cookie', 'strawberry'],
    GameLevel.level2: ['cupcake', 'lollipop'],
  };
  static const Map<GameLevel, List<String>> _badItemsByLevel = {
    GameLevel.level1: ['bad_shoe', 'bad_rock', 'bad_soap', 'bad_brick'],
    GameLevel.level2: ['chili', 'onion'],
  };

  @override
  Future<void> onLoad() async {
    final bgSprite = await loadSprite('backgrounds/bg_meadow.png');
    background = SpriteComponent(
      sprite: bgSprite,
      priority: -100,
    );
    add(background);

    // Add monster in dedicated bottom area
    monster = Monster(monsterId: selectedMonsterId)
      ..position = Vector2(
          size.x * _monsterXRatio, monsterAreaTopY + (monsterAreaHeight * 0.6))
      ..anchor = Anchor.center;
    add(monster);

    _trashBinIdleSprite = await loadSprite('trash_bin/trash_bin_idle.png');
    _trashBinActiveSprite = await loadSprite('trash_bin/trash_bin_active.png');
    trashBin = SpriteComponent(
      sprite: _trashBinIdleSprite,
      anchor: Anchor.center,
      priority: 5,
    );
    add(trashBin);

    // Add score display
    scoreDisplay = ScoreDisplay()..position = Vector2(20, 24);
    add(scoreDisplay);
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      selectedLevel,
      _goalText(),
      forceRepaint: true,
    );

    // Add game over display (hidden initially)
    gameOverDisplay = GameOverDisplay()..anchor = Anchor.center;
    add(gameOverDisplay);

    await _loadBestScore();
    await loadCustomizationProgress();
    await _applySelectedMonster();
    await _applyLevelTheme(selectedLevel);
    await _initBackgroundMusic();
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      selectedLevel,
      _goalText(),
      forceRepaint: true,
    );
    _layoutScene();
    _applyMonsterAccessories();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_shakeTime > 0) {
      _shakeTime = max(0, _shakeTime - dt);
    }

    if (!isStarted || isGameOver || isPaused || isTransitioning) return;

    survivalTime += dt;
    _difficultyTimer += dt;
    if (_difficultyTimer >= difficultyTickSeconds) {
      _difficultyTimer = 0;
      currentSpawnInterval =
          max(minSpawnInterval, currentSpawnInterval - spawnIntervalStep);
      currentFallSpeed = min(maxFallSpeed, currentFallSpeed + fallSpeedStep);
    }

    // Spawn items periodically
    spawnTimer += dt;
    if (spawnTimer >= currentSpawnInterval) {
      spawnTimer = 0;
      spawnRandomItem();
    }
  }

  void spawnRandomItem() {
    final random = Random();
    final isGood = random.nextDouble() < goodItemChance;

    final goodList = _goodItemsByLevel[selectedLevel]!;
    final badList = _badItemsByLevel[selectedLevel]!;

    final itemType = isGood
        ? goodList[random.nextInt(goodList.length)]
        : badList[random.nextInt(badList.length)];

    final item = FallingItem(
      itemType: itemType,
      isGood: isGood,
      onDropped: handleItemDropped,
      onMissed: handleItemMissed,
      onDragMoved: handleItemDragMoved,
      fallSpeed: currentFallSpeed,
    )
      ..position = Vector2(random.nextDouble() * (size.x - 90) + 45, -50)
      ..anchor = Anchor.center;

    add(item);
  }

  void handleItemDropped(FallingItem item, Vector2 dropPosition) {
    if (isGameOver || isTransitioning) return;
    _setTrashBinActive(false);
    final onMonster =
        _monsterDropRect().contains(Offset(dropPosition.x, dropPosition.y));
    final onTrashBin =
        _trashBinDropRect().contains(Offset(dropPosition.x, dropPosition.y));

    if (item.isGood && onMonster) {
      goodStreak += 1;
      score += goodItemPoints;
      if (goodStreak >= 3) {
        monster.showStreak();
        add(
          TapBurst(
            position: dropPosition,
            baseColor: const Color(0xFFFFD54F),
            particleCount: 24,
            particleSize: 10,
            lifetime: 0.55,
            spreadSpeed: 210,
            palette: const [
              Color(0xFFFFD54F),
              Color(0xFF81C784),
              Color(0xFF4FC3F7),
              Color(0xFFFF8A65),
              Color(0xFFBA68C8),
            ],
          ),
        );
      } else {
        monster.showHappy();
      }
      add(
        TapBurst(
          position: dropPosition,
          baseColor: const Color(0xFFFFD54F),
          particleCount: 16,
          particleSize: 8,
          lifetime: 0.35,
          spreadSpeed: 180,
        ),
      );
    } else if (!item.isGood && onTrashBin) {
      goodStreak += 1;
      score += badItemDiscardPoints;
      monster.showHappy();
      add(
        TapBurst(
          position: dropPosition,
          baseColor: const Color(0xFF66BB6A),
          particleCount: 14,
          particleSize: 8,
          lifetime: 0.32,
          spreadSpeed: 170,
        ),
      );
    } else {
      goodStreak = 0;
      score -= wrongDropPointsPenalty;
      lives -= 1;
      monster.showOops();
      _triggerScreenShake();
      add(
        TapBurst(
          position: dropPosition,
          baseColor: const Color(0xFFE53935),
          particleCount: 14,
          particleSize: 9,
          lifetime: 0.32,
          spreadSpeed: 170,
        ),
      );
      if (lives <= 0) {
        triggerGameOver();
      }
    }
    _checkLevelUnlockProgress();
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      selectedLevel,
      _goalText(),
    );
    item.removeFromParent();
  }

  void handleItemDragMoved(FallingItem item, Vector2 position) {
    if (isGameOver || isTransitioning) return;
    if (!item.isGood) {
      final overTrashBin =
          _trashBinDropRect().contains(Offset(position.x, position.y));
      _setTrashBinActive(overTrashBin);
      return;
    }
    _setTrashBinActive(false);
  }

  void handleItemMissed(FallingItem item) {
    if (isGameOver || isTransitioning) return;
    _setTrashBinActive(false);

    // Missing any item costs one life.
    goodStreak = 0;
    lives -= 1;
    if (item.isGood) {
      score -= missedGoodItemPointsPenalty;
    } else {
      score -= missedBadItemPointsPenalty;
    }
    monster.showOops();
    _triggerScreenShake();
    _checkLevelUnlockProgress();
    if (lives <= 0) {
      triggerGameOver();
      return;
    }
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      selectedLevel,
      _goalText(),
    );
  }

  void triggerGameOver() {
    isGameOver = true;
    isPaused = false;
    monster.showGameOver();
    _awardRunCoins();
    if (score > bestScore) {
      bestScore = score;
      _saveBestScore();
    }
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      selectedLevel,
      _goalText(),
    );
    gameOverDisplay.show(score, survivalTime);
  }

  void restartGame() {
    score = 0;
    lives = maxLives;
    goodStreak = 0;
    isGameOver = false;
    isPaused = false;
    isTransitioning = false;
    spawnTimer = 0;
    survivalTime = 0;
    _difficultyTimer = 0;
    currentSpawnInterval = baseSpawnInterval;
    currentFallSpeed = baseFallSpeed;
    // Remove all falling items
    children
        .whereType<FallingItem>()
        .toList()
        .forEach((item) => item.removeFromParent());

    gameOverDisplay.hide();
    _setTrashBinActive(false);
    monster.showIdle();
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      selectedLevel,
      _goalText(),
      forceRepaint: true,
    );
    _applyLevelTheme(selectedLevel);
  }

  void startGame() {
    isStarted = true;
    isPaused = false;
    resumeEngine();
    restartGame();
    _playRandomBackgroundTrack();
    // Force one extra HUD repaint right after start to avoid first-frame glyph fallback glitches.
    Future.delayed(const Duration(milliseconds: 1), () {
      if (!isGameOver) {
        scoreDisplay.updateHud(
          score,
          totalCoins,
          lives,
          maxLives,
          selectedLevel,
          _goalText(),
          forceRepaint: true,
        );
      }
    });
  }

  void startNewGameFromMenu() {
    if (!isStarted) return;
    restartGame();
    isPaused = false;
    resumeEngine();
    if (_musicReady) {
      FlameAudio.bgm.resume();
    }
  }

  void _checkLevelUnlockProgress() {
    if (selectedLevel != GameLevel.level1) return;
    if (score < level1UnlockScore) return;
    if (unlockedLevels.contains(GameLevel.level2)) return;
    unlockedLevels.add(GameLevel.level2);
    _saveCustomizationProgress();
  }

  Future<void> _applyLevelTheme(GameLevel level) async {
    background.sprite = await loadSprite(_backgroundByLevel[level]!);
    await monster.loadLevelSkin(level);
    _applyMonsterAccessories();
  }

  String _goalText() {
    if (selectedLevel == GameLevel.level1) {
      if (unlockedLevels.contains(GameLevel.level2)) {
        return 'Goal complete: Level 2 unlocked';
      }
      return 'Goal: reach $level1UnlockScore points to unlock Level 2';
    }
    return 'Goal: survive and collect more gold in Level 2';
  }

  void _triggerScreenShake() {
    _shakeTime = _shakeDuration;
  }

  void pauseGame() {
    if (!isStarted || isGameOver || isPaused) return;
    isPaused = true;
    pauseEngine();
    if (_musicReady) {
      FlameAudio.bgm.pause();
    }
  }

  void resumeGame() {
    if (!isStarted || isGameOver || !isPaused) return;
    isPaused = false;
    resumeEngine();
    if (_musicReady) {
      FlameAudio.bgm.resume();
    }
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    bestScore = prefs.getInt('best_score') ?? 0;
  }

  Future<void> loadCustomizationProgress() async {
    final prefs = await SharedPreferences.getInstance();
    totalCoins = prefs.getInt(_coinsKey) ?? 0;
    unlockedLevels
      ..clear()
      ..addAll(
          _decodeUnlockedLevels(prefs.getStringList(_unlockedLevelIdsKey)));
    if (unlockedLevels.isEmpty) {
      unlockedLevels.add(GameLevel.level1);
    }
    final persistedLevelId = prefs.getString(_selectedLevelKey);
    final persistedLevel = _levelFromId(persistedLevelId);
    if (persistedLevel != null && unlockedLevels.contains(persistedLevel)) {
      selectedLevel = persistedLevel;
    } else {
      selectedLevel = GameLevel.level1;
    }

    unlockedMonsterIds
      ..clear()
      ..addAll(prefs.getStringList(_unlockedMonsterIdsKey) ?? const []);
    if (unlockedMonsterIds.isEmpty) {
      unlockedMonsterIds.add(MonsterCatalog.defaultMonsterId);
    }
    final persistedMonsterId = prefs.getString(_selectedMonsterIdKey);
    if (persistedMonsterId != null &&
        MonsterCatalog.byId(persistedMonsterId) != null &&
        unlockedMonsterIds.contains(persistedMonsterId)) {
      selectedMonsterId = persistedMonsterId;
    } else {
      selectedMonsterId = MonsterCatalog.defaultMonsterId;
      unlockedMonsterIds.add(MonsterCatalog.defaultMonsterId);
    }

    unlockedAccessoryIds
      ..clear()
      ..addAll(prefs.getStringList(_unlockedAccessoryIdsKey) ?? const []);

    equippedAccessoryByTarget.clear();
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

    // Backward compatibility: migrate old world1-hat bool flags.
    final legacyUnlocked = prefs.getBool(_world1HatUnlockedKey) ?? false;
    final legacyEquipped = prefs.getBool(_world1HatEquippedKey) ?? false;
    if (legacyUnlocked) {
      unlockedAccessoryIds.add(AccessoryCatalog.world1PartyHatId);
      if (legacyEquipped) {
        equippedAccessoryByTarget[
                _targetKey(GameLevel.level1, _legacyMonsterMainId)] =
            AccessoryCatalog.world1PartyHatId;
      }
      await _saveCustomizationProgress();
    }

    if (isLoaded) {
      await _applySelectedMonster();
      await _applyLevelTheme(selectedLevel);
      _applyMonsterAccessories();
    }
  }

  Future<void> _saveCustomizationProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, totalCoins);
    await prefs.setString(_selectedLevelKey, selectedLevel.name);
    await prefs.setStringList(
      _unlockedLevelIdsKey,
      unlockedLevels.map((level) => level.name).toList(),
    );
    await prefs.setString(_selectedMonsterIdKey, selectedMonsterId);
    await prefs.setStringList(
        _unlockedMonsterIdsKey, unlockedMonsterIds.toList());
    await prefs.setStringList(
        _unlockedAccessoryIdsKey, unlockedAccessoryIds.toList());
    await prefs.setString(
      _equippedAccessoryByTargetKey,
      jsonEncode(equippedAccessoryByTarget),
    );
    // Keep legacy values in sync while older code/paths may exist.
    await prefs.setBool(_world1HatUnlockedKey, isWorld1HatUnlocked);
    await prefs.setBool(_world1HatEquippedKey, isWorld1HatEquipped);
  }

  void _applyMonsterAccessories() {
    if (!isLoaded || !monster.isLoaded) return;
    final equippedIdForLevel = equippedAccessoryIdForTarget(
      level: selectedLevel,
      monsterId: selectedMonsterId,
    );
    final equippedId = equippedIdForLevel ??
        equippedAccessoryIdForTarget(
          level: GameLevel.level1,
          monsterId: selectedMonsterId,
        );
    final equippedItem =
        equippedId == null ? null : AccessoryCatalog.byId(equippedId);
    final hatItem =
        equippedItem?.slot == AccessorySlot.hat ? equippedItem : null;
    monster.setHatAccessoryAssetPath(hatItem?.assetPath);
  }

  int _calculateCoinsFromScore(int finalScore) {
    if (finalScore <= 0) return 0;
    return max(1, finalScore ~/ 40);
  }

  void _awardRunCoins() {
    final earned = _calculateCoinsFromScore(score);
    lastRunCoinsEarned = earned;
    if (earned <= 0) return;
    totalCoins += earned;
    _saveCustomizationProgress();
  }

  Future<bool> unlockWorld1Hat() async {
    final ok = await unlockAccessory(AccessoryCatalog.world1PartyHatId);
    if (!ok) return false;
    await setAccessoryEquipped(
      AccessoryCatalog.world1PartyHatId,
      level: GameLevel.level1,
      monsterId: _legacyMonsterMainId,
    );
    return true;
  }

  Future<void> setWorld1HatEquipped(bool equipped) async {
    if (equipped) {
      if (!isWorld1HatUnlocked) return;
      await setAccessoryEquipped(
        AccessoryCatalog.world1PartyHatId,
        level: GameLevel.level1,
        monsterId: _legacyMonsterMainId,
      );
      return;
    }
    await clearEquippedAccessory(
      level: GameLevel.level1,
      monsterId: _legacyMonsterMainId,
    );
  }

  List<AccessoryItem> accessoriesFor({
    required GameLevel level,
    required String monsterId,
  }) {
    return AccessoryCatalog.forMonster(level: level, monsterId: monsterId);
  }

  bool isAccessoryUnlocked(String accessoryId) {
    return unlockedAccessoryIds.contains(accessoryId);
  }

  String? equippedAccessoryIdForTarget({
    required GameLevel level,
    required String monsterId,
  }) {
    return equippedAccessoryByTarget[_targetKey(level, monsterId)];
  }

  bool isAccessoryEquipped({
    required String accessoryId,
    required GameLevel level,
    required String monsterId,
  }) {
    return equippedAccessoryIdForTarget(level: level, monsterId: monsterId) ==
        accessoryId;
  }

  Future<bool> unlockAccessory(String accessoryId) async {
    if (isAccessoryUnlocked(accessoryId)) return true;
    final item = AccessoryCatalog.byId(accessoryId);
    if (item == null) return false;
    if (totalCoins < item.cost) return false;
    totalCoins -= item.cost;
    unlockedAccessoryIds.add(accessoryId);
    await _saveCustomizationProgress();
    return true;
  }

  Future<void> setAccessoryEquipped(
    String accessoryId, {
    required GameLevel level,
    required String monsterId,
  }) async {
    if (!isAccessoryUnlocked(accessoryId)) return;
    equippedAccessoryByTarget[_targetKey(level, monsterId)] = accessoryId;
    await _saveCustomizationProgress();
    _applyMonsterAccessories();
  }

  Future<void> clearEquippedAccessory({
    required GameLevel level,
    required String monsterId,
  }) async {
    equippedAccessoryByTarget.remove(_targetKey(level, monsterId));
    await _saveCustomizationProgress();
    _applyMonsterAccessories();
  }

  bool get isWorld1HatUnlocked =>
      isAccessoryUnlocked(AccessoryCatalog.world1PartyHatId);
  bool get isWorld1HatEquipped => isAccessoryEquipped(
        accessoryId: AccessoryCatalog.world1PartyHatId,
        level: GameLevel.level1,
        monsterId: _legacyMonsterMainId,
      );

  List<GameLevel> get availableLevels => GameLevel.values;

  bool isLevelUnlocked(GameLevel level) {
    return unlockedLevels.contains(level);
  }

  Future<void> selectLevel(GameLevel level) async {
    if (!isLevelUnlocked(level)) return;
    selectedLevel = level;
    await _saveCustomizationProgress();
    if (isStarted) {
      restartGame();
    } else if (isLoaded) {
      await _applyLevelTheme(selectedLevel);
      scoreDisplay.updateHud(
        score,
        totalCoins,
        lives,
        maxLives,
        selectedLevel,
        _goalText(),
        forceRepaint: true,
      );
    }
  }

  List<MonsterCharacter> get availableMonsters => MonsterCatalog.characters;

  bool isMonsterUnlocked(String monsterId) {
    return unlockedMonsterIds.contains(monsterId);
  }

  bool isMonsterSelected(String monsterId) {
    return selectedMonsterId == monsterId;
  }

  Future<bool> unlockMonster(String monsterId) async {
    if (isMonsterUnlocked(monsterId)) return true;
    final character = MonsterCatalog.byId(monsterId);
    if (character == null) return false;
    if (totalCoins < character.unlockCost) return false;
    totalCoins -= character.unlockCost;
    unlockedMonsterIds.add(monsterId);
    await _saveCustomizationProgress();
    return true;
  }

  Future<void> selectMonster(String monsterId) async {
    if (!isMonsterUnlocked(monsterId)) return;
    if (selectedMonsterId == monsterId) return;
    selectedMonsterId = monsterId;
    await _saveCustomizationProgress();
    await _applySelectedMonster();
    _applyMonsterAccessories();
  }

  String _targetKey(GameLevel level, String monsterId) {
    return '${level.name}:$monsterId';
  }

  GameLevel? _levelFromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final level in GameLevel.values) {
      if (level.name == id) return level;
    }
    return null;
  }

  Set<GameLevel> _decodeUnlockedLevels(List<String>? ids) {
    if (ids == null || ids.isEmpty) {
      return <GameLevel>{GameLevel.level1};
    }
    final result = <GameLevel>{};
    for (final id in ids) {
      final level = _levelFromId(id);
      if (level != null) {
        result.add(level);
      }
    }
    result.add(GameLevel.level1);
    return result;
  }

  Future<void> _applySelectedMonster() async {
    if (!isLoaded || !monster.isLoaded) return;
    await monster.setMonsterId(selectedMonsterId);
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', bestScore);
  }

  Future<void> _initBackgroundMusic() async {
    FlameAudio.audioCache.prefix = 'assets/sounds/';
    await FlameAudio.audioCache.loadAll(_musicTracks);
    FlameAudio.bgm.initialize();
    _musicReady = true;
  }

  void _playRandomBackgroundTrack() {
    if (!_musicReady) return;
    final track = _musicTracks[_musicRandom.nextInt(_musicTracks.length)];
    FlameAudio.bgm.stop();
    FlameAudio.bgm.play(track, volume: 0.28);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Tap handled by GameOverDisplay
  }

  @override
  Color backgroundColor() => const Color(0xFF2A2A2A);

  @override
  void onRemove() {
    FlameAudio.bgm.stop();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (_shakeTime > 0) {
      final intensity = (_shakeTime / _shakeDuration).clamp(0.0, 1.0);
      final dx = (_fxRandom.nextDouble() * 2 - 1) * _shakeStrength * intensity;
      final dy = (_fxRandom.nextDouble() * 2 - 1) * _shakeStrength * intensity;
      canvas.save();
      canvas.translate(dx, dy);
      super.render(canvas);
      canvas.restore();
      return;
    }
    super.render(canvas);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!isLoaded) return;
    _layoutScene();
  }

  void _layoutScene() {
    final bottomY = gameplayBottomY;
    final overlaySize = Vector2(size.x * 0.92, min(520.0, bottomY * 0.95));

    background
      ..position = Vector2.zero()
      ..size = size;

    monster.position = Vector2(
      size.x * _monsterXRatio,
      monsterAreaTopY + (monsterAreaHeight * 0.6),
    );
    trashBin
      ..position = Vector2(
        size.x * _trashBinXRatio,
        monsterAreaTopY + (monsterAreaHeight * 0.62),
      )
      ..size = Vector2(size.x * 0.19, size.x * 0.19);
    scoreDisplay.position = Vector2(20, 24);

    gameOverDisplay
      ..position = Vector2(size.x / 2, bottomY / 2)
      ..setDisplaySize(overlaySize);
  }

  Rect _monsterDropRect() {
    return Rect.fromCenter(
      center: Offset(monster.position.x, monster.position.y),
      width: monster.size.x * _dropZoneScale,
      height: monster.size.y * _dropZoneScale,
    );
  }

  Rect _trashBinDropRect() {
    return Rect.fromCenter(
      center: Offset(trashBin.position.x, trashBin.position.y),
      width: trashBin.size.x * _dropZoneScale,
      height: trashBin.size.y * _dropZoneScale,
    );
  }

  void _setTrashBinActive(bool active) {
    if (_trashBinActive == active) return;
    _trashBinActive = active;
    trashBin.sprite = active ? _trashBinActiveSprite : _trashBinIdleSprite;
  }
}
