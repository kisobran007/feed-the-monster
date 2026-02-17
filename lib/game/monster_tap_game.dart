part of '../main.dart';
// Main game class
class MonsterTapGame extends FlameGame with TapCallbacks {
  late Monster monster;
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
  static const int world1HatCost = 60;
  static const String _coinsKey = 'coins_total';
  static const String _unlockedAccessoryIdsKey = 'unlocked_accessory_ids';
  static const String _equippedAccessoryByTargetKey = 'equipped_accessory_by_target';
  static const String _world1HatUnlockedKey = 'skin_world1_hat_unlocked';
  static const String _world1HatEquippedKey = 'skin_world1_hat_equipped';
  static const String _monsterMainId = AccessoryCatalog.monsterMainId;
  int score = 0;
  int lives = maxLives;
  int bestScore = 0;
  int goodStreak = 0;
  int totalCoins = 0;
  int lastRunCoinsEarned = 0;
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
  static const double monsterAreaRatio = 0.28;

  double get gameplayBottomY => size.y * (1 - monsterAreaRatio);
  double get monsterAreaTopY => gameplayBottomY;
  double get monsterAreaHeight => size.y - monsterAreaTopY;  

  GameWorld currentWorld = GameWorld.world1;

  static const int world2ScoreThreshold = 300;

  List<String> world1Good = ['apple', 'banana', 'cookie', 'strawberry'];
  List<String> world1Bad = ['bad_shoe', 'bad_rock', 'bad_soap', 'bad_brick'];

  List<String> world2Good = ['cupcake', 'lollipop'];
  List<String> world2Bad = ['chili', 'onion'];

  @override
  Future<void> onLoad() async {
    final bgSprite = await loadSprite('backgrounds/bg_meadow.png');
    background = SpriteComponent(
      sprite: bgSprite,
      priority: -100,
    );
    add(background);

    // Add monster in dedicated bottom area
    monster = Monster()
      ..position = Vector2(size.x / 2, monsterAreaTopY + (monsterAreaHeight * 0.6))
      ..anchor = Anchor.center;
    add(monster);

    // Add score display
    scoreDisplay = ScoreDisplay()..position = Vector2(20, 24);
    add(scoreDisplay);
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      currentWorld,
      _goalText(),
      forceRepaint: true,
    );

    // Add game over display (hidden initially)
    gameOverDisplay = GameOverDisplay()
      ..anchor = Anchor.center;
    add(gameOverDisplay);

    await _loadBestScore();
    await loadCustomizationProgress();
    await _initBackgroundMusic();
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      currentWorld,
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
      currentSpawnInterval = max(minSpawnInterval, currentSpawnInterval - spawnIntervalStep);
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

    final goodList =
        currentWorld == GameWorld.world1 ? world1Good : world2Good;

    final badList =
        currentWorld == GameWorld.world1 ? world1Bad : world2Bad;

    final itemType = isGood
        ? goodList[random.nextInt(goodList.length)]
        : badList[random.nextInt(badList.length)];

    final item = FallingItem(
      itemType: itemType,
      isGood: isGood,
      onTapped: handleItemTap,
      onMissed: handleItemMissed,
      fallSpeed: currentFallSpeed,
    )
      ..position = Vector2(random.nextDouble() * (size.x - 90) + 45, -50)
      ..anchor = Anchor.center;

