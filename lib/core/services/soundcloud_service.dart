import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundcloud_explode_dart/soundcloud_explode_dart.dart';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

/// Provedor global para o serviço do SoundCloud.
final soundCloudServiceProvider = Provider((ref) => SoundCloudService());

/// Serviço responsável por interagir com o SoundCloud via `soundcloud_explode_dart`.
class SoundCloudService {
  final _sc = SoundcloudClient();

  /// Realiza uma busca no SoundCloud e retorna uma lista de [MediaItem].
  Future<List<MediaItem>> search(String query) async {
    try {
      // getTracks retorna um Stream de lotes de resultados. Pegamos o primeiro lote.
      final stream = _sc.search.getTracks(query);
      final firstBatch = await stream.first;
      
      return firstBatch.map((track) {
        return MediaItem(
          id: track.id.toString(),
          title: track.title,
          artist: track.user.username,
          thumbnailUrl: track.artworkUrl?.toString() ?? '',
          duration: Duration(milliseconds: track.duration.toInt()),
          source: MediaSourceType.soundcloud,
          originalUrl: track.permalinkUrl.toString(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtém o stream de áudio de uma track do SoundCloud.
  Future<Stream<List<int>>> getAudioStream(String trackId) async {
    final id = int.parse(trackId);
    final streams = await _sc.tracks.getStreams(id);
    // Pega o primeiro stream disponível (geralmente hls ou http).
    final streamInfo = streams.first;
    
    final client = http.Client();
    final response = await client.send(http.Request('GET', Uri.parse(streamInfo.url)));
    return response.stream;
  }
}
