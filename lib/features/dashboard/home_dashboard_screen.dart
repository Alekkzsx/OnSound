import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/audio_service.dart';
import '../../core/services/auth_service.dart';
import '../library/library_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final tracks = ref.watch(musicListProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1C1C), Color(0xFF0A0A0A), Color(0xFF0A0A0A)],
          stops: [0.0, 0.28, 1.0],
        ),
      ),
      child: SafeArea(
        child: tracks.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1ED760))),
          error: (err, _) => Center(child: Text('Erro ao carregar dashboard: $err')),
          data: (songs) {
            final recent = songs.take(8).toList();
            final quickPick = songs.take(4).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ProfileBubble(photoUrl: user?.photoUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Boa sessao', style: TextStyle(color: Color(0xFFB3B3B3))),
                                  Text(
                                    user?.displayName ?? 'OnSound User',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref.invalidate(musicListProvider),
                              icon: const Icon(Icons.refresh, color: Colors.white70),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 260.ms)
                            .slideY(begin: -0.08, end: 0),
                        const SizedBox(height: 20),
                        const Text('Atalhos do dia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        _QuickGrid(songs: quickPick)
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 260.ms)
                            .slideY(begin: 0.08, end: 0),
                        const SizedBox(height: 24),
                        const Text('Tocados recentemente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 192,
                    child: recent.isEmpty
                        ? const Center(
                            child: Text('Sua biblioteca ainda esta vazia. Use a busca para adicionar musicas.'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            scrollDirection: Axis.horizontal,
                            itemCount: recent.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final song = recent[index];
                              return GestureDetector(
                                onTap: () async {
                                  final token = await ref.read(authServiceProvider).getAccessToken();
                                  await ref.read(audioServiceProvider).playSong(song, accessToken: token);
                                },
                                child: _CoverCard(song: song),
                              );
                            },
                          ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
                  sliver: SliverList.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _TrackRow(song: song, index: index);
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

class _QuickGrid extends StatelessWidget {
  final List<dynamic> songs;

  const _QuickGrid({required this.songs});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF171717),
        ),
        child: const Text('Nenhuma musica ainda. Abra Buscar para montar sua colecao.'),
      );
    }

    return GridView.builder(
      itemCount: songs.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final song = songs[index];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: song.thumbnailUrl != null && song.thumbnailUrl.toString().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.thumbnailUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox(width: 56, child: Icon(Icons.music_note)),
                      )
                    : const SizedBox(width: 56, child: Icon(Icons.music_note)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  song.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

class _CoverCard extends StatelessWidget {
  final dynamic song;

  const _CoverCard({required this.song});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 144,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: song.thumbnailUrl != null && song.thumbnailUrl.toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: song.thumbnailUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF171717),
                        child: const Center(child: Icon(Icons.album_outlined, size: 34)),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF171717),
                      child: const Center(child: Icon(Icons.album_outlined, size: 34)),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            song.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends ConsumerWidget {
  final dynamic song;
  final int index;

  const _TrackRow({required this.song, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: SizedBox(
        width: 30,
        child: Center(child: Text('${index + 1}', style: const TextStyle(color: Color(0xFFB3B3B3)))),
      ),
      title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.isOffline ? 'Offline' : 'Streaming', style: const TextStyle(color: Color(0xFFB3B3B3))),
      trailing: const Icon(Icons.play_circle_fill, color: Color(0xFF1ED760)),
      onTap: () async {
        final token = await ref.read(authServiceProvider).getAccessToken();
        await ref.read(audioServiceProvider).playSong(song, accessToken: token);
      },
    );
  }
}

class _ProfileBubble extends StatelessWidget {
  final String? photoUrl;

  const _ProfileBubble({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null) {
      return const CircleAvatar(
        radius: 21,
        backgroundColor: Color(0xFF262626),
        child: Icon(Icons.person, color: Colors.white70),
      );
    }

    return CircleAvatar(
      radius: 21,
      backgroundColor: const Color(0xFF262626),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const Icon(Icons.person, color: Colors.white70),
        ),
      ),
    );
  }
}
