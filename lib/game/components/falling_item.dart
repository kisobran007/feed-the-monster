part of '../../main.dart';

class FallingItem extends SpriteComponent
    with DragCallbacks, HasGameReference<MonsterTapGame> {
  final String itemType;
  final bool isGood;
  final Function(FallingItem, Vector2) onDropped;
  final Function(FallingItem) onMissed;
  final Function(FallingItem, Vector2)? onDragMoved;
  final double fallSpeed; // pixels per second
  static const double _itemSize = 125;
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
  bool _isDragging = false;
  bool _isHandled = false;
  Vector2? _lastPointerCanvasPosition;

  FallingItem({
    required this.itemType,
    required this.isGood,
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
    if (!_isDragging) {
      position.y += fallSpeed * dt;
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
    super.render(canvas);
  }
}
