import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/media_item.dart';

/// Provedor global para o serviço do YouTube.
final youtubeServiceProvider = Provider((ref) => YoutubeService());

/// Serviço responsável por interagir com o YouTube via `youtube_explode_dart`.
class YoutubeService {
  final _yt = YoutubeExplode();

  /// Realiza uma busca no YouTube e retorna uma lista de [MediaItem].
  Future<List<MediaItem>> search(String query) async {
    try {
      // Realiza a busca por vídeos.
      final results = await _yt.search.search(query);
      
      return results.map((video) {
        return MediaItem(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          thumbnailUrl: video.thumbnails.mediumResUrl,
          duration: video.duration,
          source: MediaSourceType.youtube,
          originalUrl: video.url,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtém o stream de áudio de melhor qualidade para um vídeo específico.
  Future<Stream<List<int>>> getAudioStream(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    // Filtrar apenas streams de áudio e pegar o de maior bitrate.
    final audioStream = manifest.audioOnly.withHighestBitrate();
    return _yt.videos.streamsClient.get(audioStream);
  }

  /// Fecha o cliente quando não for mais necessário.
  void dispose() {
    _yt.close();
  }
}
