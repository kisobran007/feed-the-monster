import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() {
  runApp(GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: const GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MonsterTapGame game;
  bool hasStarted = false;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
    game = MonsterTapGame();
  }

  void _startGame() {
    game.startGame();
    setState(() {
      hasStarted = true;
      isPaused = false;
    });
  }

  void _togglePause() {
    if (!hasStarted || game.isGameOver) return;
    if (isPaused) {
      game.resumeGame();
    } else {
      game.pauseGame();
    }
    setState(() {
      isPaused = !isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: game),
        if (!hasStarted)
          Positioned.fill(
            child: Container(
              color: const Color(0xDD111111),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Monster Tap Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap good food, avoid bad items!',
                    style: TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      'Start The Game',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (hasStarted)
          Positioned(
            top: 18,
            right: 18,
            child: ElevatedButton(
              onPressed: _togglePause,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xCC111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                isPaused ? 'Resume' : 'Pause',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (isPaused)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: const Color(0x66000000),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xDD111111),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Paused',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Main game class
class MonsterTapGame extends FlameGame with TapCallbacks {
  late Monster monster;
  late ScoreDisplay scoreDisplay;
  late GameOverDisplay gameOverDisplay;
  late RectangleComponent playAreaBackground;
  late RectangleComponent monsterAreaBackground;
  late RectangleComponent areaDivider;
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
  static const int level2ScoreThreshold = 100;
  static const int level3ScoreThreshold = 220;
  static const double levelSpawnBoost = 0.12;
  static const double levelFallBoost = 12;
  int score = 0;
  int lives = maxLives;
  int bestScore = 0;
  int level = 1;
  int goodStreak = 0;
  bool isGameOver = false;
  bool isStarted = false;
  bool isPaused = false;
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

  @override
  Future<void> onLoad() async {
    playAreaBackground = RectangleComponent(priority: -30);
    monsterAreaBackground = RectangleComponent(priority: -20);
    areaDivider = RectangleComponent(priority: -10);
    add(playAreaBackground);
    add(monsterAreaBackground);
    add(areaDivider);

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
      lives,
      maxLives,
      bestScore,
      level,
      _goalText(),
      forceRepaint: true,
    );

    // Add game over display (hidden initially)
    gameOverDisplay = GameOverDisplay()
      ..anchor = Anchor.center;
    add(gameOverDisplay);

    await _loadBestScore();
    await _initBackgroundMusic();
    scoreDisplay.updateHud(
      score,
      lives,
      maxLives,
      bestScore,
      level,
      _goalText(),
      forceRepaint: true,
    );
    _layoutScene();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_shakeTime > 0) {
      _shakeTime = max(0, _shakeTime - dt);
    }
    
    if (!isStarted || isGameOver || isPaused) return;

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
    final itemType = isGood
        ? ['apple', 'banana', 'cookie', 'strawberry'][random.nextInt(4)]
        : ['bad_shoe', 'bad_rock', 'bad_soap', 'bad_brick'][random.nextInt(2)];

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
    if (isGameOver) return;
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
    _updateLevelProgression();
    scoreDisplay.updateHud(score, lives, maxLives, bestScore, level, _goalText());
    item.removeFromParent();
  }

  void handleItemMissed(FallingItem item) {
    if (isGameOver) return;
    if (!item.isGood) return;

    // Missing healthy food costs one life and a small score penalty.
    goodStreak = 0;
    lives -= 1;
    score -= missedGoodItemPointsPenalty;
    monster.showOops();
    _updateLevelProgression();
    if (lives <= 0) {
      triggerGameOver();
      return;
    }
    scoreDisplay.updateHud(score, lives, maxLives, bestScore, level, _goalText());
  }

  void triggerGameOver() {
    isGameOver = true;
    isPaused = false;
    monster.showGameOver();
    if (score > bestScore) {
      bestScore = score;
      _saveBestScore();
    }
    scoreDisplay.updateHud(score, lives, maxLives, bestScore, level, _goalText());
    gameOverDisplay.show(score, bestScore, survivalTime);
  }

  void restartGame() {
    score = 0;
    lives = maxLives;
    level = 1;
    goodStreak = 0;
    isGameOver = false;
    isPaused = false;
    spawnTimer = 0;
    survivalTime = 0;
    _difficultyTimer = 0;
    currentSpawnInterval = baseSpawnInterval;
    currentFallSpeed = baseFallSpeed;
    
    // Remove all falling items
    children.whereType<FallingItem>().toList().forEach((item) => item.removeFromParent());
    
    gameOverDisplay.hide();
    monster.showIdle();
    scoreDisplay.updateHud(
      score,
      lives,
      maxLives,
      bestScore,
      level,
      _goalText(),
      forceRepaint: true,
    );
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
          lives,
          maxLives,
          bestScore,
          level,
          _goalText(),
          forceRepaint: true,
        );
      }
    });
  }

  void _updateLevelProgression() {
    final previousLevel = level;
    if (score >= level3ScoreThreshold) {
      level = 3;
    } else if (score >= level2ScoreThreshold) {
      level = 2;
    } else {
      level = 1;
    }

    if (level > previousLevel) {
      currentSpawnInterval = max(minSpawnInterval, currentSpawnInterval - levelSpawnBoost);
      currentFallSpeed = min(maxFallSpeed, currentFallSpeed + levelFallBoost);
    } else if (level < previousLevel) {
      currentSpawnInterval = min(baseSpawnInterval, currentSpawnInterval + levelSpawnBoost);
      currentFallSpeed = max(baseFallSpeed, currentFallSpeed - levelFallBoost);
    }
  }

  String _goalText() {
    if (level == 1) return 'Goal: reach $level2ScoreThreshold points';
    if (level == 2) return 'Goal: reach $level3ScoreThreshold points';
    return 'Goal: survive and beat best score';
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

    playAreaBackground
      ..position = Vector2.zero()
      ..size = Vector2(size.x, bottomY)
      ..paint = (Paint()..color = const Color(0xFF1E1E1E));

    monsterAreaBackground
      ..position = Vector2(0, bottomY)
      ..size = Vector2(size.x, size.y - bottomY)
      ..paint = (Paint()..color = const Color(0xFF103A2F));

    areaDivider
      ..position = Vector2(0, bottomY - 2)
      ..size = Vector2(size.x, 4)
      ..paint = (Paint()..color = const Color(0x66FFFFFF));

    monster.position = Vector2(size.x / 2, monsterAreaTopY + (monsterAreaHeight * 0.6));
    scoreDisplay.position = Vector2(20, 24);

    gameOverDisplay
      ..position = Vector2(size.x / 2, bottomY / 2)
      ..setDisplaySize(overlaySize);
  }
}

