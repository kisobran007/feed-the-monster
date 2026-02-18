part of '../../main.dart';

class AudioController {
  final Random _random = Random();
  final List<String> _tracks;
  bool _ready = false;

  AudioController({
    List<String> tracks = const ['bgm_playful_01.mp3', 'bgm_playful_02.mp3'],
  }) : _tracks = tracks;

  Future<void> init() async {
    FlameAudio.audioCache.prefix = 'assets/sounds/';
    await FlameAudio.audioCache.loadAll(_tracks);
    FlameAudio.bgm.initialize();
    _ready = true;
  }

  void playRandomTrack({double volume = 0.28}) {
    if (!_ready || _tracks.isEmpty) return;
    final track = _tracks[_random.nextInt(_tracks.length)];
    FlameAudio.bgm.stop();
    FlameAudio.bgm.play(track, volume: volume);
  }

  void pause() {
    if (!_ready) return;
    FlameAudio.bgm.pause();
  }

  void resume() {
    if (!_ready) return;
    FlameAudio.bgm.resume();
  }

  void stop() {
    FlameAudio.bgm.stop();
  }
}
