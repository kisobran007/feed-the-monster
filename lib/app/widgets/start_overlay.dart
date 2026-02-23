part of '../../main.dart';

class StartOverlay extends StatelessWidget {
  static const double _buttonWidth = 280;
  static const double _buttonHeight = 58;

  final VoidCallback onStart;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenLevels;
  final Future<void> Function() onGoogleSignIn;
  final bool isSigningIn;
  final String? signedInEmail;
  final Future<void> Function() onExit;

  const StartOverlay({
    super.key,
    required this.onStart,
    required this.onOpenShop,
    required this.onOpenLevels,
    required this.onGoogleSignIn,
    required this.isSigningIn,
    required this.signedInEmail,
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
              'Swipe food to monster, swipe bad items to bin!',
              style: TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                minimumSize: const Size(_buttonWidth, _buttonHeight),
                maximumSize: const Size(_buttonWidth, _buttonHeight),
              ),
              child: const Text(
                'Start The Game',
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
              onPressed: (isSigningIn || signedInEmail != null)
                  ? null
                  : onGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF),
                foregroundColor: const Color(0xFF222222),
                minimumSize: const Size(_buttonWidth, _buttonHeight),
                maximumSize: const Size(_buttonWidth, _buttonHeight),
              ),
              child: Text(
                isSigningIn
                    ? 'Signing In...'
                    : (signedInEmail != null
                        ? 'Google Signed In'
                        : 'Sign in with Google'),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
