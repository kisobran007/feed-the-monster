part of '../../main.dart';

class PauseOverlay extends StatelessWidget {
  static const double _buttonWidth = 280;
  static const double _buttonHeight = 58;

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final Future<void> Function() onOpenShop;
  final Future<void> Function() onOpenLevels;
  final Future<void> Function() onExit;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onOpenShop,
    required this.onOpenLevels,
    required this.onExit,
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
              'Monster Munch',
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
                minimumSize: const Size(_buttonWidth, _buttonHeight),
                maximumSize: const Size(_buttonWidth, _buttonHeight),
              ),
              child: const Text(
                'Resume',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
                minimumSize: const Size(_buttonWidth, _buttonHeight),
                maximumSize: const Size(_buttonWidth, _buttonHeight),
              ),
              child: const Text(
                'Start New Game',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onOpenShop,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
                minimumSize: const Size(_buttonWidth, _buttonHeight),
                maximumSize: const Size(_buttonWidth, _buttonHeight),
              ),
              child: const Text(
                'Shop',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onOpenLevels,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
                foregroundColor: Colors.white,
                minimumSize: const Size(_buttonWidth, _buttonHeight),
                maximumSize: const Size(_buttonWidth, _buttonHeight),
              ),
              child: const Text(
                'Levels',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                minimumSize: const Size(_buttonWidth, _buttonHeight),
                maximumSize: const Size(_buttonWidth, _buttonHeight),
              ),
              child: const Text(
                'Exit',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
