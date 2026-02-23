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
  StreamSubscription<User?>? _authSubscription;
  bool hasStarted = false;
  bool isPaused = false;
  bool isMenuOpen = false;
  bool isSigningIn = false;
  User? signedInUser;

  @override
  void initState() {
    super.initState();
    game = MonsterTapGame();
    game.onLevelCompleted = _handleLevelCompleted;
    if (Firebase.apps.isNotEmpty) {
      signedInUser = FirebaseAuth.instance.currentUser;
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
        user,
      ) {
        if (!mounted) return;
        setState(() {
          signedInUser = user;
        });
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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

  Future<void> _openSettingsFromPause() async {
    setState(() {
      isMenuOpen = false;
    });
    await _openSettingsPanel();
    if (!mounted || !hasStarted || !isPaused) return;
    setState(() {
      isMenuOpen = true;
    });
  }

  Future<void> _exitApp() async {
    await SystemNavigator.pop();
  }

  Future<void> _syncCloudSaveNow() async {
    if (signedInUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect Cloud Save first.')),
      );
      return;
    }
    await game.loadCustomizationProgress();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cloud save synced.')));
  }

  Future<void> _signOutCloudSave() async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    setState(() {
      signedInUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cloud Save disconnected.')),
    );
  }

  Future<void> _openAccountPanel() async {
    if (!mounted) return;
    final connected = signedInUser != null;
    final email = signedInUser?.email;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  connected
                      ? 'Connected as ${email ?? signedInUser!.uid}'
                      : 'Connect Google to protect progress across devices.',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 18),
                if (!connected)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSigningIn
                          ? null
                          : () {
                              Navigator.of(sheetContext).pop('connect');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F1F1F),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        isSigningIn ? 'Connecting...' : 'Sign In via Google',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (connected) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop('sync');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A65B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Sync Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(sheetContext).pop('disconnect');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Disconnect',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    switch (action) {
      case 'connect':
        await _signInWithGoogle();
        break;
      case 'sync':
        await _syncCloudSaveNow();
        break;
      case 'disconnect':
        await _signOutCloudSave();
        break;
      default:
        break;
    }
  }

  Future<void> _openSettingsPanel() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: const Color(0xFF1E1E1E),
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: const Text(
                    'Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    signedInUser == null ? 'Not connected' : 'Connected',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openAccountPanel();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    if (isSigningIn) return;
    if (signedInUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud Save is already connected.')),
      );
      return;
    }
    if (kIsWeb && Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Web Firebase is not configured. Add FIREBASE_WEB_* dart-define values.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSigningIn = true;
    });

    try {
      final result = await AuthService.signInWithGoogle();
      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign in canceled.')),
        );
        return;
      }

      final email = result.user?.email;
      setState(() {
        signedInUser = result.user;
      });
      await game.loadCustomizationProgress();
      if (!mounted) return;
      final message = email == null
          ? 'Successfully signed in with Google.'
          : 'Successfully signed in: $email';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSigningIn = false;
        });
      }
    }
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
            onOpenSettings: _openSettingsPanel,
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
            onOpenSettings: _openSettingsFromPause,
            onExit: _exitApp,
          ),
      ],
    );
  }
}
