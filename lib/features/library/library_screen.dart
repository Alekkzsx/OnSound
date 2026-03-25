import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/drive_service.dart';
import '../../models/song.dart';

final musicListProvider = FutureProvider<List<Song>>((ref) async {
  final driveService = ref.watch(driveServiceProvider);
  if (driveService == null) return [];

  final folderId = await driveService.getOrCreateOnSoundFolder();
  if (folderId == null) return [];

  final files = await driveService.listMusicFiles(folderId);
  return files
      .map(
        (f) => Song(
          driveId: f.id ?? '',
          name: f.name ?? 'Desconhecido',
          thumbnailUrl: f.appProperties?['thumbnailUrl'],
        ),
      )
      .toList();
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicList = ref.watch(musicListProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1D2C21), Color(0xFF0A0A0A)],
        ),
      ),
      child: SafeArea(
        child: musicList.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1ED760))),
          error: (err, _) => Center(child: Text('Erro ao carregar biblioteca: $err')),
          data: (songs) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sua Biblioteca', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w800)),
                              SizedBox(height: 6),
                              Text('Colecao pessoal no Google Drive', style: TextStyle(color: Color(0xFFB3B3B3))),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => ref.invalidate(musicListProvider),
                          icon: const Icon(Icons.refresh, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                if (songs.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Nenhuma musica encontrada no Drive ainda. Va em Buscar para montar sua biblioteca.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFB3B3B3)),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                    sliver: SliverList.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return _SongTile(song: song);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SongTile extends ConsumerWidget {
  final Song song;

  const _SongTile({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song.thumbnailUrl != null && song.thumbnailUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: song.thumbnailUrl!,
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white70),
                )
              : const SizedBox(
                  width: 54,
                  height: 54,
                  child: ColoredBox(
                    color: Color(0xFF252525),
                    child: Icon(Icons.music_note, color: Colors.white70),
                  ),
                ),
        ),
        title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          song.isOffline ? 'Disponivel offline' : 'Streaming do Drive',
          style: TextStyle(color: song.isOffline ? const Color(0xFF1ED760) : const Color(0xFFB3B3B3)),
        ),
        trailing: IconButton(
          icon: Icon(
            song.isOffline ? Icons.check_circle : Icons.download_for_offline,
            color: song.isOffline ? const Color(0xFF1ED760) : Colors.white70,
          ),
          onPressed: () async {
            if (song.isOffline) return;
            try {
              final downloadService = ref.read(downloadServiceProvider);
              await downloadService.downloadAndCache(song);
              ref.invalidate(musicListProvider);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao baixar: $e')));
              }
            }
          },
        ),
        onTap: () async {
          final token = await ref.read(authServiceProvider).getAccessToken();
          await ref.read(audioServiceProvider).playSong(song, accessToken: token);
        },
      ),
    );
  }
}
