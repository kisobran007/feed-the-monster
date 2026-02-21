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
  final int timeLimitSeconds;
  final double spawnRateMultiplier;
  final double fallSpeedMultiplier;
  final double freezeChance;
  final double fakeChance;
  final double bombChance;

  String get id => 'level$levelNumber';
  String get label => 'Level $levelNumber';

  const GameLevel({
    required this.levelNumber,
    required this.objectives,
    required this.timeLimitSeconds,
    this.spawnRateMultiplier = 1,
    this.fallSpeedMultiplier = 1,
    this.freezeChance = 0,
    this.fakeChance = 0,
    this.bombChance = 0,
  });

  GameLevel freshRunCopy() {
    return GameLevel(
      levelNumber: levelNumber,
      objectives: objectives.map((objective) => objective.clone()).toList(),
      timeLimitSeconds: timeLimitSeconds,
      spawnRateMultiplier: spawnRateMultiplier,
      fallSpeedMultiplier: fallSpeedMultiplier,
      freezeChance: freezeChance,
      fakeChance: fakeChance,
      bombChance: bombChance,
    );
  }

  static final GameLevel level1 = GameLevel(
    levelNumber: 1,
    timeLimitSeconds: 80,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 15),
      LevelObjective(type: ObjectiveType.throwJunk, target: 10),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 3),
    ],
  );

  static final GameLevel level2 = GameLevel(
    levelNumber: 2,
    timeLimitSeconds: 78,
    spawnRateMultiplier: 1.04,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 20),
      LevelObjective(type: ObjectiveType.throwJunk, target: 15),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 2),
    ],
  );

  static final GameLevel level3 = GameLevel(
    levelNumber: 3,
    timeLimitSeconds: 76,
    spawnRateMultiplier: 1.08,
    fallSpeedMultiplier: 1.03,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 24),
      LevelObjective(type: ObjectiveType.throwJunk, target: 18),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 2),
    ],
  );

  static final GameLevel level4 = GameLevel(
    levelNumber: 4,
    timeLimitSeconds: 72,
    spawnRateMultiplier: 1.12,
    fallSpeedMultiplier: 1.06,
    freezeChance: 0.08,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 18),
      LevelObjective(type: ObjectiveType.throwJunk, target: 18),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 2),
    ],
  );

  static final GameLevel level5 = GameLevel(
    levelNumber: 5,
    timeLimitSeconds: 70,
    spawnRateMultiplier: 1.14,
    fallSpeedMultiplier: 1.08,
    freezeChance: 0.1,
    fakeChance: 0.08,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 22),
      LevelObjective(type: ObjectiveType.throwJunk, target: 20),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 2),
    ],
  );

  static final GameLevel level6 = GameLevel(
    levelNumber: 6,
    timeLimitSeconds: 68,
    spawnRateMultiplier: 1.17,
    fallSpeedMultiplier: 1.1,
    freezeChance: 0.1,
    fakeChance: 0.1,
    bombChance: 0.06,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 24),
      LevelObjective(type: ObjectiveType.throwJunk, target: 22),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 2),
    ],
  );

  static final GameLevel level7 = GameLevel(
    levelNumber: 7,
    timeLimitSeconds: 64,
    spawnRateMultiplier: 1.2,
    fallSpeedMultiplier: 1.13,
    freezeChance: 0.12,
    fakeChance: 0.1,
    bombChance: 0.07,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 26),
      LevelObjective(type: ObjectiveType.throwJunk, target: 24),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 2),
    ],
  );

  static final GameLevel level8 = GameLevel(
    levelNumber: 8,
    timeLimitSeconds: 62,
    spawnRateMultiplier: 1.22,
    fallSpeedMultiplier: 1.15,
    freezeChance: 0.12,
    fakeChance: 0.12,
    bombChance: 0.08,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 28),
      LevelObjective(type: ObjectiveType.throwJunk, target: 25),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 2),
    ],
  );

  static final GameLevel level9 = GameLevel(
    levelNumber: 9,
    timeLimitSeconds: 58,
    spawnRateMultiplier: 1.25,
    fallSpeedMultiplier: 1.18,
    freezeChance: 0.13,
    fakeChance: 0.14,
    bombChance: 0.09,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 30),
      LevelObjective(type: ObjectiveType.throwJunk, target: 27),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 1),
    ],
  );

  static final GameLevel level10 = GameLevel(
    levelNumber: 10,
    timeLimitSeconds: 55,
    spawnRateMultiplier: 1.28,
    fallSpeedMultiplier: 1.2,
    freezeChance: 0.14,
    fakeChance: 0.15,
    bombChance: 0.1,
    objectives: [
      LevelObjective(type: ObjectiveType.feedHealthy, target: 32),
      LevelObjective(type: ObjectiveType.throwJunk, target: 30),
      LevelObjective(type: ObjectiveType.maxMistakes, target: 1),
    ],
  );

  static final List<GameLevel> values = [
    level1,
    level2,
    level3,
    level4,
    level5,
    level6,
    level7,
    level8,
    level9,
    level10,
  ];

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
