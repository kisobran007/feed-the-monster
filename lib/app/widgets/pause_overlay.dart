part of '../../main.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final Future<void> Function() onOpenMonster;
  final Future<void> Function() onOpenLevels;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onOpenMonster,
    required this.onOpenLevels,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xDD111111),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Monster Tap Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Game Menu',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onResume,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Resume',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Start New Game',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onOpenMonster,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'My Monster',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onOpenLevels,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'Levels',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
