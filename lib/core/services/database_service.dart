import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/song.dart';

/// Provedor para o serviço de banco de dados local.
final databaseServiceProvider = Provider((ref) => DatabaseService());

/// Serviço responsável pela persistência de dados local no dispositivo.
/// Atualmente utiliza [SharedPreferences] para armazenar a lista de músicas e seus estados.
class DatabaseService {
  /// Chave utilizada para salvar a lista de músicas no armazenamento local.
  static const _songsKey = 'onsound_songs';

  /// Salva ou atualiza uma música na lista persistente.
  /// Se a música já existir (baseado no [driveId]), ela será atualizada.
  Future<void> saveSong(Song song) async {
    final songs = await getAllSongs();
    final index = songs.indexWhere((s) => s.driveId == song.driveId);
    
    if (index >= 0) {
      songs[index] = song; // Atualiza música existente
    } else {
      songs.add(song); // Adiciona nova música
    }
    
    await _saveSongsList(songs);
  }

  /// Recupera todas as músicas salvas no JSON local.
  Future<List<Song>> getAllSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_songsKey);
    
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => Song.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Busca uma música específica pelo seu ID do Google Drive.
  Future<Song?> getSongByDriveId(String driveId) async {
    final songs = await getAllSongs();
    try {
      return songs.firstWhere((s) => s.driveId == driveId);
    } catch (_) {
      return null;
    }
  }

  /// Retorna apenas a lista de músicas que estão marcadas como disponíveis offline.
  Future<List<Song>> getOfflineSongs() async {
    final songs = await getAllSongs();
    return songs.where((s) => s.isOffline).toList();
  }

  /// Serializa a lista de objetos [Song] e salva no SharedPreferences.
  Future<void> _saveSongsList(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(songs.map((s) => s.toJson()).toList());
    await prefs.setString(_songsKey, jsonString);
  }
}
