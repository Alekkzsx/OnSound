import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/song.dart';

/// Provedor para a instância única do AudioPlayer.
final audioPlayerProvider = Provider((ref) => AudioPlayer());

/// Provedor para o [AudioService], que encapsula a lógica de reprodução.
final audioServiceProvider = Provider((ref) {
  final player = ref.watch(audioPlayerProvider);
  return AudioService(player);
});

/// Serviço responsável por gerenciar a reprodução de áudio no aplicativo.
/// Utiliza o pacote [just_audio] para suporte a streaming e arquivos locais.
class AudioService {
  final AudioPlayer _player;

  AudioService(this._player) {
    _init();
  }

  /// Inicializa a sessão de áudio do sistema, configurando-a para reprodução de música.
  /// Isso garante que o aplicativo se comporte corretamente com outros sons do dispositivo.
  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  /// Stream que emite o estado atual do player.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream que emite a música que está sendo reproduzida no momento.
  final _currentSongSubject = BehaviorSubject<Song?>();
  Stream<Song?> get currentSongStream => _currentSongSubject.stream;

  /// Inicia a reprodução de uma música.
  /// Se a música estiver offline, toca o arquivo local. 
  /// Caso contrário, busca a URL de streaming autenticada do Drive.
  Future<void> playSong(Song song, {String? accessToken}) async {
    try {
      _currentSongSubject.add(song);

      if (song.isOffline && song.localPath != null) {
        await _player.setFilePath(song.localPath!);
      } else {
        // Gera a URL de streaming direto da API do Google Drive v3
        final streamUrl = 'https://www.googleapis.com/drive/v3/files/${song.driveId}?alt=media';
        
        // Configura o player com o cabeçalho de autorização necessário
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(streamUrl),
            headers: accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null,
          ),
        );
      }
      _player.play();
    } catch (e) {
      debugPrint('Erro ao reproduzir música: $e');
    }
  }

  /// Pausa a reprodução.
  Future<void> pause() => _player.pause();

  /// Continua a reprodução pausada.
  Future<void> resume() => _player.play();

  /// Encerra a reprodução e limpa o player.
  Future<void> stop() async {
    await _player.stop();
    _currentSongSubject.add(null); // Limpa a música atual
  }

  /// Altera a posição atual da música.
  Future<void> seek(Duration position) => _player.seek(position);

  /// Stream que emite a posição atual de reprodução em tempo real.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream que fornece a duração total da música carregada.
  Stream<Duration?> get durationStream => _player.durationStream;
}
