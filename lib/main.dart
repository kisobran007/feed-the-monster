import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
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
  int score = 0;
  bool isGameOver = false;
  double spawnTimer = 0;
  final double spawnInterval = 1.5; // Spawn item every 1.5 seconds

  @override
  Future<void> onLoad() async {
    // Add monster at bottom center
    monster = Monster()
      ..position = Vector2(size.x / 2, size.y - 150)
      ..anchor = Anchor.center;
    add(monster);

    // Add score display
    scoreDisplay = ScoreDisplay()..position = Vector2(20, 40);
    add(scoreDisplay);

    // Add game over display (hidden initially)
    gameOverDisplay = GameOverDisplay()
      ..position = Vector2(size.x / 2, size.y / 2)
      ..anchor = Anchor.center;
    add(gameOverDisplay);
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
      ..position = Vector2(random.nextDouble() * (size.x - 100) + 50, -50)
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
}

// Monster character component
class Monster extends SpriteComponent with HasGameRef<MonsterTapGame> {
  String currentState = 'idle';

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('characters/monster.png');
    size = Vector2(120, 120);
  }

  void showHappy() {
    currentState = 'happy';
    // Optional: load happy sprite or animate
    Future.delayed(Duration(milliseconds: 500), () => showIdle());
  }

  void showOops() {
    currentState = 'oops';
    // Optional: load oops sprite or animate
    Future.delayed(Duration(milliseconds: 500), () => showIdle());
  }

  void showIdle() {
    currentState = 'idle';
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
    if (position.y > gameRef.size.y + 50) {
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
      position: Vector2(0, 60),
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
      position: Vector2(0, 120),
    );

    add(gameOverText);
    add(finalScoreText);
    add(restartText);
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
      gameRef.restartGame();
    }
  }
}
