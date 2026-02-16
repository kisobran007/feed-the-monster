part of '../../main.dart';
class WorldTransitionOverlay extends PositionComponent
    with HasGameReference<MonsterTapGame> {
  final GameWorld nextWorld;
  final VoidCallback onSwitchWorld;
  final VoidCallback onCompleted;
  final double durationSeconds;

  double _elapsed = 0;
  bool _didSwitch = false;

  WorldTransitionOverlay({
    required this.nextWorld,
    required this.onSwitchWorld,
    required this.onCompleted,
    this.durationSeconds = 1.0,
  }) {
    priority = 200;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    final t = (_elapsed / durationSeconds).clamp(0.0, 1.0);

    if (!_didSwitch && t >= 0.5) {
      _didSwitch = true;
      onSwitchWorld();
    }

    if (t >= 1.0) {
      onCompleted();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / durationSeconds).clamp(0.0, 1.0);
    final fade = t < 0.5
        ? Curves.easeInOut.transform(t / 0.5)
        : Curves.easeInOut.transform((1 - t) / 0.5);
    final overlayOpacity = (0.65 * fade).clamp(0.0, 0.65);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, game.size.x, game.size.y),
      Paint()..color = Colors.black.withValues(alpha: overlayOpacity),
    );

    if (fade > 0.2) {
      final worldLabel = nextWorld == GameWorld.world2 ? 'World 2' : 'World 1';
      final textPainter = TextPainter(
        text: TextSpan(
          text: worldLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 8)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final offset = Offset(
        (game.size.x - textPainter.width) / 2,
        (game.size.y - textPainter.height) / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }
}

// Score display component
