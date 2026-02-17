part of '../main.dart';

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameScreen(),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MonsterTapGame game;
  bool hasStarted = false;
  bool isPaused = false;
  bool isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    game = MonsterTapGame();
  }

  void _startGame() {
    game.startGame();
    setState(() {
      hasStarted = true;
      isPaused = false;
      isMenuOpen = false;
    });
  }

  void _openInGameMenu() {
    if (!hasStarted || game.isGameOver) return;
    if (!isPaused) {
      game.pauseGame();
    }
    setState(() {
      isPaused = true;
      isMenuOpen = true;
    });
  }

  void _resumeFromMenu() {
    game.resumeGame();
    setState(() {
      isPaused = false;
      isMenuOpen = false;
    });
  }

  void _restartFromMenu() {
    game.startNewGameFromMenu();
    setState(() {
      hasStarted = true;
      isPaused = false;
      isMenuOpen = false;
    });
  }

  Future<void> _openMonsterMenu() async {
    await game.loadCustomizationProgress();
    if (!mounted) return;

    var previewState = 'idle';
    var coins = game.totalCoins;
    var showHatPreview = true;
    String selectedMonsterId = game.selectedMonsterId;
    String? selectedHatId;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final monsterItems = game.availableMonsters;
            final selectedMonster = monsterItems.firstWhere(
              (monster) => monster.id == selectedMonsterId,
              orElse: () => monsterItems.first,
            );
            final monsterUnlocked = game.isMonsterUnlocked(selectedMonster.id);
            final monsterSelected = game.isMonsterSelected(selectedMonster.id);
            final hatItems = game
                .accessoriesFor(
                  world: GameWorld.world1,
                  monsterId: selectedMonster.id,
                )
                .where((item) => item.slot == AccessorySlot.hat)
                .toList();
            final equippedHatId = game.equippedAccessoryIdForTarget(
              world: GameWorld.world1,
              monsterId: selectedMonster.id,
            );
            if (selectedHatId == null ||
                !hatItems.any((item) => item.id == selectedHatId)) {
              selectedHatId = equippedHatId;
              if (selectedHatId == null && hatItems.isNotEmpty) {
                selectedHatId = hatItems.first.id;
              }
            }
            final selectedHat = selectedHatId == null
                ? null
                : hatItems.firstWhere((item) => item.id == selectedHatId);
            final hatUnlocked = selectedHat != null
                ? game.isAccessoryUnlocked(selectedHat.id)
                : false;
            final hatEquipped = selectedHat != null
                ? game.isAccessoryEquipped(
                    accessoryId: selectedHat.id,
                    world: GameWorld.world1,
                    monsterId: selectedMonster.id,
                  )
                : false;
            final monsterPath =
                'assets/images/characters/world1/${selectedMonster.id}/$previewState.png';
            final hatPath = selectedHat == null
                ? null
                : 'assets/images/${selectedHat.assetPath}';

            return AlertDialog(
              backgroundColor: const Color(0xFF1F1F1F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              title: const Text(
                'My Monster',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 360,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Coins: $coins',
                          style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: const Color(0x33000000),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x66FFFFFF)),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Image.asset(monsterPath,
                                    fit: BoxFit.contain),
                              ),
                              if (showHatPreview && hatPath != null)
                                Positioned(
                                  top: 8,
                                  child: SizedBox(
                                    width: 150,
                                    height: 92,
                                    child: Opacity(
                                      opacity: hatUnlocked ? 1.0 : 0.75,
                                      child: Image.asset(hatPath,
                                          fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('Idle'),
                              selected: previewState == 'idle',
                              onSelected: (_) =>
                                  setDialogState(() => previewState = 'idle'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Happy'),
                              selected: previewState == 'happy',
                              onSelected: (_) =>
                                  setDialogState(() => previewState = 'happy'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Sad'),
                              selected: previewState == 'sad',
                              onSelected: (_) =>
                                  setDialogState(() => previewState = 'sad'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x22000000),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x44FFFFFF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Monsters',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: monsterItems
                                    .map(
                                      (monster) => ChoiceChip(
                                        label: Text(monster.label),
                                        selected:
                                            selectedMonsterId == monster.id,
                                        onSelected: (_) {
                                          setDialogState(() {
                                            selectedMonsterId = monster.id;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                monsterUnlocked
                                    ? (monsterSelected
                                        ? 'Status: Selected in game'
                                        : 'Status: Unlocked')
                                    : 'Status: Locked',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              if (!monsterUnlocked)
                                Text(
                                  'Unlock cost: ${selectedMonster.unlockCost} coins',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (!monsterUnlocked)
                                    ElevatedButton(
                                      onPressed:
                                          coins >= selectedMonster.unlockCost
                                              ? () async {
                                                  final ok =
                                                      await game.unlockMonster(
                                                          selectedMonster.id);
                                                  if (!ok) return;
                                                  await game.selectMonster(
                                                      selectedMonster.id);
                                                  await game
                                                      .loadCustomizationProgress();
                                                  setDialogState(() {
                                                    coins = game.totalCoins;
                                                    selectedMonsterId =
                                                        game.selectedMonsterId;
                                                    selectedHatId = null;
                                                  });
                                                }
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF43A047),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Unlock & Select'),
                                    ),
                                  if (monsterUnlocked)
                                    ElevatedButton(
                                      onPressed: monsterSelected
                                          ? null
                                          : () async {
                                              await game.selectMonster(
                                                  selectedMonster.id);
                                              await game
                                                  .loadCustomizationProgress();
                                              setDialogState(() {
                                                coins = game.totalCoins;
                                                selectedMonsterId =
                                                    game.selectedMonsterId;
                                                selectedHatId = null;
                                              });
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF42A5F5),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(monsterSelected
                                          ? 'Selected'
                                          : 'Select'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x22000000),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x44FFFFFF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: const Color(0x33000000),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: hatPath == null
                                        ? const Icon(
                                            Icons.block,
                                            color: Colors.white54,
                                          )
                                        : Image.asset(hatPath,
                                            fit: BoxFit.contain),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedHat?.label ??
                                              'No hats available',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          selectedHat == null
                                              ? 'Add hat assets for this monster'
                                              : 'Cost: ${selectedHat.cost} coins',
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilterChip(
                                    label: const Text('Preview'),
                                    selected: showHatPreview,
                                    onSelected: (v) => setDialogState(
                                        () => showHatPreview = v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                selectedHat == null
                                    ? 'Status: No items'
                                    : hatUnlocked
                                        ? (hatEquipped
                                            ? 'Status: Equipped in game'
                                            : 'Status: Unlocked')
                                        : 'Status: Locked',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              if (selectedHat != null &&
                                  !hatUnlocked &&
                                  coins < selectedHat.cost)
                                Text(
                                  'Need ${selectedHat.cost - coins} more coins',
                                  style:
                                      const TextStyle(color: Color(0xFFFFAB91)),
                                ),
                              const SizedBox(height: 8),
                              const Text(
                                'Hats',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: hatItems
                                    .map(
                                      (item) => ChoiceChip(
                                        label: Text(item.label),
                                        selected: selectedHatId == item.id,
                                        onSelected: (_) {
                                          setDialogState(() {
                                            selectedHatId = item.id;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (selectedHat != null && !hatUnlocked)
                                    ElevatedButton(
                                      onPressed: coins >= selectedHat.cost
                                          ? () async {
                                              final ok =
                                                  await game.unlockAccessory(
                                                      selectedHat.id);
                                              if (!ok) return;
                                              await game.setAccessoryEquipped(
                                                selectedHat.id,
                                                world: GameWorld.world1,
                                                monsterId: selectedMonster.id,
                                              );
                                              await game
                                                  .loadCustomizationProgress();
                                              setDialogState(() {
                                                coins = game.totalCoins;
                                              });
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF43A047),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Unlock & Apply'),
                                    ),
                                  if (selectedHat != null && hatUnlocked)
                                    ElevatedButton(
                                      onPressed: hatEquipped
                                          ? null
                                          : () async {
                                              await game.setAccessoryEquipped(
                                                selectedHat.id,
                                                world: GameWorld.world1,
                                                monsterId: selectedMonster.id,
                                              );
                                              await game
                                                  .loadCustomizationProgress();
                                              setDialogState(() {
                                                coins = game.totalCoins;
                                              });
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF42A5F5),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(
                                          hatEquipped ? 'Applied' : 'Apply'),
                                    ),
                                  if (selectedHat != null && hatUnlocked)
                                    OutlinedButton(
                                      onPressed: hatEquipped
                                          ? () async {
                                              await game.clearEquippedAccessory(
                                                world: GameWorld.world1,
                                                monsterId: selectedMonster.id,
                                              );
                                              await game
                                                  .loadCustomizationProgress();
                                              setDialogState(() {
                                                coins = game.totalCoins;
                                              });
                                            }
                                          : null,
                                      child: const Text('Remove'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Color(0xFF81C784)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: game),
        if (!hasStarted)
          Positioned.fill(
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
                    'Swipe food to monster, swipe bad items to bin!',
                    style: TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _startGame,
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _openMonsterMenu,
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
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (hasStarted)
          Positioned(
            top: 18,
            right: 18,
            child: ElevatedButton(
              onPressed: _openInGameMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xCC111111),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Menu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (isPaused && isMenuOpen)
          Positioned.fill(
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
                    onPressed: _resumeFromMenu,
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
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _restartFromMenu,
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
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        isMenuOpen = false;
                      });
                      await _openMonsterMenu();
                      if (!mounted || !hasStarted || !isPaused) return;
                      setState(() {
                        isMenuOpen = true;
                      });
                    },
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
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
