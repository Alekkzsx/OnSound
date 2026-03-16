import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/song.dart';

final audioPlayerProvider = Provider((ref) => AudioPlayer());

final audioServiceProvider = Provider((ref) {
  final player = ref.watch(audioPlayerProvider);
  return AudioService(player);
});

class AudioService {
  final AudioPlayer _player;

  AudioService(this._player) {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  /// Toca uma música (do local se existir, senão via streaming)
  Future<void> playSong(Song song, {String? streamUrl}) async {
    try {
      if (song.localPath != null) {
        await _player.setFilePath(song.localPath!);
      } else if (streamUrl != null) {
        await _player.setUrl(streamUrl);
      }
      _player.play();
    } catch (e) {
      print('Erro ao tocar música: $e');
    }
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
}
