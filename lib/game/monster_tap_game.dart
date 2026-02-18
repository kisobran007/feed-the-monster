part of '../main.dart';

class MonsterTapGame extends FlameGame with TapCallbacks {
  late Monster monster;
  late SpriteComponent trashBin;
  late ObjectiveDisplay objectiveDisplay;
  late GameOverDisplay gameOverDisplay;
  late SpriteComponent background;
  final ObjectiveEngine _objectiveEngine = ObjectiveEngine();
  final GameProgressRepository _progressRepository = GameProgressRepository();
  final SpawnController _spawnController = SpawnController();
  final AudioController _audioController = AudioController();

  static const double goodItemChance = 0.65;
  static const double _dropZoneScale = 0.72;

  static const String _legacyMonsterMainId = AccessoryCatalog.monsterMainId;

  int mistakes = 0;
  int totalCoins = 0;
  int lastRunCoinsEarned = 0;
  int unlockedLevel = 1;
  String selectedMonsterId = MonsterCatalog.defaultMonsterId;
  final Set<String> unlockedMonsterIds = <String>{};
  GameLevel selectedLevel = GameLevel.level1;
  final Set<String> unlockedAccessoryIds = <String>{};
  final Map<String, String> equippedAccessoryByTarget = <String, String>{};

  bool isGameOver = false;
  bool isStarted = false;
  bool isPaused = false;
  bool isTransitioning = false;
  bool _runRewardGranted = false;

  double survivalTime = 0;
  double _shakeTime = 0;
  static const double _shakeDuration = 0.14;
  static const double _shakeStrength = 9;

  final Random _fxRandom = Random();
  bool _trashBinActive = false;
  late Sprite _trashBinIdleSprite;
  late Sprite _trashBinActiveSprite;

  static const double monsterAreaRatio = 0.28;
  static const double _monsterXRatio = 0.22;
  static const double _trashBinXRatio = 0.85;

  double get gameplayBottomY => size.y * (1 - monsterAreaRatio);
  double get monsterAreaTopY => gameplayBottomY;
  double get monsterAreaHeight => size.y - monsterAreaTopY;
  bool get hasNextUnlockedLevel {
    final next = GameLevel.fromLevelNumber(selectedLevel.levelNumber + 1);
    if (next == null) return false;
    return unlockedLevel >= next.levelNumber;
  }

  static final Map<GameLevel, String> _backgroundByLevel = {
    GameLevel.level1: 'backgrounds/bg_meadow.png',
    GameLevel.level2: 'backgrounds/bg_bathroom.png',
    GameLevel.level3: 'backgrounds/bg_safety_playground.png',
  };
  static final Map<GameLevel, List<String>> _goodItemsByLevel = {
    GameLevel.level1: ['apple', 'banana', 'carrot', 'broccoli'],
    GameLevel.level2: ['good_soap', 'toothbrush', 'clean_sponge', 'shampoo'],
    GameLevel.level3: ['safe_helmet', 'safe_vest', 'safe_seatbelt', 'safe_first_aid_kit'],
  };
  static final Map<GameLevel, List<String>> _badItemsByLevel = {
    GameLevel.level1: ['bad_donut', 'bad_fries', 'bad_pizza', 'bad_candy'],
    GameLevel.level2: ['dirty_sock', 'germ', 'dirty_tissue', 'slime_blob'],
    GameLevel.level3: ['danger_fire', 'danger_electrical_cable', 'danger_sharp_scissors', 'danger_jagged_glass'],
  };

  List<LevelObjective> get _objectives => _objectiveEngine.objectives;

  @override
  Future<void> onLoad() async {
    final bgSprite = await loadSprite('backgrounds/bg_meadow.png');
    background = SpriteComponent(sprite: bgSprite, priority: -100);
    add(background);

    monster = Monster(monsterId: selectedMonsterId)
      ..position = Vector2(
        size.x * _monsterXRatio,
        monsterAreaTopY + (monsterAreaHeight * 0.6),
      )
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

    objectiveDisplay = ObjectiveDisplay()..position = Vector2(20, 24);
    add(objectiveDisplay);

    gameOverDisplay = GameOverDisplay()..anchor = Anchor.topLeft;
    add(gameOverDisplay);

    await loadCustomizationProgress();
    _objectiveEngine.resetForLevel(selectedLevel);
    await _applySelectedMonster();
    await _applyLevelTheme(selectedLevel);
    await _audioController.init();
    _refreshObjectiveHud();
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
    if (_spawnController.tick(dt)) {
      spawnRandomItem();
    }
  }

