part of '../../main.dart';
class Monster extends SpriteComponent with HasGameReference<MonsterTapGame> {
  static const String _monsterId = 'monster_main';
  static const Map<GameWorld, Map<String, String>> _skinAssetPaths = {
    GameWorld.world1: {
      'idle': 'characters/world1/$_monsterId/idle.png',
      'happy': 'characters/world1/$_monsterId/happy.png',
      'sad': 'characters/world1/$_monsterId/sad.png',
    },
    GameWorld.world2: {
      'idle': 'characters/world2/$_monsterId/idle.png',
      'happy': 'characters/world2/$_monsterId/happy.png',
      'sad': 'characters/world2/$_monsterId/sad.png',
    },
  };

  String currentState = 'idle';
  int _reactionId = 0;
  static const Duration _reactionDuration = Duration(milliseconds: 500);
  static const double _idleSize = 240;
  static const double _happySize = 265;
  static const double _sadSize = 215;
  final Random _random = Random();
  final List<String> _happySounds = ['happy_1.mp3', 'happy_2.mp3'];
  final List<String> _sadSounds = ['sad_1.mp3', 'sad_2.mp3'];
  late MonsterReactionIndicator reactionIndicator;
  late Sprite idleSprite;
  late Sprite happySprite;
  late Sprite sadSprite;
  Sprite? _hatSprite;
  SpriteComponent? _hatOverlay;
  bool _hatOverlayAttached = false;
  String? _hatAssetPath;
  int _hatLoadToken = 0;
  double _idleTime = 0;
  static const double _idleAmplitude = 0.035; // 3.5%
  static const double _idleSpeed = 2.5;
  GameWorld currentWorld = GameWorld.world1;

  @override
  Future<void> onLoad() async {
    FlameAudio.audioCache.prefix = 'assets/sounds/';
    await FlameAudio.audioCache.loadAll([..._happySounds, ..._sadSounds]);

    await _loadSkinSprites(currentWorld);
    sprite = idleSprite;
    size = Vector2.all(_idleSize);

    reactionIndicator = MonsterReactionIndicator()
      ..anchor = Anchor.center;
    add(reactionIndicator);
    _layoutReactionIndicator();
    _layoutAccessories();
    _applyAccessoryVisibility();
  }

  Future<void> loadWorldSkin(GameWorld world) async {
    currentWorld = world;
    await _loadSkinSprites(world);

    showIdle();
    _applyAccessoryVisibility();
  }

  Future<void> _loadSkinSprites(GameWorld world) async {
    final skinPaths = _skinAssetPaths[world];
    if (skinPaths == null) {
      throw StateError('Missing skin path config for world: $world');
    }
    idleSprite = await game.loadSprite(skinPaths['idle']!);
    happySprite = await game.loadSprite(skinPaths['happy']!);
    sadSprite = await game.loadSprite(skinPaths['sad']!);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (currentState == 'idle') {
      _idleTime += dt;
      final scaleValue =
          1 + _idleAmplitude * sin(_idleTime * _idleSpeed);
      scale = Vector2.all(scaleValue);
    } else {
      // reset scale when not idle
      scale = Vector2.all(1);
    }
  }

