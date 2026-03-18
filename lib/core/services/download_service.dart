import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'drive_service.dart';
import 'database_service.dart';
import '../../models/song.dart';
import '../../features/settings/settings_screen.dart';

/// Provedor para o serviço de download e gerenciamento de cache.
final downloadServiceProvider = Provider((ref) {
  final driveService = ref.watch(driveServiceProvider);
  return DownloadService(driveService, ref);
});

/// Serviço responsável por baixar as músicas do Google Drive e gerenciar o cache local.
/// Também implementa a política de limpeza automática para respeitar o limite de espaço.
class DownloadService {
  final DriveService? _driveService;
  final Ref _ref;

  DownloadService(this._driveService, this._ref);

  /// Realiza o download de uma música e a salva no armazenamento local do dispositivo.
  Future<void> downloadAndCache(Song song) async {
    if (_driveService == null) return;

    // Bloqueia a funcionalidade de cache na Web, pois não há acesso direto ao sistema de arquivos.
    if (kIsWeb) {
      print('Download offline não disponível na Web. Use Windows ou Android.');
      return;
    }

    try {
      // 1. Verifica e limpa músicas antigas do cache se o limite de faixas for atingido.
      await _performAutoCleanup();

      // 2. Faz o download dos bytes da música via API do Drive.
      final data = await _driveService.downloadFile(song.driveId);

      // 3. Define e cria o diretório de cache se ele ainda não existir.
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/onsound_cache');
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      // 4. Grava o arquivo físico no disco.
      final file = File('${cacheDir.path}/${song.driveId}.m4a');
      await file.writeAsBytes(data);

      // 5. Atualiza o objeto da música e persiste no banco de dados local.
      final dbService = _ref.read(databaseServiceProvider);
      final updatedSong = song.copyWith(
        localPath: file.path,
        isOffline: true,
      );
      await dbService.saveSong(updatedSong);
    } catch (e) {
      print('Erro ao baixar/salvar música: $e');
    }
  }

  /// Implementa a limpeza automática baseada no limite configurado pelo usuário.
  /// Remove a música mais antiga do cache para dar lugar à nova.
  Future<void> _performAutoCleanup() async {
    final settings = _ref.read(settingsProvider);
    final limit = settings.trackLimit;

    final dbService = _ref.read(databaseServiceProvider);
    final offlineSongs = await dbService.getOfflineSongs();

    // Se o número de músicas offline atingir o limite, remove a primeira da lista (a mais antiga).
    if (offlineSongs.length >= limit) {
      final oldestSong = offlineSongs.first;
      await removeCache(oldestSong);
      print('Auto-Cleanup: Removida música antiga ${oldestSong.name}');
    }
  }

  /// Remove o arquivo físico de uma música do cache e atualiza o estado no banco de dados.
  Future<void> removeCache(Song song) async {
    if (kIsWeb) return;

    if (song.localPath != null) {
      final file = File(song.localPath!);
      if (await file.exists()) {
        await file.delete(); // Exclui arquivo físico
      }

      // Atualiza metadados para refletir que a música não está mais offline.
      final dbService = _ref.read(databaseServiceProvider);
      final updatedSong = song.copyWith(
        localPath: null,
        isOffline: false,
      );
      await dbService.saveSong(updatedSong);
    }
  }
}