// Monster character component
class Monster extends SpriteComponent with HasGameRef<MonsterTapGame> {
  String currentState = 'idle';
  int _reactionId = 0;
  static const Duration _reactionDuration = Duration(milliseconds: 500);
  static const double _idleSize = 190;
  static const double _happySize = 210;
  static const double _sadSize = 170;
  final Random _random = Random();
  final List<String> _happySounds = ['happy_wee.mp3'];
  final List<String> _sadSounds = ['sad_aww.mp3'];
  late MonsterReactionIndicator reactionIndicator;
  late Sprite idleSprite;
  late Sprite happySprite;
  late Sprite sadSprite;

  @override
  Future<void> onLoad() async {
    FlameAudio.audioCache.prefix = 'assets/sounds/';
    await FlameAudio.audioCache.loadAll([..._happySounds, ..._sadSounds]);

    idleSprite = await gameRef.loadSprite('characters/monster2_idle.png');
    happySprite = await gameRef.loadSprite('characters/monster2_yum.png');
    sadSprite = await gameRef.loadSprite('characters/monster2_yack.png');
    sprite = idleSprite;
    size = Vector2.all(_idleSize);

    reactionIndicator = MonsterReactionIndicator()
      ..anchor = Anchor.center;
    add(reactionIndicator);
    _layoutReactionIndicator();
  }

