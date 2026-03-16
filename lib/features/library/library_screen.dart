import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/drive_service.dart';
import '../../models/song.dart';
import '../../widgets/mini_player.dart';
import '../settings/settings_screen.dart';

final musicListProvider = FutureProvider<List<Song>>((ref) async {
  final driveService = ref.watch(driveServiceProvider);
  if (driveService == null) return [];

  final folderId = await driveService.getOrCreateOnSoundFolder();
  if (folderId == null) return [];

  final files = await driveService.listMusicFiles(folderId);
  return files.map((f) => Song(
    driveId: f.id ?? '',
    name: f.name ?? 'Desconhecido',
  )).toList();
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicList = ref.watch(musicListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sua Biblioteca'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1DB954), Color(0xFF121212)],
            stops: [0.0, 0.3],
          ),
        ),
        child: musicList.when(
          data: (songs) {
            if (songs.isEmpty) {
              return const Center(child: Text('Nenhuma música encontrada no Drive.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(top: 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.white70),
                  title: Text(song.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    song.isOffline ? 'Disponível Offline' : 'Toque para reproduzir',
                    style: TextStyle(color: song.isOffline ? const Color(0xFF1DB954) : Colors.white60),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white60), // Toggle no futuro
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          song.isOffline ? Icons.check_circle : Icons.download_for_offline,
                          color: song.isOffline ? const Color(0xFF1DB954) : Colors.white60,
                        ),
                        onPressed: () async {
                          if (!song.isOffline) {
                            try {
                              final downloadService = ref.read(downloadServiceProvider);
                              await downloadService.downloadAndCache(song);
                              ref.invalidate(musicListProvider);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao baixar: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    final audioService = ref.read(audioServiceProvider);
                    await audioService.playSong(song, streamUrl: 'URL_DO_DRIVE_STREAMING');
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          error: (err, stack) => Center(child: Text('Erro: $err')),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
