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
  static const int maxLives = 3;
  static const double baseSpawnInterval = 1.5;
  static const double minSpawnInterval = 0.7;
  static const double spawnIntervalStep = 0.12;
  static const double difficultyTickSeconds = 12;
  static const double baseFallSpeed = 100;
  static const double maxFallSpeed = 220;
  static const double fallSpeedStep = 10;
  int score = 0;
  int lives = maxLives;
  int bestScore = 0;
  bool isGameOver = false;
  bool isStarted = false;
  bool isPaused = false;
  double survivalTime = 0;
  double _difficultyTimer = 0;
  double currentSpawnInterval = baseSpawnInterval;
  double currentFallSpeed = baseFallSpeed;
  double spawnTimer = 0;
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
    scoreDisplay.updateHud(score, lives, maxLives, bestScore, forceRepaint: true);

    // Add game over display (hidden initially)
    gameOverDisplay = GameOverDisplay()
      ..anchor = Anchor.center;
    add(gameOverDisplay);

    await _loadBestScore();
    scoreDisplay.updateHud(score, lives, maxLives, bestScore, forceRepaint: true);
    _layoutScene();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
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
    final isGood = random.nextBool(); // 50% chance for good/bad
    final itemType = isGood
        ? ['apple', 'banana', 'cookie', 'strawberry'][random.nextInt(4)]
        : ['bad_shoe', 'bad_rock', 'bad_soap', 'bad_brick'][random.nextInt(2)];

    final item = FallingItem(
      itemType: itemType,
      isGood: isGood,
      onTapped: handleItemTap,
      fallSpeed: currentFallSpeed,
    )
      ..position = Vector2(random.nextDouble() * (size.x - 90) + 45, -50)
      ..anchor = Anchor.center;

    add(item);
  }

  void handleItemTap(FallingItem item) {
    if (isGameOver) return;

    if (item.isGood) {
      score += 10;
      monster.showHappy();
    } else {
      score -= 5;
      lives -= 1;
      monster.showOops();
      if (lives <= 0) {
        triggerGameOver();
      }
    }
    scoreDisplay.updateHud(score, lives, maxLives, bestScore);
    item.removeFromParent();
  }

  void triggerGameOver() {
    isGameOver = true;
    isPaused = false;
    if (score > bestScore) {
      bestScore = score;
      _saveBestScore();
    }
    scoreDisplay.updateHud(score, lives, maxLives, bestScore);
    gameOverDisplay.show(score, bestScore, survivalTime);
  }

  void restartGame() {
    score = 0;
    lives = maxLives;
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
    scoreDisplay.updateHud(score, lives, maxLives, bestScore, forceRepaint: true);
  }

  void startGame() {
    isStarted = true;
    isPaused = false;
    resumeEngine();
    restartGame();
    // Force one extra HUD repaint right after start to avoid first-frame glyph fallback glitches.
    Future.delayed(const Duration(milliseconds: 1), () {
      if (!isGameOver) {
        scoreDisplay.updateHud(score, lives, maxLives, bestScore, forceRepaint: true);
      }
    });
  }

  void pauseGame() {
    if (!isStarted || isGameOver || isPaused) return;
    isPaused = true;
    pauseEngine();
  }

  void resumeGame() {
    if (!isStarted || isGameOver || !isPaused) return;
    isPaused = false;
    resumeEngine();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    bestScore = prefs.getInt('best_score') ?? 0;
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('best_score', bestScore);
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Tap handled by GameOverDisplay
  }

  @override
  Color backgroundColor() => const Color(0xFF2A2A2A);

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
  late TextComponent reactionText;
  late Sprite idleSprite;
  late Sprite happySprite;
  late Sprite sadSprite;

  @override
  Future<void> onLoad() async {
    FlameAudio.audioCache.prefix = 'assets/sounds/';
    await FlameAudio.audioCache.loadAll([..._happySounds, ..._sadSounds]);

    idleSprite = await gameRef.loadSprite('characters/monster_idle.png');
    happySprite = await gameRef.loadSprite('characters/monster_happy.png');
    sadSprite = await gameRef.loadSprite('characters/monster_sad.png');
    sprite = idleSprite;
    size = Vector2.all(_idleSize);

    reactionText = TextComponent(
      text: 'Catch good food!',
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
    add(reactionText);
    _layoutReactionText();
  }

  void showHappy() {
    currentState = 'happy';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = happySprite;
    //_playReactionSound(_happySounds);
    reactionText.text = 'Yummy!';
    size = Vector2.all(_happySize);
    _layoutReactionText();
    Future.delayed(_reactionDuration, () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void showOops() {
    currentState = 'oops';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = sadSprite;
    //_playReactionSound(_sadSounds);
    reactionText.text = 'Yuck!';
    size = Vector2.all(_sadSize);
    _layoutReactionText();
    Future.delayed(_reactionDuration, () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void showIdle() {
    currentState = 'idle';
    sprite = idleSprite;
    reactionText.text = 'Catch good food!';
    size = Vector2.all(_idleSize);
    _layoutReactionText();
  }

  void _playReactionSound(List<String> sounds) {
    if (sounds.isEmpty) return;
    final sound = sounds[_random.nextInt(sounds.length)];
    FlameAudio.play(sound);
  }

  void _layoutReactionText() {
    reactionText.position = Vector2(size.x / 2, -54);
  }
}

// Falling item component
class FallingItem extends SpriteComponent with TapCallbacks, HasGameRef<MonsterTapGame> {
  final String itemType;
  final bool isGood;
  final Function(FallingItem) onTapped;
  final double fallSpeed; // pixels per second
  static const double _itemSize = 125;

  FallingItem({
    required this.itemType,
    required this.isGood,
    required this.onTapped,
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
      removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapped(this);
  }
}

// Score display component
class ScoreDisplay extends PositionComponent {
  late TextComponent scoreText;
  late TextComponent bestText;
  late HeartsDisplay heartsDisplay;

  int _score = 0;
  int _lives = 3;
  int _maxLives = 3;
  int _bestScore = 0;

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

    heartsDisplay = HeartsDisplay(
      maxLives: _maxLives,
      lives: _lives,
    )..position = Vector2(0, 36);

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
    )..position = Vector2(0, 82);

    add(scoreText);
    add(heartsDisplay);
    add(bestText);
    _applyHud();
  }

  void updateHud(
    int score,
    int lives,
    int maxLives,
    int bestScore, {
    bool forceRepaint = false,
  }) {
    _score = score;
    _lives = lives;
    _maxLives = maxLives;
    _bestScore = bestScore;
    if (!isLoaded) return;
    _applyHud();
  }

  void _applyHud() {
    scoreText.text = 'Score: $_score';
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
