part of '../../main.dart';

enum ItemModifier {
  none,
  freeze,
  fake,
  bomb,
}

class FallingItem extends SpriteComponent
    with DragCallbacks, HasGameReference<MonsterTapGame> {
  final String itemType;
  final bool isGood;
  final ItemModifier modifier;
  final Function(FallingItem, Vector2) onDropped;
  final Function(FallingItem) onMissed;
  final Function(FallingItem, Vector2)? onDragMoved;
  final double fallSpeed; // pixels per second
  static const double _itemSize = 125;
  static const double _modifierAuraBaseInflate = 5.5;
  static const double _modifierAuraPulse = 2.6;
  static final Paint _goodGlowSoftPaint = Paint()
    ..color = const Color(0x4D3ECF6A)
    ..style = PaintingStyle.fill;
  static final Paint _goodGlowCorePaint = Paint()
    ..color = const Color(0x7032B85A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _badGlowSoftPaint = Paint()
    ..color = const Color(0x4DE53935)
    ..style = PaintingStyle.fill;
  static final Paint _badGlowCorePaint = Paint()
    ..color = const Color(0x70C62828)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _freezePaint = Paint()..color = const Color(0xFF4FC3F7);
  static final Paint _fakePaint = Paint()..color = const Color(0xFFCE93D8);
  static final Paint _bombPaint = Paint()..color = const Color(0xFFFFB74D);
  static final Paint _freezeAuraPaint = Paint()
    ..color = const Color(0x664FC3F7)
    ..style = PaintingStyle.fill;
  static final Paint _fakeAuraPaint = Paint()
    ..color = const Color(0x66D946EF)
    ..style = PaintingStyle.fill;
  static final Paint _bombAuraPaint = Paint()
    ..color = const Color(0x66FF6A00)
    ..style = PaintingStyle.fill;
  static final Paint _freezeStrokePaint = Paint()
    ..color = const Color(0xFFB3E5FC)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  static final Paint _fakeStrokePaint = Paint()
    ..color = const Color(0xFF6D28D9)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  static final Paint _bombStrokePaint = Paint()
    ..color = const Color(0xFF1F1F1F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4;
  static final Paint _badgeStrokePaint = Paint()
    ..color = const Color(0xFF121212)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _symbolPaint = Paint()
    ..color = const Color(0xFF101010)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 2.2;
  bool _isDragging = false;
  bool _isHandled = false;
  Vector2? _lastPointerCanvasPosition;
  double _fxTime = 0;

  bool get isEffectivelyGood => modifier != ItemModifier.fake && isGood;

  FallingItem({
    required this.itemType,
    required this.isGood,
    this.modifier = ItemModifier.none,
    required this.onDropped,
    required this.onMissed,
    this.onDragMoved,
    required this.fallSpeed,
  });

  @override
  Future<void> onLoad() async {
    sprite = await game.loadSprite('items/$itemType.png');
    size = Vector2.all(_itemSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _fxTime += dt;
    if (!_isDragging) {
      position.y += fallSpeed * dt * game.fallSpeedMultiplier;
    }

    // Miss only when item fully leaves gameplay from the bottom while not dragging.
    if (!_isHandled && !_isDragging && position.y > game.size.y + 50) {
      _isHandled = true;
      onMissed(this);
      removeFromParent();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    _lastPointerCanvasPosition = event.canvasPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_isHandled) return;
    position += event.canvasDelta;
    _lastPointerCanvasPosition = event.canvasStartPosition.clone();
    onDragMoved?.call(this, _lastPointerCanvasPosition!.clone());
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_isHandled) return;
    _isDragging = false;
    _isHandled = true;
    onDropped(this, (_lastPointerCanvasPosition ?? position).clone());
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _isDragging = false;
    _lastPointerCanvasPosition = null;
  }

  @override
  void render(Canvas canvas) {
    final wobble = _modifierCanvasOffset();
    if (wobble != Offset.zero) {
      canvas.save();
      canvas.translate(wobble.dx, wobble.dy);
    }

    final itemRect = Rect.fromLTWH(0, 0, size.x, size.y);
    if (isGood) {
      final halo = RRect.fromRectAndRadius(
        itemRect.inflate(2),
        const Radius.circular(15),
      );
      final core = RRect.fromRectAndRadius(
        itemRect.inflate(0.75),
        const Radius.circular(13),
      );
      canvas.drawRRect(halo, _goodGlowSoftPaint);
      canvas.drawRRect(core, _goodGlowCorePaint);
    } else {
      final halo = RRect.fromRectAndRadius(
        itemRect.inflate(2),
        const Radius.circular(15),
      );
      final core = RRect.fromRectAndRadius(
        itemRect.inflate(0.75),
        const Radius.circular(13),
      );
      canvas.drawRRect(halo, _badGlowSoftPaint);
      canvas.drawRRect(core, _badGlowCorePaint);
    }
    _renderModifierAura(canvas, itemRect);
    _renderModifierBadge(canvas);
    super.render(canvas);

    if (wobble != Offset.zero) {
      canvas.restore();
    }
  }

  Offset _modifierCanvasOffset() {
    switch (modifier) {
      case ItemModifier.freeze:
        return Offset(0, sin(_fxTime * 2.8) * 1.8);
      case ItemModifier.fake:
        return Offset(sin(_fxTime * 17.0) * 1.5, 0);
      case ItemModifier.bomb:
        return Offset(sin(_fxTime * 23.0) * 1.3, cos(_fxTime * 19.0) * 1.0);
      case ItemModifier.none:
        return Offset.zero;
    }
  }

  void _renderModifierAura(Canvas canvas, Rect itemRect) {
    if (modifier == ItemModifier.none) return;
    final pulse = _modifierAuraBaseInflate +
        sin(_fxTime * 6.0).abs() * _modifierAuraPulse;
    final auraRect = RRect.fromRectAndRadius(
      itemRect.inflate(pulse),
      const Radius.circular(18),
    );
    switch (modifier) {
      case ItemModifier.freeze:
        canvas.drawRRect(auraRect, _freezeAuraPaint);
        canvas.drawRRect(auraRect, _freezeStrokePaint);
        break;
      case ItemModifier.fake:
        canvas.drawRRect(auraRect, _fakeAuraPaint);
        canvas.drawRRect(auraRect.shift(const Offset(2, -1)), _fakeStrokePaint);
        canvas.drawRRect(auraRect.shift(const Offset(-2, 1)), _fakeStrokePaint);
        break;
      case ItemModifier.bomb:
        canvas.drawRRect(auraRect, _bombAuraPaint);
        canvas.drawRRect(auraRect, _bombStrokePaint);
        break;
      case ItemModifier.none:
        break;
    }
  }

  void _renderModifierBadge(Canvas canvas) {
    if (modifier == ItemModifier.none) return;

    final center = Offset(size.x * 0.83, size.y * 0.18);
    final rect = Rect.fromCenter(center: center, width: 30, height: 30);
    switch (modifier) {
      case ItemModifier.freeze:
        canvas.drawCircle(center, 14, _freezePaint);
        canvas.drawCircle(center, 14, _badgeStrokePaint);
        _drawFreezeSymbol(canvas, center);
        break;
      case ItemModifier.fake:
        final diamond = Path()
          ..moveTo(center.dx, rect.top)
          ..lineTo(rect.right, center.dy)
          ..lineTo(center.dx, rect.bottom)
          ..lineTo(rect.left, center.dy)
          ..close();
        canvas.drawPath(diamond, _fakePaint);
        canvas.drawPath(diamond, _badgeStrokePaint);
        _drawBadgeText(canvas, center, '?');
        break;
      case ItemModifier.bomb:
        final bombRect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(9),
        );
        canvas.drawRRect(bombRect, _bombPaint);
        canvas.drawRRect(bombRect, _badgeStrokePaint);
        _drawBadgeText(canvas, center, '!');
        break;
      case ItemModifier.none:
        return;
    }
  }

  void _drawFreezeSymbol(Canvas canvas, Offset center) {
    const arm = 8.0;
    canvas.drawLine(
      Offset(center.dx - arm, center.dy),
      Offset(center.dx + arm, center.dy),
      _symbolPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - arm),
      Offset(center.dx, center.dy + arm),
      _symbolPaint,
    );
    const diag = arm * 0.72;
    canvas.drawLine(
      Offset(center.dx - diag, center.dy - diag),
      Offset(center.dx + diag, center.dy + diag),
      _symbolPaint,
    );
    canvas.drawLine(
      Offset(center.dx - diag, center.dy + diag),
      Offset(center.dx + diag, center.dy - diag),
      _symbolPaint,
    );
  }

  void _drawBadgeText(Canvas canvas, Offset center, String label) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
}
