import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/settings_provider.dart';

class SoundService {
  final Ref _ref;
  final Map<String, AudioPlayer> _players = {};

  SoundService(this._ref);

  bool get _enabled => _ref.read(settingsProvider).soundEnabled;

  Future<void> _play(String assetName) async {
    if (!_enabled) return;
    try {
      var player = _players[assetName];
      if (player == null) {
        player = AudioPlayer();
        _players[assetName] = player;
      }
      await player.play(AssetSource('audio/$assetName'));
    } catch (_) {
      // Never let audio errors crash the game.
    }
  }

  Future<void> playMove() => _play('move.wav');
  Future<void> playCapture() => _play('capture.wav');
  Future<void> playCheck() => _play('check.wav');
  Future<void> playGameOver() => _play('game_over.wav');
  Future<void> playCannon() => _play('cannon.wav');
  Future<void> playExplosion() => _play('explosion.wav');
  Future<void> playClick() => _play('click.wav');

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});