  void showHappy() {
    currentState = 'happy';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = happySprite;
    reactionIndicator.showHappy();
    size = Vector2.all(_happySize);
    _layoutReactionIndicator();
    Future.delayed(_reactionDuration, () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void showOops() {
    currentState = 'oops';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = sadSprite;
    reactionIndicator.showOops();
    size = Vector2.all(_sadSize);
    _layoutReactionIndicator();
    Future.delayed(_reactionDuration, () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void showIdle() {
    currentState = 'idle';
    sprite = idleSprite;
    reactionIndicator.hideIndicator();
    size = Vector2.all(_idleSize);
    _layoutReactionIndicator();
  }

  void showGameOver() {
    _reactionId += 1;
    currentState = 'game_over';
    sprite = sadSprite;
    reactionIndicator.showGameOver();
    size = Vector2.all(_sadSize);
    _layoutReactionIndicator();
  }

  void showStreak() {
    currentState = 'streak';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = happySprite;
    reactionIndicator.showStreak();
    size = Vector2.all(_happySize + 12);
    _layoutReactionIndicator();
    Future.delayed(const Duration(milliseconds: 620), () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void _playReactionSound(List<String> sounds) {
    if (sounds.isEmpty) return;
    final sound = sounds[_random.nextInt(sounds.length)];
    FlameAudio.play(sound);
  }

  void _layoutReactionIndicator() {
    reactionIndicator.position = Vector2(size.x / 2, -54);
  }
}

enum MonsterReactionState {
  none,
  happy,
  oops,
  streak,
  gameOver,
}

class MonsterReactionIndicator extends PositionComponent {
  MonsterReactionState state = MonsterReactionState.none;
  double _time = 0;

  final Paint _happyPaint = Paint()..color = const Color(0xFFFFD54F);
  final Paint _oopsPaint = Paint()..color = const Color(0xFFE53935);
  final Paint _streakPaint = Paint()..color = const Color(0xFFFFEE58);
  final Paint _gameOverPaint = Paint()..color = const Color(0xFF64B5F6);

  MonsterReactionIndicator() {
    size = Vector2(120, 64);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  void showHappy() => state = MonsterReactionState.happy;
  void showOops() => state = MonsterReactionState.oops;
  void showStreak() => state = MonsterReactionState.streak;
  void showGameOver() => state = MonsterReactionState.gameOver;
  void hideIndicator() => state = MonsterReactionState.none;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (state == MonsterReactionState.none) return;

    final pulse = 1 + 0.12 * sin(_time * 8);
    final center = Offset(size.x / 2, size.y / 2);

    if (state == MonsterReactionState.happy) {
      _drawOrbitDots(canvas, center, 20 * pulse, 3, _happyPaint, 8);
    } else if (state == MonsterReactionState.oops) {
      _drawCross(canvas, center, 22 * pulse, _oopsPaint);
      canvas.drawCircle(center.translate(-18, 0), 4 * pulse, _oopsPaint);
      canvas.drawCircle(center.translate(18, 0), 4 * pulse, _oopsPaint);
    } else if (state == MonsterReactionState.streak) {
      _drawOrbitDots(canvas, center, 26 * pulse, 5, _streakPaint, 9);
    } else if (state == MonsterReactionState.gameOver) {
      canvas.drawCircle(center.translate(-10, 6), 7 * pulse, _gameOverPaint);
      canvas.drawCircle(center.translate(10, 6), 7 * pulse, _gameOverPaint);
      canvas.drawCircle(center.translate(0, 20), 5 * pulse, _gameOverPaint);
    }
  }

  void _drawOrbitDots(
    Canvas canvas,
    Offset center,
    double radius,
    int count,
    Paint paint,
    double dotRadius,
  ) {
    for (var i = 0; i < count; i++) {
      final angle = (_time * 2.8) + (2 * pi * i / count);
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * (radius * 0.6);
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  void _drawCross(Canvas canvas, Offset center, double halfSize, Paint paint) {
    final stroke = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - halfSize, center.dy - halfSize),
      Offset(center.dx + halfSize, center.dy + halfSize),
      stroke,
    );
    canvas.drawLine(
      Offset(center.dx + halfSize, center.dy - halfSize),
      Offset(center.dx - halfSize, center.dy + halfSize),
      stroke,
    );
  }
}

// Falling item component
class FallingItem extends SpriteComponent with TapCallbacks, HasGameRef<MonsterTapGame> {
  final String itemType;
  final bool isGood;
  final Function(FallingItem) onTapped;
  final Function(FallingItem) onMissed;
  final double fallSpeed; // pixels per second
  static const double _itemSize = 125;

  FallingItem({
    required this.itemType,
    required this.isGood,
    required this.onTapped,
    required this.onMissed,
    required this.fallSpeed,
  });

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('items/$itemType.png');
    size = Vector2.all(_itemSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;

    // Remove if off screen
    if (position.y > gameRef.gameplayBottomY + 50) {
      onMissed(this);
      removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapped(this);
  }
}

class TapBurst extends PositionComponent {
  final Color baseColor;
  final int particleCount;
  final double particleSize;
  final double lifetime;
  final double spreadSpeed;
  final List<Color>? palette;
  final Random _random = Random();

  final List<_BurstParticle> _particles = [];
  double _elapsed = 0;

  TapBurst({
    required Vector2 position,
    required this.baseColor,
    required this.particleCount,
    required this.particleSize,
    required this.lifetime,
    required this.spreadSpeed,
    this.palette,
  }) {
    this.position = position;
    priority = 30;
  }

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = spreadSpeed * (0.55 + _random.nextDouble() * 0.75);
      _particles.add(
        _BurstParticle(
          velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
          size: particleSize * (0.6 + _random.nextDouble() * 0.9),
          color: palette == null
              ? baseColor
              : palette![_random.nextInt(palette!.length)],
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / lifetime).clamp(0.0, 1.0);
    final alpha = (255 * (1 - t)).clamp(0, 255).toInt();
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final x = p.velocity.x * _elapsed;
      final y = p.velocity.y * _elapsed;
      final radius = p.size * (1 - t * 0.7);
      paint.color = p.color.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
}

class _BurstParticle {
  final Vector2 velocity;
  final double size;
  final Color color;

  _BurstParticle({
    required this.velocity,
    required this.size,
    required this.color,
  });
}

// Score display component
class ScoreDisplay extends PositionComponent {
  late TextComponent scoreText;
  late TextComponent levelText;
  late TextComponent goalText;
  late TextComponent bestText;
  late HeartsDisplay heartsDisplay;

  int _score = 0;
  int _lives = 3;
  int _maxLives = 3;
  int _bestScore = 0;
  int _level = 1;
  String _goal = '';

  ScoreDisplay();

  @override
  Future<void> onLoad() async {
    scoreText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )..position = Vector2.zero();

    levelText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.orangeAccent,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )..position = Vector2(0, 34);

    heartsDisplay = HeartsDisplay(
      maxLives: _maxLives,
      lives: _lives,
    )..position = Vector2(0, 68);

    goalText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white70,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )..position = Vector2(0, 112);

    bestText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )..position = Vector2(0, 144);

    add(scoreText);
    add(levelText);
    add(heartsDisplay);
    add(goalText);
    add(bestText);
    _applyHud();
  }

  void updateHud(
    int score,
    int lives,
    int maxLives,
    int bestScore,
    int level,
    String goal, {
    bool forceRepaint = false,
  }) {
    _score = score;
    _lives = lives;
    _maxLives = maxLives;
    _bestScore = bestScore;
    _level = level;
    _goal = goal;
    if (!isLoaded) return;
    _applyHud();
  }

  void _applyHud() {
    scoreText.text = 'Score: $_score';
    levelText.text = 'Level $_level';
    goalText.text = _goal;
    bestText.text = 'Best: $_bestScore';
    heartsDisplay
      ..maxLives = _maxLives
      ..lives = _lives;
  }
}

class HeartsDisplay extends PositionComponent {
  int lives;
  int maxLives;

  HeartsDisplay({
    required this.lives,
    required this.maxLives,
  });

  final Paint _fullPaint = Paint()..color = const Color(0xFFE53935);
  final Paint _emptyPaint = Paint()..color = const Color(0xFF555555);
  final Paint _strokePaint = Paint()
    ..color = const Color(0xDDFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static const double _heartSize = 24;
  static const double _spacing = 10;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (var i = 0; i < maxLives; i++) {
      final paint = i < lives ? _fullPaint : _emptyPaint;
      final dx = i * (_heartSize + _spacing);
      final path = _buildHeartPath(dx, 0, _heartSize);
      canvas.drawPath(path, paint);
      canvas.drawPath(path, _strokePaint);
    }
  }

  Path _buildHeartPath(double x, double y, double size) {
    final path = Path();
    path.moveTo(x + size * 0.5, y + size * 0.92);
    path.cubicTo(
      x + size * 0.1,
      y + size * 0.62,
      x - size * 0.02,
      y + size * 0.34,
      x + size * 0.2,
      y + size * 0.18,
    );
    path.cubicTo(
      x + size * 0.36,
      y + size * 0.04,
      x + size * 0.55,
      y + size * 0.14,
      x + size * 0.5,
      y + size * 0.3,
    );
    path.cubicTo(
      x + size * 0.45,
      y + size * 0.14,
      x + size * 0.64,
      y + size * 0.04,
      x + size * 0.8,
      y + size * 0.18,
    );
    path.cubicTo(
      x + size * 1.02,
      y + size * 0.34,
      x + size * 0.9,
      y + size * 0.62,
      x + size * 0.5,
      y + size * 0.92,
    );
    path.close();
    return path;
  }
}

// Game over display component
class GameOverDisplay extends PositionComponent with TapCallbacks, HasGameRef<MonsterTapGame> {
  late TextComponent gameOverText;
  late TextComponent finalScoreText;
  late TextComponent bestScoreText;
  late TextComponent survivalTimeText;
  late TextComponent restartText;
  bool isVisible = false;

  @override
  Future<void> onLoad() async {
    size = Vector2(400, 300);
    
    gameOverText = TextComponent(
      text: 'Game Over!',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.red,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 70),
    );

    finalScoreText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 140),
    );

    bestScoreText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 185),
    );

