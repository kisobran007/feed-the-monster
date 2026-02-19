part of '../../main.dart';

class ObjectiveDisplay extends PositionComponent
    with HasGameReference<MonsterTapGame> {
  int _gold = 0;
  GameLevel _level = GameLevel.level1;
  List<LevelObjective> _objectives = <LevelObjective>[];
  final Map<ObjectiveType, double> _pulseByType = <ObjectiveType, double>{};
  double _sparkleClock = 0;

  void updateHud({
    required int gold,
    required GameLevel level,
    required List<LevelObjective> objectives,
    ObjectiveType? bumpedObjective,
  }) {
    _gold = gold;
    _level = level;
    _objectives = objectives;
    if (bumpedObjective != null) {
      _pulseByType[bumpedObjective] = 1;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sparkleClock += dt;
    final keys = _pulseByType.keys.toList();
    for (final type in keys) {
      final next = (_pulseByType[type] ?? 0) - (dt * 2.8);
      if (next <= 0) {
        _pulseByType.remove(type);
      } else {
        _pulseByType[type] = next;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final panelWidth = min(460.0, game.size.x * 0.9);
    const rowHeight = 34.0;
    final panelHeight = 108.0 + (_objectives.length * rowHeight);
    size = Vector2(panelWidth, panelHeight);

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, panelWidth, panelHeight),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      panelRect,
      Paint()..color = const Color(0xAA111111),
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x66FFFFFF),
    );

    _paintText(
      canvas,
      text: '${_level.label}    Coins: $_gold',
      offset: const Offset(14, 12),
      style: const TextStyle(
        color: Color(0xFFFFE082),
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );

    final completedCount = _completedGoalCount();
    final totalGoals = _trackableGoalCount();
    _paintText(
      canvas,
      text: 'Completed: $completedCount / $totalGoals',
      offset: const Offset(14, 40),
      style: const TextStyle(
        color: Color(0xFFB3E5FC),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );

    var y = 78.0;
    for (final objective in _objectives) {
      final pulse = _pulseByType[objective.type] ?? 0;
      final completed = _isVisuallyCompleted(objective);
      final isConstraint = _isConstraintObjective(objective.type);
      final rowRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(10, y - 4, panelWidth - 20, rowHeight - 4),
        const Radius.circular(10),
      );
      final rowColor = completed ? const Color(0x3343A047) : const Color(0x22000000);
      canvas.drawRRect(rowRect, Paint()..color = rowColor);
      if (pulse > 0) {
        canvas.drawRRect(
          rowRect,
          Paint()
            ..color = Color.lerp(
              const Color(0x00000000),
              const Color(0x55FFFFFF),
              pulse,
            )!,
        );
      }

      final label = _objectiveLabel(objective.type);
      final progressText = '${objective.current} / ${objective.target}';
      final color = completed
          ? const Color(0xFFB9F6CA)
          : isConstraint
              ? const Color(0xFFFFE082)
              : const Color(0xFFF5F5F5);
      _paintText(
        canvas,
        text: '$label   $progressText',
        offset: Offset(18, y),
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      );

      if (completed) {
        _paintText(
          canvas,
          text: 'OK',
          offset: Offset(panelWidth - 36, y + 2),
          style: const TextStyle(
            color: Color(0xFF69F0AE),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        );
        if (!isConstraint) {
          _drawSparkles(canvas, panelWidth - 46, y + 10);
        }
      }
      y += rowHeight;
    }
  }

  String _objectiveLabel(ObjectiveType type) {
    switch (type) {
      case ObjectiveType.feedHealthy:
        return '\u{1F966} Feed Healthy';
      case ObjectiveType.throwJunk:
        return '\u{1F5D1} Throw Junk';
      case ObjectiveType.maxMistakes:
        return '\u{26A0} Mistakes Limit';
      case ObjectiveType.comboStreak:
        return '\u{1F525} Combo';
    }
  }

  bool _isConstraintObjective(ObjectiveType type) {
    return type == ObjectiveType.maxMistakes;
  }

  bool _isVisuallyCompleted(LevelObjective objective) {
    if (_isConstraintObjective(objective.type)) {
      return false;
    }
    return objective.isCompleted;
  }

  int _trackableGoalCount() {
    final nonConstraint =
        _objectives.where((objective) => !_isConstraintObjective(objective.type)).length;
    if (nonConstraint == 0) {
      return _objectives.length;
    }
    return nonConstraint;
  }

  int _completedGoalCount() {
    final nonConstraint = _objectives
        .where((objective) => !_isConstraintObjective(objective.type))
        .toList();
    if (nonConstraint.isEmpty) {
      return _objectives.where((objective) => objective.isCompleted).length;
    }
    return nonConstraint.where((objective) => objective.isCompleted).length;
  }

  void _drawSparkles(Canvas canvas, double x, double y) {
    final sparklePaint = Paint()..color = const Color(0xFFFFF59D);
    for (var i = 0; i < 3; i++) {
      final angle = _sparkleClock * 3.5 + (i * 2.094);
      final dx = cos(angle) * 7;
      final dy = sin(angle) * 5;
      canvas.drawCircle(Offset(x + dx, y + dy), 1.8, sparklePaint);
    }
  }

  void _paintText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required TextStyle style,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }
}
