part of '../../main.dart';

class StartOverlay extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenLevels;

  const StartOverlay({
    super.key,
    required this.onStart,
    required this.onOpenShop,
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
              'Monster Munch',
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Swipe food to monster, swipe bad items to bin!',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Start The Game',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onOpenShop,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
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
