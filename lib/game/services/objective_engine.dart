part of '../../main.dart';

class ObjectiveEngine {
  late GameLevel _activeLevel;
  int _goodStreak = 0;
  int _mistakes = 0;

  List<LevelObjective> get objectives => _activeLevel.objectives;
  int get goodStreak => _goodStreak;
  int get mistakes => _mistakes;

  void resetForLevel(GameLevel level) {
    _activeLevel = level.freshRunCopy();
    _goodStreak = 0;
    _mistakes = 0;
  }

  ObjectiveType? registerGoodFeed() {
    _goodStreak += 1;
    return _incrementObjective(ObjectiveType.feedHealthy);
  }

  ObjectiveType? registerJunkThrow() {
    _goodStreak += 1;
    return _incrementObjective(ObjectiveType.throwJunk);
  }

  ObjectiveType? syncComboProgress() {
    final objective = _objectiveByType(ObjectiveType.comboStreak);
    if (objective == null) return null;
    if (_goodStreak <= objective.current) return null;
    final next = min(_goodStreak, objective.target);
    if (next == objective.current) return null;
    objective.current = next;
    return ObjectiveType.comboStreak;
  }

  ObjectiveType? registerMistake() {
    _goodStreak = 0;
    _mistakes += 1;
    final objective = _objectiveByType(ObjectiveType.maxMistakes);
    if (objective == null) return null;
    objective.current = _mistakes;
    return ObjectiveType.maxMistakes;
  }

  bool get isMistakeLimitExceeded {
    final objective = _objectiveByType(ObjectiveType.maxMistakes);
    if (objective == null) return false;
    return _mistakes > objective.target;
  }

  bool get isLevelCompleted {
    return objectives.every((objective) => objective.isCompleted);
  }

  int get completedObjectivesCount {
    return objectives.where((objective) => objective.isCompleted).length;
  }

  LevelObjective? _objectiveByType(ObjectiveType type) {
    for (final objective in objectives) {
      if (objective.type == type) return objective;
    }
    return null;
  }

  ObjectiveType? _incrementObjective(ObjectiveType type, {int by = 1}) {
    final objective = _objectiveByType(type);
    if (objective == null) return null;
    final previous = objective.current;
    objective.current = min(objective.target, objective.current + by);
    if (objective.current == previous) return null;
    return type;
  }
}
