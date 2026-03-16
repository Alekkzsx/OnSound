import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/song.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());

class DatabaseService {
  static const _songsKey = 'onsound_songs';

  Future<void> saveSong(Song song) async {
    final songs = await getAllSongs();
    final index = songs.indexWhere((s) => s.driveId == song.driveId);
    if (index >= 0) {
      songs[index] = song;
    } else {
      songs.add(song);
    }
    await _saveSongsList(songs);
  }

  Future<List<Song>> getAllSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_songsKey);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((j) => Song.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Song?> getSongByDriveId(String driveId) async {
    final songs = await getAllSongs();
    try {
      return songs.firstWhere((s) => s.driveId == driveId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Song>> getOfflineSongs() async {
    final songs = await getAllSongs();
    return songs.where((s) => s.isOffline).toList();
  }

  Future<void> _saveSongsList(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(songs.map((s) => s.toJson()).toList());
    await prefs.setString(_songsKey, jsonString);
  }
}
