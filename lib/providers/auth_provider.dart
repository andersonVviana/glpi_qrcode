import 'package:flutter/foundation.dart';
import 'package:glpi_flutter_app/services/glpi_service.dart';

class AuthProvider extends ChangeNotifier {
  final GLPIService _service;

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _sessionToken;
  String? get sessionToken => _sessionToken;

  String? _message;
  String? get message => _message;

  AuthProvider(this._service);

  /// Autentica e guarda a sessão
  Future<void> authenticate({required String userToken}) async {
    _isAuthenticating = true;
    _message = null;
    notifyListeners();

    try {
      final token = await _service.initSessionWithUserToken(userToken);
      _sessionToken = token;
      _isAuthenticated = true;
      _message = 'Sessão autenticada com sucesso.';
    } catch (e) {
      _isAuthenticated = false;
      _sessionToken = null;
      _message = 'Erro de autenticação: ${e.toString()}';
      rethrow;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  void signOut() {
    _isAuthenticated = false;
    _sessionToken = null;
    _message = 'Sessão finalizada.';
    notifyListeners();
  }
}
