part of '../../main.dart';

enum GameLevel {
  level1,
  level2,
}

extension GameLevelX on GameLevel {
  String get label => this == GameLevel.level1 ? 'Level 1' : 'Level 2';
}
