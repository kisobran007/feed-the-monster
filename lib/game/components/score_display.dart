part of '../../main.dart';

class ScoreDisplay extends PositionComponent {
  late TextComponent scoreText;
  late TextComponent goldText;
  late TextComponent levelText;
  late TextComponent goalText;
  late HeartsDisplay heartsDisplay;

  int _score = 0;
  int _gold = 0;
  int _lives = 3;
  int _maxLives = 3;
  GameLevel _level = GameLevel.level1;
  String _goal = '';

  ScoreDisplay();

  @override
  Future<void> onLoad() async {
    scoreText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )..position = Vector2.zero();

    goldText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 24,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )..position = Vector2(0, 32);

    levelText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )..position = Vector2(0, 64);

    heartsDisplay = HeartsDisplay(
      maxLives: _maxLives,
      lives: _lives,
    )..position = Vector2(0, 98);

    goalText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )..position = Vector2(0, 142);

    add(scoreText);
    add(goldText);
    add(levelText);
    add(heartsDisplay);
    add(goalText);
    _applyHud();
  }

  void updateHud(
    int score,
    int gold,
    int lives,
    int maxLives,
    GameLevel level,
    String goal, {
    bool forceRepaint = false,
  }) {
    _score = score;
    _gold = gold;
    _lives = lives;
    _maxLives = maxLives;
    _level = level;
    _goal = goal;
    if (!isLoaded) return;
    _applyHud();
  }

  void _applyHud() {
    scoreText.text = 'Score: $_score';
    goldText.text = 'Gold: $_gold';
    levelText.text = _level.label;
    goalText.text = _goal;
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
