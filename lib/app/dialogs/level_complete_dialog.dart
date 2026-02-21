part of '../../main.dart';

Future<void> showLevelCompleteDialog(
  BuildContext context, {
  required LevelCompletionResult result,
  required bool hasNextLevel,
  required VoidCallback onContinue,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF171717),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '${result.level.label} Complete!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    3,
                    (index) => _AnimatedResultStar(
                      isFilled: index < result.earnedStars,
                      delayMs: index * 120,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Best stars: ${_starsLabel(result.bestStarsAfterRun)}',
                  style: const TextStyle(color: Color(0xFFFFE082), fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  result.earnedCoins > 0
                      ? 'Earned: +${result.earnedCoins} coins'
                      : 'Best reward already claimed',
                  style: TextStyle(
                    color: result.earnedCoins > 0
                        ? const Color(0xFF81C784)
                        : Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total coins: ${result.totalCoinsAfterRun}',
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mistakes: ${result.mistakes}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContinue();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
              ),
              child: Text(hasNextLevel ? 'Next Level' : 'Replay Level'),
            ),
          ],
        ),
      );
    },
  );
}

class _AnimatedResultStar extends StatelessWidget {
  final bool isFilled;
  final int delayMs;

  const _AnimatedResultStar({
    required this.isFilled,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isFilled ? 1 : 0.65),
      duration: Duration(milliseconds: 380 + delayMs),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          isFilled ? Icons.star : Icons.star_border,
          color: isFilled ? const Color(0xFFFFD54F) : Colors.white38,
          size: 44,
        ),
      ),
    );
  }
}
