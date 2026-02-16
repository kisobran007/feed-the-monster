part of '../../main.dart';
class GameOverDisplay extends PositionComponent with TapCallbacks, HasGameReference<MonsterTapGame> {
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
        style: const TextStyle(
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
        style: const TextStyle(
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
        style: const TextStyle(
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
        style: const TextStyle(
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
        style: const TextStyle(
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

    final fullRect = Rect.fromLTWH(
      0,
      0,
      game.size.x,
      game.size.y,
    );

    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.9,
      colors: [
        Colors.black.withValues(alpha: 0.15),
        Colors.black.withValues(alpha: 0.75),
      ],
      stops: const [0.4, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(fullRect);
    canvas.drawRect(fullRect, paint);
    super.renderTree(canvas);
  }




  @override
  void onTapDown(TapDownEvent event) {
    if (isVisible) {
      final localPoint = event.localPosition;
      // Check if tap is near restart text.
      if ((localPoint.y - restartText.position.y).abs() < 36) {
        game.restartGame();
      }
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return isVisible;
  }
}
