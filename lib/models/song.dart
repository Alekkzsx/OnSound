/// Representa uma música dentro do ecossistema OnSound.
/// Esta classe centraliza as informações tanto do Google Drive quanto do cache local.
class Song {
  /// Identificador único do arquivo no Google Drive.
  final String driveId;

  /// Nome de exibição da música (geralmente o nome do arquivo).
  final String name;

  /// Nome do artista (opcional, extraído dos metadados no futuro).
  final String? artist;

  /// Nome do álbum (opcional).
  final String? album;

  /// Duração da música em segundos.
  final Duration? duration;

  /// URL da imagem de capa (se disponível).
  final String? thumbnailUrl; // Nova URL da capa vinda do Drive

  /// Caminho no sistema de arquivos local onde o arquivo está armazenado (se baixado).
  final String? localPath;

  /// Indica se a música está disponível para reprodução offline.
  final bool isOffline;

  const Song({
    required this.driveId,
    required this.name,
    this.artist,
    this.album,
    this.duration,
    this.thumbnailUrl,
    this.localPath,
    this.isOffline = false,
  });

  /// Converte o objeto para JSON para salvar no cache local.
  Map<String, dynamic> toJson() => {
    'driveId': driveId,
    'name': name,
    'artist': artist,
    'album': album,
    'duration': duration?.inSeconds,
    'thumbnailUrl': thumbnailUrl,
    'localPath': localPath,
    'isOffline': isOffline,
  };

  /// Cria um objeto [Song] a partir de um JSON carregado.
  factory Song.fromJson(Map<String, dynamic> json) => Song(
    driveId: json['driveId'],
    name: json['name'],
    artist: json['artist'],
    album: json['album'],
    duration: json['duration'] != null ? Duration(seconds: json['duration']) : null,
    thumbnailUrl: json['thumbnailUrl'],
    localPath: json['localPath'],
    isOffline: json['isOffline'] ?? false,
  );

  /// Cria uma cópia da música com campos alterados (Imutabilidade).
  Song copyWith({
    String? localPath,
    bool? isOffline,
  }) {
    return Song(
      driveId: driveId,
      name: name,
      artist: artist,
      album: album,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      localPath: localPath ?? this.localPath,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}
