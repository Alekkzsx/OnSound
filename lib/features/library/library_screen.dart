import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/download_service.dart';
import '../../core/services/drive_service.dart';
import '../../models/song.dart';
import '../../widgets/mini_player.dart';
import '../../core/services/auth_service.dart';
import '../settings/settings_screen.dart';
import '../search/search_screen.dart';

/// Provedor assíncrono que busca a lista de músicas do Google Drive.
/// Ele navega até a pasta 'OnSound' e mapeia os arquivos encontrados para objetos [Song].
final musicListProvider = FutureProvider<List<Song>>((ref) async {
  final driveService = ref.watch(driveServiceProvider);
  if (driveService == null) return [];

  // Garante que a pasta do aplicativo existe no Drive.
  final folderId = await driveService.getOrCreateOnSoundFolder();
  if (folderId == null) return [];

  // Lista os arquivos de áudio dentro da pasta identificada.
  final files = await driveService.listMusicFiles(folderId);
  return files.map((f) {
    // Extrai a URL da thumbnail dos metadados customizados do Drive.
    final thumbUrl = f.appProperties?['thumbnailUrl'];
    
    return Song(
      driveId: f.id ?? '',
      name: f.name ?? 'Desconhecido',
      thumbnailUrl: thumbUrl,
    );
  }).toList();
});

/// Tela principal da biblioteca de músicas do usuário.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observa o estado da lista de músicas (loading/data/error).
    final musicList = ref.watch(musicListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sua Biblioteca'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botão de Busca (YouTube/SoundCloud).
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          // Botão para navegar para a tela de configurações.
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
        // Fundo com gradiente estilizado (Verde Spotify para Preto).
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
            // Caso a lista esteja vazia após a busca.
            if (songs.isEmpty) {
              return const Center(child: Text('Nenhuma música encontrada no Drive.'));
            }
            // Constrói a lista rolável de músicas.
            return ListView.builder(
              padding: const EdgeInsets.only(top: 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: song.thumbnailUrl != null
                        ? Image.network(
                            song.thumbnailUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.music_note, color: Colors.white70),
                          )
                        : const Icon(Icons.music_note, color: Colors.white70),
                  ),
                  title: Text(song.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    song.isOffline ? 'Disponível Offline' : 'Toque para reproduzir',
                    style: TextStyle(color: song.isOffline ? const Color(0xFF1DB954) : Colors.white60),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão Favoritar (Placeholder para funcionalidade futura).
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white60),
                        onPressed: () {},
                      ),
                      // Botão de Download/Status Offline.
                      IconButton(
                        icon: Icon(
                          song.isOffline ? Icons.check_circle : Icons.download_for_offline,
                          color: song.isOffline ? const Color(0xFF1DB954) : Colors.white60,
                        ),
                        onPressed: () async {
                          if (!song.isOffline) {
                            try {
                              // Inicia o processo de download e cache local.
                              final downloadService = ref.read(downloadServiceProvider);
                              await downloadService.downloadAndCache(song);
                              // Atualiza a lista na UI após o download.
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
                    // Inicia a reprodução da música selecionada.
                    final audioService = ref.read(audioServiceProvider);
                    final authService = ref.read(authServiceProvider);
                    
                    // Obtém o token atual para streaming autenticado.
                    final token = await authService.getAccessToken();
                    
                    await audioService.playSong(song, accessToken: token);
                  },
                );
              },
            );
          },
          // Indicador de progresso enquanto a lista é carregada do Drive.
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
          // Exibição amigável de erros de rede ou permissão.
          error: (err, stack) => Center(child: Text('Erro: $err')),
        ),
      ),
      // Player flutuante na parte inferior se houver música carregada.
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}
