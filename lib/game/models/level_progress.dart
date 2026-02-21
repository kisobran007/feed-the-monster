part of '../../main.dart';

class LevelCompletionResult {
  final GameLevel level;
  final int mistakes;
  final int earnedStars;
  final int previousBestStars;
  final int bestStarsAfterRun;
  final int earnedCoins;
  final int totalCoinsAfterRun;

  const LevelCompletionResult({
    required this.level,
    required this.mistakes,
    required this.earnedStars,
    required this.previousBestStars,
    required this.bestStarsAfterRun,
    required this.earnedCoins,
    required this.totalCoinsAfterRun,
  });
}
