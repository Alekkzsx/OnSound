import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drive_service.dart';
import 'database_service.dart';
import '../../models/song.dart';
import '../../features/settings/settings_screen.dart';

final downloadServiceProvider = Provider((ref) {
  final driveService = ref.watch(driveServiceProvider);
  return DownloadService(driveService, ref);
});

class DownloadService {
  final DriveService? _driveService;
  final Ref _ref;

  DownloadService(this._driveService, this._ref);

  Future<void> downloadAndCache(Song song) async {
    if (_driveService == null) return;

    // Na Web, não conseguimos salvar arquivos locais
    if (kIsWeb) {
      print('Download offline não disponível na Web. Use Windows ou Android.');
      return;
    }

    try {
      // 1. Verifica e limpa cache se necessário antes de baixar
      await _performAutoCleanup();

      // 2. Procede com o download
      final data = await _driveService!.downloadFile(song.driveId);
      if (data == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/onsound_cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final file = File('${cacheDir.path}/${song.driveId}.m4a');
      await file.writeAsBytes(data);

      final dbService = _ref.read(databaseServiceProvider);
      song.localPath = file.path;
      song.isOffline = true;
      await dbService.saveSong(song);
    } catch (e) {
      print('Erro ao baixar/salvar música: $e');
    }
  }

  Future<void> _performAutoCleanup() async {
    final settings = _ref.read(settingsProvider);
    final limit = settings.trackLimit;

    final dbService = _ref.read(databaseServiceProvider);
    final offlineSongs = await dbService.getOfflineSongs();

    if (offlineSongs.length >= limit) {
      final oldestSong = offlineSongs.first;
      await removeCache(oldestSong);
      print('Auto-Cleanup: Removida música antiga ${oldestSong.name}');
    }
  }

  Future<void> removeCache(Song song) async {
    if (kIsWeb) return;

    if (song.localPath != null) {
      final file = File(song.localPath!);
      if (await file.exists()) {
        await file.delete();
      }

      final dbService = _ref.read(databaseServiceProvider);
      song.localPath = null;
      song.isOffline = false;
      await dbService.saveSong(song);
    }
  }
}
