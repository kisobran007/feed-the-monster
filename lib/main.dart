import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(GameApp());
}

class GameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(game: MonsterTapGame()),
      ),
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
  int score = 0;
  bool isGameOver = false;
  double spawnTimer = 0;
  final double spawnInterval = 1.5; // Spawn item every 1.5 seconds
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

    // Add game over display (hidden initially)
    gameOverDisplay = GameOverDisplay()
      ..anchor = Anchor.center;
    add(gameOverDisplay);

    _layoutScene();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (isGameOver) return;

    // Spawn items periodically
    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      spawnRandomItem();
    }

    // Update score display
    scoreDisplay.updateScore(score);
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
      monster.showOops();
      if (score < 0) {
        triggerGameOver();
      }
    }
    item.removeFromParent();
  }

  void triggerGameOver() {
    isGameOver = true;
    gameOverDisplay.show(score);
  }

  void restartGame() {
    score = 0;
    isGameOver = false;
    spawnTimer = 0;
    
    // Remove all falling items
    children.whereType<FallingItem>().toList().forEach((item) => item.removeFromParent());
    
    gameOverDisplay.hide();
    monster.showIdle();
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
    final overlaySize = Vector2(size.x * 0.92, min(420.0, bottomY * 0.8));

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
  static const Duration _reactionDuration = Duration(milliseconds: 250);
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
    size = Vector2(130, 130);

    reactionText = TextComponent(
      text: 'Catch good food!',
      anchor: Anchor.center,
      position: Vector2(0, -95),
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
  }

  void showHappy() {
    currentState = 'happy';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = happySprite;
    _playReactionSound(_happySounds);
    reactionText.text = 'Yummy!';
    size = Vector2(145, 145);
    Future.delayed(_reactionDuration, () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void showOops() {
    currentState = 'oops';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = sadSprite;
    _playReactionSound(_sadSounds);
    reactionText.text = 'Yuck!';
    size = Vector2(115, 115);
    Future.delayed(_reactionDuration, () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void showIdle() {
    currentState = 'idle';
    sprite = idleSprite;
    reactionText.text = 'Catch good food!';
    size = Vector2(130, 130);
  }

  void _playReactionSound(List<String> sounds) {
    if (sounds.isEmpty) return;
    final sound = sounds[_random.nextInt(sounds.length)];
    FlameAudio.play(sound);
  }
}

// Falling item component
class FallingItem extends SpriteComponent with TapCallbacks, HasGameRef<MonsterTapGame> {
  final String itemType;
  final bool isGood;
  final Function(FallingItem) onTapped;
  final double fallSpeed = 100; // pixels per second

  FallingItem({
    required this.itemType,
    required this.isGood,
    required this.onTapped,
  });

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('items/$itemType.png');
    size = Vector2(80, 80);
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
class ScoreDisplay extends TextComponent {
  ScoreDisplay() : super(
    text: 'Score: 0',
    textRenderer: TextPaint(
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
      ),
    ),
  );

  void updateScore(int score) {
    text = 'Score: $score';
  }
}

// Game over display component
class GameOverDisplay extends PositionComponent with TapCallbacks, HasGameRef<MonsterTapGame> {
  late TextComponent gameOverText;
  late TextComponent finalScoreText;
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
    add(restartText);
    _layoutText();
  }

  void setDisplaySize(Vector2 newSize) {
    size = newSize;
    _layoutText();
  }

  void _layoutText() {
    gameOverText.position = Vector2(size.x / 2, size.y * 0.28);
    finalScoreText.position = Vector2(size.x / 2, size.y * 0.5);
    restartText.position = Vector2(size.x / 2, size.y * 0.74);
  }

  void show(int finalScore) {
    isVisible = true;
    finalScoreText.text = 'Final Score: $finalScore';
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
