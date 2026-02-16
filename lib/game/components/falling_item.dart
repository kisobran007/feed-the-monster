part of '../../main.dart';
class FallingItem extends SpriteComponent with TapCallbacks, HasGameRef<MonsterTapGame> {
  final String itemType;
  final bool isGood;
  final Function(FallingItem) onTapped;
  final Function(FallingItem) onMissed;
  final double fallSpeed; // pixels per second
  static const double _itemSize = 125;

  FallingItem({
    required this.itemType,
    required this.isGood,
    required this.onTapped,
    required this.onMissed,
    required this.fallSpeed,
  });

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('items/$itemType.png');
    size = Vector2.all(_itemSize);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += fallSpeed * dt;

    // Remove if off screen
    if (position.y > gameRef.gameplayBottomY + 50) {
      onMissed(this);
      removeFromParent();
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapped(this);
  }
}

