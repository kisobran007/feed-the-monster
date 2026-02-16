part of '../../main.dart';
class TapBurst extends PositionComponent {
  final Color baseColor;
  final int particleCount;
  final double particleSize;
  final double lifetime;
  final double spreadSpeed;
  final List<Color>? palette;
  final Random _random = Random();

  final List<_BurstParticle> _particles = [];
  double _elapsed = 0;

  TapBurst({
    required Vector2 position,
    required this.baseColor,
    required this.particleCount,
    required this.particleSize,
    required this.lifetime,
    required this.spreadSpeed,
    this.palette,
  }) {
    this.position = position;
    priority = 30;
  }

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = spreadSpeed * (0.55 + _random.nextDouble() * 0.75);
      _particles.add(
        _BurstParticle(
          velocity: Vector2(cos(angle) * speed, sin(angle) * speed),
          size: particleSize * (0.6 + _random.nextDouble() * 0.9),
          color: palette == null
              ? baseColor
              : palette![_random.nextInt(palette!.length)],
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final t = (_elapsed / lifetime).clamp(0.0, 1.0);
    final alpha = (255 * (1 - t)).clamp(0, 255).toInt();
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final x = p.velocity.x * _elapsed;
      final y = p.velocity.y * _elapsed;
      final radius = p.size * (1 - t * 0.7);
      paint.color = p.color.withAlpha(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
}

class _BurstParticle {
  final Vector2 velocity;
  final double size;
  final Color color;

  _BurstParticle({
    required this.velocity,
    required this.size,
    required this.color,
  });
}