  void spawnRandomItem() {
    final random = Random();
    final isGood = random.nextDouble() < goodItemChance;
    final goodList = _goodItemsByLevel[selectedLevel]!;
    final badList = _badItemsByLevel[selectedLevel]!;
    if (goodList.isEmpty && badList.isEmpty) {
      return;
    }

    final canSpawnGood = goodList.isNotEmpty;
    final canSpawnBad = badList.isNotEmpty;
    final spawnGood = canSpawnGood && (!canSpawnBad || isGood);
    final itemType = spawnGood
        ? goodList[random.nextInt(goodList.length)]
        : badList[random.nextInt(badList.length)];

    final item = FallingItem(
      itemType: itemType,
      isGood: spawnGood,
      onDropped: handleItemDropped,
      onMissed: handleItemMissed,
      onDragMoved: handleItemDragMoved,
      fallSpeed: _spawnController.currentFallSpeed,
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
      var bumped = _objectiveEngine.registerGoodFeed();
      bumped ??= _objectiveEngine.syncComboProgress();
      if (_objectiveEngine.goodStreak >= 3) {
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
      _refreshObjectiveHud(bumpedObjective: bumped);
      _checkLevelCompletion();
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
      var bumped = _objectiveEngine.registerJunkThrow();
      bumped ??= _objectiveEngine.syncComboProgress();
      monster.showHappy();
      _refreshObjectiveHud(bumpedObjective: bumped);
      _checkLevelCompletion();
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
      _registerMistake();
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
    }

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

    _registerMistake();
    monster.showOops();
    _triggerScreenShake();
  }

  void _registerMistake() {
    final bumped = _objectiveEngine.registerMistake();
    mistakes = _objectiveEngine.mistakes;
    _refreshObjectiveHud(bumpedObjective: bumped);
    if (_objectiveEngine.isMistakeLimitExceeded) {
      triggerGameOver();
      return;
    }
    _checkLevelCompletion();
  }

  void _checkLevelCompletion() {
    if (isGameOver || isTransitioning) return;
    if (_objectiveEngine.isLevelCompleted) {
      completeLevel();
    }
  }

  void completeLevel() {
    if (isGameOver || isTransitioning) return;
    isGameOver = true;
    isPaused = false;
    monster.showHappy();
    _unlockNextLevelIfNeeded();
    _awardRunCoins(completed: true);
    _refreshObjectiveHud();
    gameOverDisplay.showLevelCompleted(_objectives);
    _saveCustomizationProgress();
    _audioController.pause();
  }

  void triggerGameOver() {
    if (isGameOver) return;
    isGameOver = true;
    isPaused = false;
    monster.showGameOver();
    _awardRunCoins(completed: false);
    _refreshObjectiveHud();
    gameOverDisplay.showLevelFailed(_objectives);
    _audioController.pause();
  }

  void proceedAfterLevelCompleted() {
    final nextLevel = GameLevel.fromLevelNumber(selectedLevel.levelNumber + 1);
    if (nextLevel != null && isLevelUnlocked(nextLevel)) {
      selectedLevel = nextLevel;
    }
    restartGame();
    isPaused = false;
    resumeEngine();
    _audioController.resume();
  }

  void restartGame() {
    mistakes = 0;
    isGameOver = false;
    isPaused = false;
    isTransitioning = false;
    _runRewardGranted = false;
    survivalTime = 0;
    _spawnController.reset();
    _objectiveEngine.resetForLevel(selectedLevel);

    children
        .whereType<FallingItem>()
        .toList()
        .forEach((item) => item.removeFromParent());

    gameOverDisplay.hide();
    _setTrashBinActive(false);
    monster.showIdle();
    _refreshObjectiveHud();
    _applyLevelTheme(selectedLevel);
  }

  void startGame() {
    isStarted = true;
    isPaused = false;
    resumeEngine();
    restartGame();
    _audioController.playRandomTrack();
    Future.delayed(const Duration(milliseconds: 1), () {
      if (!isGameOver) {
        _refreshObjectiveHud();
      }
    });
  }

  void startNewGameFromMenu() {
    if (!isStarted) return;
    restartGame();
    isPaused = false;
    resumeEngine();
    _audioController.resume();
  }

  void _unlockNextLevelIfNeeded() {
    final nextLevelNumber = selectedLevel.levelNumber + 1;
    final nextLevel = GameLevel.fromLevelNumber(nextLevelNumber);
    if (nextLevel == null) return;
    if (unlockedLevel >= nextLevelNumber) return;
    unlockedLevel = nextLevelNumber;
  }

  Future<void> _applyLevelTheme(GameLevel level) async {
    final backgroundPath =
        _backgroundByLevel[level] ?? _backgroundByLevel[GameLevel.level1]!;
    background.sprite = await loadSprite(backgroundPath);
    _applyMonsterAccessories();
  }

  void _refreshObjectiveHud({ObjectiveType? bumpedObjective}) {
    objectiveDisplay.updateHud(
      gold: totalCoins,
      level: selectedLevel,
      objectives: _objectives,
      bumpedObjective: bumpedObjective,
    );
  }

  void _triggerScreenShake() {
    _shakeTime = _shakeDuration;
  }

  void pauseGame() {
    if (!isStarted || isGameOver || isPaused) return;
    isPaused = true;
    pauseEngine();
    _audioController.pause();
  }

  void resumeGame() {
    if (!isStarted || isGameOver || !isPaused) return;
    isPaused = false;
    resumeEngine();
    _audioController.resume();
  }

  Future<void> loadCustomizationProgress() async {
    final data = await _progressRepository.load();
    totalCoins = data.totalCoins;
    unlockedLevel = data.unlockedLevel;
    selectedLevel = data.selectedLevel;
    selectedMonsterId = data.selectedMonsterId;
    unlockedMonsterIds
      ..clear()
      ..addAll(data.unlockedMonsterIds);
    unlockedAccessoryIds
      ..clear()
      ..addAll(data.unlockedAccessoryIds);
    equippedAccessoryByTarget
      ..clear()
      ..addAll(data.equippedAccessoryByTarget);

    if (isLoaded) {
      _objectiveEngine.resetForLevel(selectedLevel);
      await _applySelectedMonster();
      await _applyLevelTheme(selectedLevel);
      _applyMonsterAccessories();
      _refreshObjectiveHud();
    }
  }

  Future<void> _saveCustomizationProgress() async {
    await _progressRepository.save(
      totalCoins: totalCoins,
      selectedLevel: selectedLevel,
      unlockedLevel: unlockedLevel,
      selectedMonsterId: selectedMonsterId,
      unlockedMonsterIds: unlockedMonsterIds,
      unlockedAccessoryIds: unlockedAccessoryIds,
      equippedAccessoryByTarget: equippedAccessoryByTarget,
      world1HatUnlocked: isWorld1HatUnlocked,
      world1HatEquipped: isWorld1HatEquipped,
    );
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

  int _calculateCoinsForRun({required bool completed}) {
    final completedObjectives = _objectiveEngine.completedObjectivesCount;
    if (completed) {
      return 12 + (selectedLevel.levelNumber * 4) + (completedObjectives * 3);
    }
    return max(1, completedObjectives * 2);
  }

  void _awardRunCoins({required bool completed}) {
    if (_runRewardGranted) return;
    _runRewardGranted = true;
    final earned = _calculateCoinsForRun(completed: completed);
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
    _refreshObjectiveHud();
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
    return level.levelNumber <= unlockedLevel;
  }

  Future<void> selectLevel(GameLevel level) async {
    if (!isLevelUnlocked(level)) return;
    selectedLevel = level;
    await _saveCustomizationProgress();
    if (isStarted) {
      restartGame();
    } else if (isLoaded) {
      _objectiveEngine.resetForLevel(selectedLevel);
      await _applyLevelTheme(selectedLevel);
      _refreshObjectiveHud();
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
    _refreshObjectiveHud();
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
    return '${level.id}:$monsterId';
  }

  Future<void> _applySelectedMonster() async {
    if (!isLoaded || !monster.isLoaded) return;
    await monster.setMonsterId(selectedMonsterId);
  }

  @override
  void onTapDown(TapDownEvent event) {}

  @override
  Color backgroundColor() => const Color(0xFF2A2A2A);

  @override
  void onRemove() {
    _audioController.stop();
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
    objectiveDisplay.position = Vector2(20, 24);

    gameOverDisplay
      ..position = Vector2.zero()
      ..setDisplaySize(size);
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
