import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provedor para o serviço de autenticação central.
final authServiceProvider = Provider((ref) => AuthService(ref));

/// Provedor que indica se o app está verificando o login automático.
final authLoadingProvider = StateProvider<bool>((ref) => true);

/// Provedor que monitora o estado do usuário logado através do Riverpod.
final authStateProvider = StateProvider<GoogleSignInAccount?>((ref) => null);

/// Serviço responsável por gerenciar a autenticação com a conta Google.
/// Requisita permissões específicas para acessar arquivos no Google Drive.
class AuthService {
  final Ref _ref;

  /// Define o nível de permissão (Scope) necessário: acesso aos arquivos criados/abertos pelo app.
  static const _scopes = [
    drive.DriveApi.driveFileScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  AuthService(this._ref) {
    // Escuta mudanças de sessão globais (Ex: Login pelo botão oficial da Web)
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _ref.read(authStateProvider.notifier).state = account;
    });

    // Tenta restaurar automaticamente uma sessão anterior ao iniciar o app.
    _tryAutoLogin();
  }

  /// Tenta realizar o login silencioso caso o usuário já tenha se autenticado antes.
  Future<void> _tryAutoLogin() async {
    try {
      // Inicia a verificação silenciosa.
      final account = await _googleSignIn.signInSilently();
      _ref.read(authStateProvider.notifier).state = account;
    } catch (e) {
      // Falha silenciosa é esperada se o usuário nunca logou ou limpou o cache.
      _ref.read(authStateProvider.notifier).state = null;
    } finally {
      // Marca como concluído para que a UI possa parar o loading.
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  /// Inicia o fluxo de login interativo com a conta Google.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      // No Web, o signIn() pode falhar se não houver interação direta.
      final account = await _googleSignIn.signIn();
      _ref.read(authStateProvider.notifier).state = account;
      return account;
    } catch (e) {
      print('Erro ao fazer login: $e');
      // Tenta forçar o logout antes de tentar novamente se houver erro de estado.
      await _googleSignIn.signOut();
      return null;
    }
  }

  /// Finaliza a sessão do usuário e desconecta a conta Google do aplicativo.
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      _ref.read(authStateProvider.notifier).state = null;
    } catch (e) {
      print('Erro ao fazer logout: $e');
    }
  }

  /// Retorna o token de acesso para requisições autenticadas (como streaming).
  Future<String?> getAccessToken() async {
    final account = _googleSignIn.currentUser;
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.accessToken;
  }
}
