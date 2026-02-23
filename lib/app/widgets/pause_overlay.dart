part of '../../main.dart';

class PauseOverlay extends StatelessWidget {
  static const double _buttonHeight = 56;

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final Future<void> Function() onOpenShop;
  final Future<void> Function() onOpenLevels;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onExit;

  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onOpenShop,
    required this.onOpenLevels,
    required this.onOpenSettings,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xCC0F1115),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelWidth = min(constraints.maxWidth - 24, 420).toDouble();
              final titleSize = constraints.maxWidth < 420 ? 40.0 : 46.0;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Container(
                    width: panelWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    decoration: BoxDecoration(
                      color: const Color(0xB31A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Monster Munch',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Game Menu',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                        const SizedBox(height: 20),
                        _menuButton(
                          label: 'Resume',
                          icon: Icons.play_arrow_rounded,
                          color: const Color(0xFF43A047),
                          onPressed: onResume,
                        ),
                        const SizedBox(height: 10),
                        _menuButton(
                          label: 'Shop',
                          icon: Icons.storefront_rounded,
                          color: const Color(0xFF42A5F5),
                          onPressed: onOpenShop,
                        ),
                        const SizedBox(height: 10),
                        _menuButton(
                          label: 'Levels',
                          icon: Icons.flag_rounded,
                          color: const Color(0xFFFFA726),
                          onPressed: onOpenLevels,
                        ),
                        const SizedBox(height: 10),
                        _menuButton(
                          label: 'Settings',
                          icon: Icons.settings_rounded,
                          color: const Color(0xFF8E8E93),
                          onPressed: onOpenSettings,
                        ),
                        const SizedBox(height: 10),
                        _menuButton(
                          label: 'Start New Game',
                          icon: Icons.replay_rounded,
                          color: const Color(0xFFFF7043),
                          onPressed: onRestart,
                        ),
                        const SizedBox(height: 10),
                        _menuButton(
                          label: 'Exit',
                          icon: Icons.logout_rounded,
                          color: const Color(0xFFE53935),
                          onPressed: onExit,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _menuButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: _buttonHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
