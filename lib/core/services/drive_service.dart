import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';
import '../models/media_item.dart';
import 'package:http/http.dart' as http;

/// Provedor para o [DriveService], que só é instanciado se o usuário estiver logado.
final driveServiceProvider = Provider<DriveService?>((ref) {
  final account = ref.watch(authStateProvider);
  if (account == null) return null;
  return DriveService(account);
});

/// Serviço de integração direta com a API do Google Drive v3.
/// Responsável por gerenciar as pastas do app, listar músicas e realizar downloads.
class DriveService {
  final GoogleSignInAccount account;
  drive.DriveApi? _driveApi;
  Future<void>? _initFuture;

  DriveService(this.account) {
    _initFuture = _initApi();
  }

  /// Inicializa o cliente da API do Drive utilizando os cabeçalhos de autenticação do Google Sign-In.
  Future<void> _initApi() async {
    final authHeaders = await account.authHeaders;
    final client = GoogleAuthClient(authHeaders);
    _driveApi = drive.DriveApi(client);
  }
  
  /// Aguarda a inicialização terminar.
  Future<void> _ensureInitialized() async {
    if (_initFuture != null) {
      await _initFuture;
    }
  }

  /// Busca pela pasta de sistema 'OnSound' no Drive do usuário. 
  /// Se não existir, a pasta é criada automaticamente.
  Future<String?> getOrCreateOnSoundFolder() async {
    try {
      await _ensureInitialized();
      if (_driveApi == null) return null;

      // Procura por uma pasta chamada 'OnSound' que não esteja na lixeira.
      final list = await _driveApi!.files.list(
        q: "name = 'OnSound' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        spaces: 'drive',
      );

      if (list.files != null && list.files!.isNotEmpty) {
        return list.files!.first.id; // Retorna ID da pasta existente
      }

      // Cria a pasta caso a busca retorne vazia.
      final folder = drive.File()
        ..name = 'OnSound'
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      print('Erro ao buscar/criar pasta OnSound: $e');
      return null;
    }
  }

  /// Lista todos os arquivos (supostamente músicas) contidos dentro da pasta OnSound.
  Future<List<drive.File>> listMusicFiles(String folderId) async {
    await _ensureInitialized();
    try {
      final list = await _driveApi!.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        $fields: 'files(id, name, mimeType, size, webContentLink, appProperties)',
      );

      return list.files ?? [];
    } catch (e) {
      print('Erro ao listar arquivos: $e');
      return [];
    }
  }

  /// Realiza o download de um arquivo do Drive.
  Future<List<int>> downloadFile(String fileId) async {
    await _ensureInitialized();
    final response = await _driveApi!.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> data = [];
    await for (final chunk in response.stream) {
      data.addAll(chunk);
    }
    return data;
  }

  /// Upload direto de um Stream de áudio para a pasta OnSound no Drive.
  /// Salva a URL da thumbnail nos metadados do arquivo (appProperties).
  Future<void> uploadMediaStream({
    required String name,
    required Stream<List<int>> stream,
    required String thumbnailUrl,
    required MediaSourceType source,
  }) async {
    await _ensureInitialized();
    final folderId = await getOrCreateOnSoundFolder();
    if (folderId == null) throw Exception('Não foi possível encontrar a pasta OnSound');

    // Metadados do arquivo.
    final file = drive.File();
    file.name = name;
    file.parents = [folderId];
    
    // Armazena a URL da capa e a fonte nos appProperties do Google Drive.
    // Assim o app sabe qual imagem mostrar sem precisar baixar nada extra.
    file.appProperties = {
      'thumbnailUrl': thumbnailUrl,
      'source': source.name,
      'isOnSound': 'true', // Flag para identificação rápida
    };

    final media = drive.Media(stream, null); // Stream sem tamanho fixo (chunked).

    await _driveApi!.files.create(
      file,
      uploadMedia: media,
    );
  }
}

/// Um cliente HTTP personalizado que injeta os tokens de autenticação do Google em cada requisição.
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