  void showHappy() {
    currentState = 'happy';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = happySprite;
    _playReactionSound(_happySounds);
    reactionIndicator.showHappy();
    size = Vector2.all(_happySize);
    _layoutReactionIndicator();
    _layoutAccessories();
    Future.delayed(_reactionDuration, () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void showOops() {
    currentState = 'oops';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = sadSprite;
    _playReactionSound(_sadSounds);
    reactionIndicator.showOops();
    size = Vector2.all(_sadSize);
    _layoutReactionIndicator();
    _layoutAccessories();
    Future.delayed(_reactionDuration, () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void showIdle() {
    currentState = 'idle';
    sprite = idleSprite;
    reactionIndicator.hideIndicator();
    size = Vector2.all(_idleSize);
    _layoutReactionIndicator();
    _layoutAccessories();
  }

  void showGameOver() {
    _reactionId += 1;
    currentState = 'game_over';
    sprite = sadSprite;
    _playReactionSound(_sadSounds);
    reactionIndicator.showGameOver();
    size = Vector2.all(_sadSize);
    _layoutReactionIndicator();
    _layoutAccessories();
  }

  void showStreak() {
    currentState = 'streak';
    _reactionId += 1;
    final currentId = _reactionId;
    sprite = happySprite;
    _playReactionSound(_happySounds);
    reactionIndicator.showStreak();
    size = Vector2.all(_happySize + 12);
    _layoutReactionIndicator();
    _layoutAccessories();
    Future.delayed(const Duration(milliseconds: 620), () {
      if (_reactionId == currentId) showIdle();
    });
  }

  void setHatAccessoryAssetPath(String? assetPath) {
    if (_hatAssetPath == assetPath) return;
    _hatAssetPath = assetPath;
    _loadHatSprite(assetPath);
  }

  void _playReactionSound(List<String> sounds) {
    if (sounds.isEmpty) return;
    final sound = sounds[_random.nextInt(sounds.length)];
    FlameAudio.play(sound);
  }

  void _layoutReactionIndicator() {
    reactionIndicator.position = Vector2(size.x / 2, -54);
  }

  void _layoutAccessories() {
    if (_hatOverlay == null) return;
    _hatOverlay!
      ..position = Vector2(size.x * 0.5, size.y * 0.02)
      ..size = Vector2(size.x * 0.74, size.y * 0.36);
  }

  void _applyAccessoryVisibility() {
    final shouldShowHat = _hatOverlay != null && _hatSprite != null;
    if (shouldShowHat && !_hatOverlayAttached) {
      add(_hatOverlay!);
      _hatOverlayAttached = true;
    } else if (!shouldShowHat && _hatOverlayAttached) {
      _hatOverlay!.removeFromParent();
      _hatOverlayAttached = false;
    }
  }

  Future<void> _loadHatSprite(String? assetPath) async {
    final token = ++_hatLoadToken;
    if (_hatOverlayAttached && _hatOverlay != null) {
      _hatOverlay!.removeFromParent();
    }
    _hatOverlayAttached = false;
    if (assetPath == null || assetPath.isEmpty) {
      _hatSprite = null;
      _hatOverlay = null;
      _applyAccessoryVisibility();
      return;
    }
    try {
      final sprite = await game.loadSprite(assetPath);
      if (token != _hatLoadToken) return;
      _hatSprite = sprite;
      _hatOverlay = SpriteComponent(
        sprite: _hatSprite,
        anchor: Anchor.center,
        priority: 12,
      );
      _layoutAccessories();
      _applyAccessoryVisibility();
    } catch (_) {
      if (token != _hatLoadToken) return;
      _hatSprite = null;
      _hatOverlay = null;
      _applyAccessoryVisibility();
    }
  }
}

enum MonsterReactionState {
  none,
  happy,
  oops,
  streak,
  gameOver,
}

class MonsterReactionIndicator extends PositionComponent {
  MonsterReactionState state = MonsterReactionState.none;
  double _time = 0;

  final Paint _happyPaint = Paint()..color = const Color(0xFFFFD54F);
  final Paint _oopsPaint = Paint()..color = const Color(0xFFE53935);
  final Paint _streakPaint = Paint()..color = const Color(0xFFFFEE58);
  final Paint _gameOverPaint = Paint()..color = const Color(0xFF64B5F6);

  MonsterReactionIndicator() {
    size = Vector2(120, 64);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  void showHappy() => state = MonsterReactionState.happy;
  void showOops() => state = MonsterReactionState.oops;
  void showStreak() => state = MonsterReactionState.streak;
  void showGameOver() => state = MonsterReactionState.gameOver;
  void hideIndicator() => state = MonsterReactionState.none;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (state == MonsterReactionState.none) return;

    final pulse = 1 + 0.12 * sin(_time * 8);
    final center = Offset(size.x / 2, size.y / 2);

    if (state == MonsterReactionState.happy) {
      _drawOrbitDots(canvas, center, 20 * pulse, 3, _happyPaint, 8);
    } else if (state == MonsterReactionState.oops) {
      _drawCross(canvas, center, 22 * pulse, _oopsPaint);
      canvas.drawCircle(center.translate(-18, 0), 4 * pulse, _oopsPaint);
      canvas.drawCircle(center.translate(18, 0), 4 * pulse, _oopsPaint);
    } else if (state == MonsterReactionState.streak) {
      _drawOrbitDots(canvas, center, 26 * pulse, 5, _streakPaint, 9);
    } else if (state == MonsterReactionState.gameOver) {
      canvas.drawCircle(center.translate(-10, 6), 7 * pulse, _gameOverPaint);
      canvas.drawCircle(center.translate(10, 6), 7 * pulse, _gameOverPaint);
      canvas.drawCircle(center.translate(0, 20), 5 * pulse, _gameOverPaint);
    }
  }

  void _drawOrbitDots(
    Canvas canvas,
    Offset center,
    double radius,
    int count,
    Paint paint,
    double dotRadius,
  ) {
    for (var i = 0; i < count; i++) {
      final angle = (_time * 2.8) + (2 * pi * i / count);
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * (radius * 0.6);
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  void _drawCross(Canvas canvas, Offset center, double halfSize, Paint paint) {
    final stroke = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - halfSize, center.dy - halfSize),
      Offset(center.dx + halfSize, center.dy + halfSize),
      stroke,
    );
    canvas.drawLine(
      Offset(center.dx + halfSize, center.dy - halfSize),
      Offset(center.dx - halfSize, center.dy + halfSize),
      stroke,
    );
  }
}

