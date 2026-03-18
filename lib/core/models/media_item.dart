import 'package:flutter/foundation.dart';

/// Define a origem da mídia para sabermos se veio do YouTube ou SoundCloud.
enum MediaSourceType { youtube, soundcloud }

/// Modelo unificado que representa um resultado de busca de qualquer plataforma.
@immutable
class MediaItem {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration? duration;
  final MediaSourceType source;
  
  /// Link original para referência ou extração posterior.
  final String originalUrl;

  const MediaItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.duration,
    required this.source,
    required this.originalUrl,
  });

  /// Converte para um mapa para depuração ou armazenamento simples.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration?.inSeconds,
      'source': source.name,
      'originalUrl': originalUrl,
    };
  }
}
