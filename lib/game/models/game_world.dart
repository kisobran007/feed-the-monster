part of '../../main.dart';

enum ObjectiveType {
  feedHealthy,
  throwJunk,
  maxMistakes,
  comboStreak,
}

class LevelObjective {
  final ObjectiveType type;
  final int target;
  int current;

  bool get isCompleted {
    if (type == ObjectiveType.maxMistakes) {
      return current <= target;
    }
    return current >= target;
  }

  LevelObjective({
    required this.type,
    required this.target,
    this.current = 0,
  });

  LevelObjective clone() {
    return LevelObjective(
      type: type,
      target: target,
      current: current,
    );
  }
}

class GameLevel {
  final int levelNumber;
  final List<LevelObjective> objectives;

  String get id => 'level$levelNumber';
  String get label => 'Level $levelNumber';

  const GameLevel({
    required this.levelNumber,
    required this.objectives,
  });

  GameLevel freshRunCopy() {
    return GameLevel(
      levelNumber: levelNumber,
      objectives: objectives.map((objective) => objective.clone()).toList(),
    );
  }

  static final GameLevel level1 = GameLevel(
    levelNumber: 1,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 15),
      LevelObjective(type: ObjectiveType.throwJunk, target: 10),
    ],
  );

  static final GameLevel level2 = GameLevel(
    levelNumber: 2,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 20),
      LevelObjective(type: ObjectiveType.throwJunk, target: 15),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 2),
    ],
  );

  static final List<GameLevel> values = [level1, level2];

  static GameLevel? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final level in values) {
      if (level.id == id) return level;
    }
    return null;
  }

  static GameLevel? fromLevelNumber(int levelNumber) {
    for (final level in values) {
      if (level.levelNumber == levelNumber) {
        return level;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is GameLevel && other.levelNumber == levelNumber;
  }

  @override
  int get hashCode => levelNumber.hashCode;
}
