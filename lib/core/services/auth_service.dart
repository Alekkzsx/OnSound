import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para o serviço de autenticação
final authServiceProvider = Provider((ref) => AuthService(ref));

/// Provider para monitorar o estado do usuário logado
/// Começa como null (deslogado) e atualiza quando o login acontece
final authStateProvider = StateProvider<GoogleSignInAccount?>((ref) => null);

class AuthService {
  final Ref _ref;

  static const _scopes = [
    drive.DriveApi.driveFileScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  AuthService(this._ref) {
    // Tenta restaurar sessão anterior silenciosamente
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      final account = await _googleSignIn.signInSilently();
      _ref.read(authStateProvider.notifier).state = account;
    } catch (e) {
      // Sem sessão anterior, fica como null (deslogado)
      _ref.read(authStateProvider.notifier).state = null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      _ref.read(authStateProvider.notifier).state = account;
      return account;
    } catch (e) {
      print('Erro ao fazer login: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      _ref.read(authStateProvider.notifier).state = null;
    } catch (e) {
      print('Erro ao fazer logout: $e');
    }
  }
}
