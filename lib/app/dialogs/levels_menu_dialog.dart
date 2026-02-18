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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: levels
                        .map(
                          (level) => ChoiceChip(
                            label: Text(level.label),
                            selected: selectedLevel == level,
                            onSelected: (_) {
                              setDialogState(() {
                                selectedLevel = level;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isUnlocked ? 'Status: Unlocked' : 'Status: Locked',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (!isUnlocked && selectedLevel == GameLevel.level2)
                    const Text(
                      'Complete objectives in Level 1 to unlock.',
                      style: TextStyle(color: Color(0xFFFFAB91)),
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
