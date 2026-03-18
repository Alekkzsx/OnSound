import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import 'youtube_service.dart';
import 'soundcloud_service.dart';

/// Provedor global para o serviço de busca unificada.
final searchServiceProvider = Provider((ref) {
  final yt = ref.watch(youtubeServiceProvider);
  final sc = ref.watch(soundCloudServiceProvider);
  return SearchService(yt, sc);
});

/// Serviço que coordena buscas em múltiplas plataformas.
class SearchService {
  final YoutubeService _yt;
  final SoundCloudService _sc;

  SearchService(this._yt, this._sc);

  /// Realiza busca simultânea em todas as plataformas disponíveis.
  Future<List<MediaItem>> searchAll(String query) async {
    if (query.isEmpty) return [];

    // Dispara buscas em paralelo para melhor performance.
    final searches = await Future.wait([
      _yt.search(query),
      _sc.search(query),
    ]);

    // Combina os resultados em uma lista única.
    final allResults = searches.expand((x) => x).toList();
    
    // Opcional: Embaralhar ou ordenar por relevância (aqui mantemos a ordem de retorno).
    return allResults;
  }
}
