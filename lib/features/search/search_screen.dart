import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../core/models/media_item.dart';
import '../../core/services/drive_service.dart';
import '../../core/services/search_service.dart';
import '../../core/services/soundcloud_service.dart';
import '../../core/services/youtube_service.dart';
import '../library/library_screen.dart';

class SearchNotifier extends StateNotifier<AsyncValue<List<MediaItem>>> {
  final SearchService _searchService;

  SearchNotifier(this._searchService) : super(const AsyncValue.data([]));

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final results = await _searchService.searchAll(query.trim());
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final searchStateProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<MediaItem>>>((ref) {
  return SearchNotifier(ref.watch(searchServiceProvider));
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const _genreTiles = [
    ('Pop', Color(0xFFE13300), Icons.bolt),
    ('Eletronica', Color(0xFF146EF5), Icons.graphic_eq),
    ('Rap', Color(0xFF5D2E8C), Icons.mic),
    ('Lo-Fi', Color(0xFF0C8A5F), Icons.nights_stay),
    ('Rock', Color(0xFF6D4C41), Icons.album),
    ('Workout', Color(0xFFC7343A), Icons.fitness_center),
  ];

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchStateProvider);
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buscar', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 16),
                    textInputAction: TextInputAction.search,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (value) => ref.read(searchStateProvider.notifier).performSearch(value),
                    decoration: InputDecoration(
                      hintText: 'Artistas, faixas, albuns',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: hasQuery
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                ref.read(searchStateProvider.notifier).performSearch('');
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF262626),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: searchResults.when(
                loading: () => const Center(child: SpinKitPulse(color: Color(0xFF1ED760), size: 50)),
                error: (err, _) => Center(child: Text('Erro na busca: $err')),
                data: (items) {
                  if (!hasQuery) {
                    return _buildDiscovery();
                  }

                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Nenhum resultado encontrado.', style: TextStyle(color: Color(0xFFB3B3B3))),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 120),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item.thumbnailUrl,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: const Color(0xFF2A2A2A)),
                              errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white70),
                            ),
                          ),
                          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${item.artist} • ${item.source == MediaSourceType.youtube ? 'YouTube' : 'SoundCloud'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFB3B3B3)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF1ED760)),
                            onPressed: () => _showSaveConfirmation(context, ref, item),
                          ),
                        ),
                      )
                          .animate(delay: (index * 30).ms)
                          .fadeIn(duration: 220.ms)
                          .slideY(begin: 0.06, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscovery() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 120),
      itemCount: _genreTiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, index) {
        final tile = _genreTiles[index];
        return GestureDetector(
          onTap: () {
            _searchController.text = tile.$1;
            ref.read(searchStateProvider.notifier).performSearch(tile.$1);
            setState(() {});
          },
          child: Container(
            decoration: BoxDecoration(
              color: tile.$2,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tile.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Icon(tile.$3, size: 38, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSaveConfirmation(BuildContext context, WidgetRef ref, MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Adicionar a biblioteca?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                '"${item.title}" sera salva no seu Google Drive.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3B3B3)),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _processUpload(ref, item);
                  },
                  child: const Text('Confirmar'),
                ),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processUpload(WidgetRef ref, MediaItem item) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SpinKitThreeBounce(color: Colors.white, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text('Enviando "${item.title}" para o Drive...')),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final driveService = ref.read(driveServiceProvider);
      if (driveService == null) throw Exception('Drive nao conectado');

      final audioStream = item.source == MediaSourceType.youtube
          ? await ref.read(youtubeServiceProvider).getAudioStream(item.id)
          : await ref.read(soundCloudServiceProvider).getAudioStream(item.id);

      await driveService.uploadMediaStream(
        name: '${item.title}.mp3',
        stream: audioStream,
        thumbnailUrl: item.thumbnailUrl,
        source: item.source,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musica adicionada com sucesso!'), backgroundColor: Color(0xFF14833B)),
      );
      ref.invalidate(musicListProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar: $e'), backgroundColor: const Color(0xFFB3261E)),
      );
    }
  }
}
