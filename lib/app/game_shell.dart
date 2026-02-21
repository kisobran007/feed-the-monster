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
    game.onLevelCompleted = _handleLevelCompleted;
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

  Future<void> _openShop() async {
    await showShopDialog(context, game);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openLevelsMenu() async {
    await showLevelsMenuDialog(
      context,
      game,
      onLevelApplied: () {
        if (!mounted) return;
        if (!hasStarted) {
          game.startGame();
        } else {
          game.startNewGameFromMenu();
        }
        setState(() {
          hasStarted = true;
          isPaused = false;
          isMenuOpen = false;
        });
      },
    );
  }

  Future<void> _openShopFromPause() async {
    setState(() {
      isMenuOpen = false;
    });
    await _openShop();
    if (!mounted || !hasStarted || !isPaused) return;
    setState(() {
      isMenuOpen = true;
    });
  }

  Future<void> _openLevelsMenuFromPause() async {
    setState(() {
      isMenuOpen = false;
    });
    await _openLevelsMenu();
    if (!mounted || !hasStarted || !isPaused) return;
    setState(() {
      isMenuOpen = true;
    });
  }

  Future<void> _exitApp() async {
    await SystemNavigator.pop();
  }

  Future<void> _handleLevelCompleted(LevelCompletionResult result) async {
    if (!mounted) return;
    await showLevelCompleteDialog(
      context,
      result: result,
      hasNextLevel: game.hasNextUnlockedLevel,
      onContinue: () {
        game.proceedAfterLevelCompleted();
        if (!mounted) return;
        setState(() {
          hasStarted = true;
          isPaused = false;
          isMenuOpen = false;
        });
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(game: game),
        if (!hasStarted)
          StartOverlay(
            onStart: _startGame,
            onOpenShop: _openShop,
            onOpenLevels: _openLevelsMenu,
            onExit: _exitApp,
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
          PauseOverlay(
            onResume: _resumeFromMenu,
            onRestart: _restartFromMenu,
            onOpenShop: _openShopFromPause,
            onOpenLevels: _openLevelsMenuFromPause,
            onExit: _exitApp,
          ),
      ],
    );
  }
}
