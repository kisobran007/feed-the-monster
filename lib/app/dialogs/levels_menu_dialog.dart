part of '../../main.dart';

Future<void> showLevelsMenuDialog(
  BuildContext context,
  MonsterTapGame game, {
  required VoidCallback onLevelApplied,
}) async {
  await game.loadCustomizationProgress();
  if (!context.mounted) return;

  var selectedLevel = game.selectedLevel;
  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final levels = game.availableLevels;
          final isUnlocked = game.isLevelUnlocked(selectedLevel);
          final selectedBestStars = game.bestStarsForLevel(selectedLevel);
          return AlertDialog(
            backgroundColor: const Color(0xFF1F1F1F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: const Text(
              'Levels',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...levels.map(
                    (level) {
                      final levelUnlocked = game.isLevelUnlocked(level);
                      final levelStars = game.bestStarsForLevel(level);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: selectedLevel == level
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0x33FFFFFF),
                            ),
                          ),
                          tileColor: const Color(0x22000000),
                          title: Text(
                            level.label,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Best: ${_starsLabel(levelStars)}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Text(
                            levelUnlocked ? 'Unlocked' : 'Locked',
                            style: TextStyle(
                              color: levelUnlocked
                                  ? const Color(0xFF81C784)
                                  : const Color(0xFFFFAB91),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () {
                            setDialogState(() {
                              selectedLevel = level;
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Selected best stars: ${_starsLabel(selectedBestStars)}',
                    style: const TextStyle(color: Color(0xFFFFE082)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isUnlocked ? 'Status: Unlocked' : 'Status: Locked',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (!isUnlocked)
                    Text(
                      'Earn at least 1 star in Level ${selectedLevel.levelNumber - 1} to unlock.',
                      style: const TextStyle(color: Color(0xFFFFAB91)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: isUnlocked
                    ? () async {
                        final navigator = Navigator.of(context);
                        await game.selectLevel(selectedLevel);
                        navigator.pop();
                        onLevelApplied();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Play Level'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _starsLabel(int stars) {
  final normalized = stars.clamp(0, 3).toInt();
  return List<String>.generate(
    3,
    (index) => index < normalized ? '★' : '☆',
  ).join(' ');
}
