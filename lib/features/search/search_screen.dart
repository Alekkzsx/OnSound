import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/media_item.dart';
import '../../core/services/search_service.dart';
import '../../core/services/drive_service.dart';
import '../../core/services/youtube_service.dart';
import '../../core/services/soundcloud_service.dart';
import '../library/library_screen.dart';

/// Notifier para gerenciar a lógica da busca e estados de carregamento.
class SearchNotifier extends StateNotifier<AsyncValue<List<MediaItem>>> {
  final SearchService _searchService;
  SearchNotifier(this._searchService) : super(const AsyncValue.data([]));

  Future<void> performSearch(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final results = await _searchService.searchAll(query);
      state = AsyncValue.data(results);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provedores de estado para a busca.
final searchStateProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<MediaItem>>>((ref) {
  return SearchNotifier(ref.watch(searchServiceProvider));
});

/// Tela de busca premium que permite encontrar e baixar músicas do YT e SoundCloud.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Inicia focado na barra de busca para melhor UX.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'O que você quer ouvir?',
            hintStyle: TextStyle(color: Colors.white38),
            border: InputBorder.none,
          ),
          onSubmitted: (value) => ref.read(searchStateProvider.notifier).performSearch(value),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: searchResults.when(
        data: (items) {
          if (items.isEmpty && _searchController.text.isNotEmpty) {
            return const Center(child: Text('Nenhum resultado encontrado.', style: TextStyle(color: Colors.white)));
          }
          if (items.isEmpty) {
            return const Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 80, color: Colors.white),
                    SizedBox(height: 16),
                    Text('Busque milhões de músicas no YT e SoundCloud', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: item.thumbnailUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.white10),
                    errorWidget: (context, url, error) => const Icon(Icons.music_note),
                  ),
                ),
                title: Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Row(
                  children: [
                    Icon(
                      item.source == MediaSourceType.youtube ? Icons.video_library : Icons.cloud,
                      size: 12,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(item.artist, style: const TextStyle(color: Colors.white38), maxLines: 1)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                  onPressed: () => _showSaveConfirmation(context, ref, item),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: SpinKitPulse(color: Colors.white, size: 50.0),
        ),
        error: (err, stack) => Center(child: Text('Erro: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  /// Exibe diálogo de confirmação e processa o upload por stream.
  void _showSaveConfirmation(BuildContext context, WidgetRef ref, MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Adicionar à Biblioteca?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('A música será salva diretamente no seu Google Drive.', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  _processUpload(ref, item);
                },
                child: const Text('Confirmar'),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white38))),
            ],
          ),
        );
      },
    );
  }

  /// Lógica de extração e upload por stream.
  Future<void> _processUpload(WidgetRef ref, MediaItem item) async {
    // ScaffoldMessenger para feedback visual.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SpinKitThreeBounce(color: Colors.white, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text('Enviando "${item.title}" para o Drive...')),
          ],
        ),
        duration: const Duration(seconds: 30),
      ),
    );

    try {
      final driveService = ref.read(driveServiceProvider);
      if (driveService == null) throw Exception('Drive não conectado');

      Stream<List<int>> audioStream;
      if (item.source == MediaSourceType.youtube) {
        audioStream = await ref.read(youtubeServiceProvider).getAudioStream(item.id);
      } else {
        audioStream = await ref.read(soundCloudServiceProvider).getAudioStream(item.id);
      }

      await driveService.uploadMediaStream(
        name: '${item.title}.mp3', // Simplificando a extensão para compatibilidade
        stream: audioStream,
        thumbnailUrl: item.thumbnailUrl,
        source: item.source,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Música adicionada com sucesso!'), backgroundColor: Colors.green),
      );
      
      // Atualiza a biblioteca para mostrar a nova música.
      ref.invalidate(musicListProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
