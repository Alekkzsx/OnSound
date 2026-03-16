class Song {
  final String driveId;
  final String name;
  final String? artist;
  final String? album;
  final int? durationInSeconds;
  final String? coverUrl;
  String? localPath;
  bool isOffline;

  Song({
    required this.driveId,
    required this.name,
    this.artist,
    this.album,
    this.durationInSeconds,
    this.coverUrl,
    this.localPath,
    this.isOffline = false,
  });

  Map<String, dynamic> toJson() => {
    'driveId': driveId,
    'name': name,
    'artist': artist,
    'album': album,
    'durationInSeconds': durationInSeconds,
    'coverUrl': coverUrl,
    'localPath': localPath,
    'isOffline': isOffline,
  };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    driveId: json['driveId'] as String,
    name: json['name'] as String,
    artist: json['artist'] as String?,
    album: json['album'] as String?,
    durationInSeconds: json['durationInSeconds'] as int?,
    coverUrl: json['coverUrl'] as String?,
    localPath: json['localPath'] as String?,
    isOffline: json['isOffline'] as bool? ?? false,
  );
}