    add(item);
  }


  void handleItemTap(FallingItem item) {
    if (isGameOver || isTransitioning) return;
    final tapPosition = item.position.clone();

    if (item.isGood) {
      goodStreak += 1;
      score += goodItemPoints;
      if (goodStreak >= 3) {
        monster.showStreak();
        add(
          TapBurst(
            position: tapPosition,
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
          position: tapPosition,
          baseColor: const Color(0xFFFFD54F),
          particleCount: 16,
          particleSize: 8,
          lifetime: 0.35,
          spreadSpeed: 180,
        ),
      );
    } else {
      goodStreak = 0;
      score -= badItemPointsPenalty;
      lives -= 1;
      monster.showOops();
      _triggerScreenShake();
      add(
        TapBurst(
          position: tapPosition,
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
    _checkWorldProgression();
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      currentWorld,
      _goalText(),
    );
    item.removeFromParent();
  }

  void handleItemMissed(FallingItem item) {
    if (isGameOver || isTransitioning) return;
    if (!item.isGood) return;

    // Missing healthy food costs one life and a small score penalty.
    goodStreak = 0;
    lives -= 1;
    score -= missedGoodItemPointsPenalty;
    monster.showOops();
    _checkWorldProgression();
    if (lives <= 0) {
      triggerGameOver();
      return;
    }
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      currentWorld,
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
      currentWorld,
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
    currentWorld = GameWorld.world1;
    
    // Remove all falling items
    children.whereType<FallingItem>().toList().forEach((item) => item.removeFromParent());
    
    gameOverDisplay.hide();
    monster.showIdle();
    scoreDisplay.updateHud(
      score,
      totalCoins,
      lives,
      maxLives,
      currentWorld,
      _goalText(),
      forceRepaint: true,
    );
    _applyWorldTheme(currentWorld);
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
          currentWorld,
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

  void _checkWorldProgression() {
    if (score >= world2ScoreThreshold &&
        currentWorld == GameWorld.world1) {
      _transitionToWorld(GameWorld.world2);
    }
  }

  void _transitionToWorld(GameWorld newWorld) {
    if (isTransitioning) return;
    isTransitioning = true;

    // Celebration moment
    monster.showStreak();

    add(
      TapBurst(
        position: Vector2(size.x / 2, size.y / 2),
        baseColor: const Color(0xFFFF80AB),
        particleCount: 40,
        particleSize: 14,
        lifetime: 0.8,
        spreadSpeed: 250,
      ),
    );

    add(
      WorldTransitionOverlay(
        nextWorld: newWorld,
        onSwitchWorld: () {
          currentWorld = newWorld;
          _applyWorldTheme(newWorld);
          scoreDisplay.updateHud(
            score,
            totalCoins,
            lives,
            maxLives,
            currentWorld,
            _goalText(),
          );
        },
        onCompleted: () {
          isTransitioning = false;
        },
      ),
    );
  }

  Future<void> _applyWorldTheme(GameWorld world) async {
    switch (world) {
      case GameWorld.world1:
        background.sprite =
            await loadSprite('backgrounds/bg_meadow.png');
        break;

      case GameWorld.world2:
        background.sprite =
            await loadSprite('backgrounds/bg_world2.png');
        break;
    }
    await monster.loadWorldSkin(world);
    _applyMonsterAccessories();
  }

  String _goalText() {
    if (currentWorld == GameWorld.world1) {
      return 'Goal: reach $world2ScoreThreshold points to unlock World 2';
    }
    return 'Goal: survive and collect more gold';
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
            equippedAccessoryByTarget[key] = value;
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
        equippedAccessoryByTarget[_targetKey(GameWorld.world1, _monsterMainId)] =
            AccessoryCatalog.world1PartyHatId;
      }
      await _saveCustomizationProgress();
    }

    _applyMonsterAccessories();
  }

  Future<void> _saveCustomizationProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, totalCoins);
    await prefs.setStringList(_unlockedAccessoryIdsKey, unlockedAccessoryIds.toList());
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
    final equippedId = equippedAccessoryIdForTarget(
      world: currentWorld,
      monsterId: _monsterMainId,
    );
    final equippedItem = equippedId == null ? null : AccessoryCatalog.byId(equippedId);
    final hatItem = equippedItem?.slot == AccessorySlot.hat ? equippedItem : null;
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
      world: GameWorld.world1,
      monsterId: _monsterMainId,
    );
    return true;
  }

  Future<void> setWorld1HatEquipped(bool equipped) async {
    if (equipped) {
      if (!isWorld1HatUnlocked) return;
      await setAccessoryEquipped(
        AccessoryCatalog.world1PartyHatId,
        world: GameWorld.world1,
        monsterId: _monsterMainId,
      );
      return;
    }
    await clearEquippedAccessory(
      world: GameWorld.world1,
      monsterId: _monsterMainId,
    );
  }

  List<AccessoryItem> accessoriesFor({
    required GameWorld world,
    required String monsterId,
  }) {
    return AccessoryCatalog.forMonster(world: world, monsterId: monsterId);
  }

  bool isAccessoryUnlocked(String accessoryId) {
    return unlockedAccessoryIds.contains(accessoryId);
  }

  String? equippedAccessoryIdForTarget({
    required GameWorld world,
    required String monsterId,
  }) {
    return equippedAccessoryByTarget[_targetKey(world, monsterId)];
  }

  bool isAccessoryEquipped({
    required String accessoryId,
    required GameWorld world,
    required String monsterId,
  }) {
    return equippedAccessoryIdForTarget(world: world, monsterId: monsterId) == accessoryId;
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
    required GameWorld world,
    required String monsterId,
  }) async {
    if (!isAccessoryUnlocked(accessoryId)) return;
    equippedAccessoryByTarget[_targetKey(world, monsterId)] = accessoryId;
    await _saveCustomizationProgress();
    _applyMonsterAccessories();
  }

  Future<void> clearEquippedAccessory({
    required GameWorld world,
    required String monsterId,
  }) async {
    equippedAccessoryByTarget.remove(_targetKey(world, monsterId));
    await _saveCustomizationProgress();
    _applyMonsterAccessories();
  }

  bool get isWorld1HatUnlocked => isAccessoryUnlocked(AccessoryCatalog.world1PartyHatId);
  bool get isWorld1HatEquipped => isAccessoryEquipped(
        accessoryId: AccessoryCatalog.world1PartyHatId,
        world: GameWorld.world1,
        monsterId: _monsterMainId,
      );

  String _targetKey(GameWorld world, String monsterId) {
    return '${world.name}:$monsterId';
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

    monster.position = Vector2(size.x / 2, monsterAreaTopY + (monsterAreaHeight * 0.6));
    scoreDisplay.position = Vector2(20, 24);

    gameOverDisplay
      ..position = Vector2(size.x / 2, bottomY / 2)
      ..setDisplaySize(overlaySize);
  }
}



