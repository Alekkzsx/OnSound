import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;

/// Provider para o serviço do Google Drive
final driveServiceProvider = Provider<DriveService?>((ref) {
  final account = ref.watch(authStateProvider);
  
  if (account == null) return null;
  return DriveService(account);
});

class DriveService {
  final GoogleSignInAccount account;
  late final drive.DriveApi _driveApi;

  DriveService(this.account) {
    _initApi();
  }

  Future<void> _initApi() async {
    final authHeaders = await account.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    _driveApi = drive.DriveApi(client);
  }

  /// Busca ou cria a pasta 'OnSound' no Google Drive
  Future<String?> getOrCreateOnSoundFolder() async {
    try {
      final list = await _driveApi.files.list(
        q: "name = 'OnSound' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
      );

      if (list.files != null && list.files!.isNotEmpty) {
        return list.files!.first.id;
      }

      final folder = drive.File()
        ..name = 'OnSound'
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('Erro ao buscar/criar pasta OnSound: $e');
      return null;
    }
  }

  /// Lista arquivos de música dentro da pasta OnSound
  Future<List<drive.File>> listMusicFiles(String folderId) async {
    try {
      final list = await _driveApi.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, size, webContentLink)',
      );

      return list.files ?? [];
    } catch (e) {
      print('Erro ao listar arquivos: $e');
      return [];
    }
  }

  /// Faz o download de um arquivo do Drive
  Future<List<int>?> downloadFile(String fileId) async {
    try {
      final response = await _driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> data = [];
      await for (final chunk in response.stream) {
        data.addAll(chunk);
      }
      return data;
    } catch (e) {
      print('Erro ao baixar arquivo: $e');
      return null;
    }
  }
}

/// Cliente HTTP para lidar com os headers de autenticação do Google
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
