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
    var hatUnlocked = game.isWorld1HatUnlocked;
    var hatEquipped = game.isWorld1HatEquipped;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final monsterPath =
                'assets/images/characters/world1/monster_main/$previewState.png';
            const hatPath =
                'assets/images/characters/world1/monster_main/accessories/hat.png';

            return AlertDialog(
              backgroundColor: const Color(0xFF1F1F1F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: const Text(
                'My Monster',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 360,
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
                            child: Image.asset(monsterPath, fit: BoxFit.contain),
                          ),
                          if (hatUnlocked && hatEquipped)
                            Positioned(
                              top: 8,
                              child: SizedBox(
                                width: 150,
                                height: 92,
                                child: Image.asset(hatPath, fit: BoxFit.contain),
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
                          onSelected: (_) => setDialogState(() => previewState = 'idle'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Happy'),
                          selected: previewState == 'happy',
                          onSelected: (_) => setDialogState(() => previewState = 'happy'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Sad'),
                          selected: previewState == 'sad',
                          onSelected: (_) => setDialogState(() => previewState = 'sad'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      hatUnlocked
                          ? (hatEquipped ? 'Hat status: Equipped' : 'Hat status: Unlocked')
                          : 'Hat status: Locked',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    if (!hatUnlocked)
                      ElevatedButton(
                        onPressed: () async {
                          if (coins < MonsterTapGame.world1HatCost) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Not enough coins to unlock hat.'),
                              ),
                            );
                            return;
                          }
                          final ok = await game.unlockWorld1Hat();
                          if (!ok) return;
                          await game.loadCustomizationProgress();
                          setDialogState(() {
                            coins = game.totalCoins;
                            hatUnlocked = game.isWorld1HatUnlocked;
                            hatEquipped = game.isWorld1HatEquipped;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Unlock Hat (60)'),
                      ),
                    if (hatUnlocked)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton(
                            onPressed: hatEquipped
                                ? null
                                : () async {
                                    await game.setWorld1HatEquipped(true);
                                    await game.loadCustomizationProgress();
                                    setDialogState(() {
                                      coins = game.totalCoins;
                                      hatUnlocked = game.isWorld1HatUnlocked;
                                      hatEquipped = game.isWorld1HatEquipped;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF42A5F5),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(hatEquipped ? 'Equipped' : 'Equip Hat'),
                          ),
                          OutlinedButton(
                            onPressed: hatEquipped
                                ? () async {
                                    await game.setWorld1HatEquipped(false);
                                    await game.loadCustomizationProgress();
                                    setDialogState(() {
                                      coins = game.totalCoins;
                                      hatUnlocked = game.isWorld1HatUnlocked;
                                      hatEquipped = game.isWorld1HatEquipped;
                                    });
                                  }
                                : null,
                            child: const Text('Unequip'),
                          ),
                        ],
                      ),
                  ],
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
                    'Tap good food, avoid bad items!',
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