    survivalTimeText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white70,
          fontSize: 24,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 230),
    );

    restartText = TextComponent(
      text: 'Tap to Restart',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.yellow,
          fontSize: 28,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, 210),
    );

    add(gameOverText);
    add(finalScoreText);
    add(bestScoreText);
    add(survivalTimeText);
    add(restartText);
    _layoutText();
  }

  void setDisplaySize(Vector2 newSize) {
    size = newSize;
    _layoutText();
  }

  void _layoutText() {
    gameOverText.position = Vector2(size.x / 2, size.y * 0.22);
    finalScoreText.position = Vector2(size.x / 2, size.y * 0.4);
    bestScoreText.position = Vector2(size.x / 2, size.y * 0.54);
    survivalTimeText.position = Vector2(size.x / 2, size.y * 0.67);
    restartText.position = Vector2(size.x / 2, size.y * 0.84);
  }

  void show(int finalScore, int bestScore, double survivalTime) {
    isVisible = true;
    finalScoreText.text = 'Final Score: $finalScore';
    bestScoreText.text = 'Best Score: $bestScore';
    survivalTimeText.text = 'Time: ${survivalTime.toStringAsFixed(1)}s';
  }

  void hide() {
    isVisible = false;
  }

  @override
  void renderTree(Canvas canvas) {
    if (!isVisible) return;
    super.renderTree(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isVisible) {
      final localPoint = event.localPosition;
      // Check if tap is near restart text.
      if ((localPoint.y - restartText.position.y).abs() < 36) {
        gameRef.restartGame();
      }
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return isVisible;
  }
}
