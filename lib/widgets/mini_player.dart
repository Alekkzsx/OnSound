import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../core/services/audio_service.dart';
import '../models/song.dart';

/// Um widget de player compacto que permanece visível na parte inferior da tela.
/// Ele exibe o estado atual da reprodução e permite controles básicos (play/pause/stop).
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Acessa o serviço de áudio através do Riverpod
    final audioService = ref.watch(audioServiceProvider);

    // Escuta as atualizações de estado do player (tocando, carregando, pausado, etc.)
    return StreamBuilder<PlayerState>(
      stream: audioService.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;

        // Se o player estiver ocioso (sem música carregada), não exibe nada
        if (processingState == ProcessingState.idle || processingState == null) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<Song?>(
          stream: audioService.currentSongStream,
          builder: (context, songSnapshot) {
            final song = songSnapshot.data;

            return Container(
              height: 70,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF282828), // Fundo cinza escuro no estilo Spotify
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Capa da música ou ícone padrão
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: song?.thumbnailUrl != null
                          ? Image.network(
                              song!.thumbnailUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.music_note, color: Color(0xFF1DB954)),
                    ),
                  ),
                  // Informações dinâmicas da música
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song?.name ?? 'Carregando...',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song?.artist ?? 'OnSound Player',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Botão Play/Pause dinâmico baseado no estado atual
                  IconButton(
                    icon: Icon(
                      playing == true ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (playing == true) {
                        audioService.pause();
                      } else {
                        audioService.resume();
                      }
                    },
                  ),
                  // Botão para parar a reprodução e limpar o player
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.white60),
                    onPressed: () => audioService.stop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
