import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provedor para o serviço de autenticação central.
final authServiceProvider = Provider((ref) => AuthService(ref));

/// Provedor que indica se o app está verificando o login automático.
final authLoadingProvider = StateProvider<bool>((ref) => true);

/// Provedor que monitora o estado do usuário logado através do Riverpod.
final authStateProvider = StateProvider<GoogleSignInAccount?>((ref) => null);

/// Origem permitida para autenticação Web (deve bater com Google Cloud OAuth).
/// Pode ser sobrescrita com:
/// --dart-define=ONSOUND_ALLOWED_WEB_ORIGIN=http://localhost:3000
const allowedWebAuthOrigin = String.fromEnvironment(
  'ONSOUND_ALLOWED_WEB_ORIGIN',
  defaultValue: 'http://localhost:5000',
);

/// Provedor para o texto de bloqueio de origem no Web.
final authWebOriginErrorProvider = Provider<String?>((ref) {
  if (!kIsWeb) return null;
  final currentOrigin = Uri.base.origin;
  if (currentOrigin == allowedWebAuthOrigin) return null;
  return 'Auth bloqueada nesta URL ($currentOrigin). Use $allowedWebAuthOrigin.';
});

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

    // Em Web, evita tentativa de auth fora da origem autorizada.
    if (kIsWeb && Uri.base.origin != allowedWebAuthOrigin) {
      _ref.read(authLoadingProvider.notifier).state = false;
      return;
    }

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
    if (kIsWeb && Uri.base.origin != allowedWebAuthOrigin) {
      debugPrint(
        'Auth bloqueada: origem atual ${Uri.base.origin} != $allowedWebAuthOrigin',
      );
      return null;
    }

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
