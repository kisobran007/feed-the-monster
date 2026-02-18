part of '../../main.dart';

class SpawnController {
  final double baseSpawnInterval;
  final double minSpawnInterval;
  final double spawnIntervalStep;
  final double difficultyTickSeconds;
  final double baseFallSpeed;
  final double maxFallSpeed;
  final double fallSpeedStep;

  double _difficultyTimer = 0;
  double _spawnTimer = 0;
  double _currentSpawnInterval;
  double _currentFallSpeed;

  double get currentFallSpeed => _currentFallSpeed;

  SpawnController({
    this.baseSpawnInterval = 1.8,
    this.minSpawnInterval = 0.95,
    this.spawnIntervalStep = 0.08,
    this.difficultyTickSeconds = 15,
    this.baseFallSpeed = 85,
    this.maxFallSpeed = 170,
    this.fallSpeedStep = 8,
  })  : _currentSpawnInterval = baseSpawnInterval,
        _currentFallSpeed = baseFallSpeed;

  void reset() {
    _difficultyTimer = 0;
    _spawnTimer = 0;
    _currentSpawnInterval = baseSpawnInterval;
    _currentFallSpeed = baseFallSpeed;
  }

  bool tick(double dt) {
    _difficultyTimer += dt;
    if (_difficultyTimer >= difficultyTickSeconds) {
      _difficultyTimer = 0;
      _currentSpawnInterval =
          max(minSpawnInterval, _currentSpawnInterval - spawnIntervalStep);
      _currentFallSpeed = min(maxFallSpeed, _currentFallSpeed + fallSpeedStep);
    }

    _spawnTimer += dt;
    if (_spawnTimer < _currentSpawnInterval) {
      return false;
    }
    _spawnTimer = 0;
    return true;
  }
}
