part of '../../main.dart';

class GameOverDisplay extends PositionComponent
    with TapCallbacks, HasGameReference<MonsterTapGame> {
  late TextComponent titleText;
  late TextComponent actionText;
  bool isVisible = false;
  bool isCompletedState = false;
  List<LevelObjective> _objectives = <LevelObjective>[];

  @override
  Future<void> onLoad() async {
    size = Vector2(420, 320);

    titleText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.2),
    );

    actionText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellow,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, size.y * 0.87),
    );

    add(titleText);
    add(actionText);
    _layoutText();
  }

  void setDisplaySize(Vector2 newSize) {
    size = newSize;
    _layoutText();
  }

  void _layoutText() {
    titleText.position = Vector2(size.x / 2, size.y * 0.2);
    actionText.position = Vector2(size.x / 2, size.y * 0.87);
  }

  void showLevelCompleted(List<LevelObjective> objectives) {
    isVisible = true;
    isCompletedState = true;
    _objectives = objectives.map((objective) => objective.clone()).toList();
    titleText.text = 'Level Completed!';
    actionText.text =
        game.hasNextUnlockedLevel ? 'Tap to Continue' : 'Tap to Replay';
  }

  void showLevelFailed(
    List<LevelObjective> objectives, {
    String title = 'Level Failed',
  }) {
    isVisible = true;
    isCompletedState = false;
    _objectives = objectives.map((objective) => objective.clone()).toList();
    titleText.text = title;
    actionText.text = 'Tap to Restart';
  }

  void hide() {
    isVisible = false;
    _objectives = <LevelObjective>[];
  }

  @override
  void renderTree(Canvas canvas) {
    if (!isVisible) return;

    final fullRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.9,
      colors: [
        Colors.black.withValues(alpha: 0.12),
        Colors.black.withValues(alpha: 0.78),
      ],
      stops: const [0.35, 1.0],
    );
    canvas.drawRect(fullRect, Paint()..shader = gradient.createShader(fullRect));

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.x * 0.08, size.y * 0.28, size.x * 0.84, size.y * 0.52),
      const Radius.circular(16),
    );
    canvas.drawRRect(panelRect, Paint()..color = const Color(0xDD1E1E1E));
    canvas.drawRRect(
      panelRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = const Color(0x66FFFFFF),
    );

    var y = size.y * 0.35;
    for (final objective in _objectives) {
      final objectiveText =
          '${_objectiveLabel(objective.type)}  ${objective.current}/${objective.target}';
      final ok = objective.isCompleted;
      final style = TextStyle(
        color: ok ? const Color(0xFFB9F6CA) : const Color(0xFFFFCDD2),
        fontSize: 22,
        fontWeight: FontWeight.w700,
      );
      _paintText(canvas, objectiveText, Offset(size.x * 0.16, y), style);
      if (ok) {
        _paintText(
          canvas,
          'OK',
          Offset(size.x * 0.78, y + 2),
          const TextStyle(
            color: Color(0xFF69F0AE),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      y += 34;
    }

    super.renderTree(canvas);
  }

  String _objectiveLabel(ObjectiveType type) {
    switch (type) {
      case ObjectiveType.feedHealthy:
        return 'Feed Healthy';
      case ObjectiveType.throwJunk:
        return 'Throw Junk';
      case ObjectiveType.maxMistakes:
        return 'Mistakes';
      case ObjectiveType.comboStreak:
        return 'Combo';
    }
  }

  void _paintText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!isVisible) return;
    final localPoint = event.localPosition;
    final isOnActionRow = (localPoint.y - actionText.position.y).abs() < 44 &&
        (localPoint.x - actionText.position.x).abs() < (size.x * 0.3);
    if (!isOnActionRow) return;
    if (isCompletedState) {
      game.proceedAfterLevelCompleted();
      return;
    }
    game.restartGame();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    return isVisible;
  }
}
