import 'package:flutter/foundation.dart';
import 'package:glpi_flutter_app/services/glpi_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 ADICIONE esta dependência

class AuthProvider extends ChangeNotifier {
  final GLPIService _service;

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _sessionToken;
  String? get sessionToken => _sessionToken;

  String? _userToken; // 👈 NOVO: Guarda o userToken para re-autenticação
  String? get userToken => _userToken;

  String? _message;
  String? get message => _message;

  String? _userName; // 👈 NOVO: Nome do usuário logado
  String? get userName => _userName;

  AuthProvider(this._service) {
    _loadStoredCredentials(); // 👈 NOVO: Tenta carregar sessão salva
  }

  /// 👇 NOVO: Carrega credenciais salvas (se existirem)
  Future<void> _loadStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserToken = prefs.getString('user_token');
      final storedUserName = prefs.getString('user_name');

      if (storedUserToken != null && storedUserToken.isNotEmpty) {
        _userToken = storedUserToken;
        _userName = storedUserName;

        // Tenta re-autenticar automaticamente
        await _silentAuthenticate();
      }
    } catch (e) {
      debugPrint('Erro ao carregar credenciais: $e');
    }
  }

  /// 👇 NOVO: Autenticação silenciosa (sem mostrar loading)
  Future<void> _silentAuthenticate() async {
    if (_userToken == null) return;

    try {
      final token = await _service.initSessionWithUserToken(_userToken!);
      _sessionToken = token;
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      // Falhou silenciosamente - usuário precisará fazer login novamente
      debugPrint('Falha na autenticação silenciosa: $e');
      _isAuthenticated = false;
      _sessionToken = null;
    }
  }

  Future<void> authenticate({
    required String userToken,
    String? userName,
    bool rememberMe = true,
  }) async {
    _isAuthenticating = true;
    _message = null;
    notifyListeners();

    try {
      final token = await _service.initSessionWithUserToken(userToken);
      _sessionToken = token;
      _userToken = userToken;
      _userName = userName;
      _isAuthenticated = true;
      _message = 'Sessão autenticada com sucesso.';

      if (rememberMe) {
        await _saveCredentials(userToken, userName);
      }
    } catch (e) {
      _isAuthenticated = false;
      _sessionToken = null;
      _userToken = null;
      _userName = null;
      _message = 'Erro de autenticação: ${e.toString()}';
      rethrow;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// 👇 NOVO: Salva credenciais localmente
  Future<void> _saveCredentials(String userToken, String? userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', userToken);
      if (userName != null) {
        await prefs.setString('user_name', userName);
      }
    } catch (e) {
      debugPrint('Erro ao salvar credenciais: $e');
    }
  }

  /// 👇 NOVO: Remove credenciais salvas
  Future<void> _clearStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_token');
      await prefs.remove('user_name');
    } catch (e) {
      debugPrint('Erro ao limpar credenciais: $e');
    }
  }

  Future<void> signOut() async {
  try {
    if (_sessionToken != null) {
      await _service.killSession(sessionToken: _sessionToken!);
    }
  } catch (e) {
    debugPrint('Aviso: falha ao encerrar sessão no GLPI: $e');
  }

  _isAuthenticated = false;
  _sessionToken = null;
  _userToken = null;
  _userName = null;
  _message = 'Sessão finalizada.';

  await _clearStoredCredentials();
  notifyListeners();
}


  /// 👇 NOVO: Verifica se a sessão ainda é válida
  Future<bool> validateSession() async {
  if (!_isAuthenticated || _sessionToken == null) return false;

  try {
    await _service.getFullSession(sessionToken: _sessionToken!);
    return true;
  } catch (e) {
    debugPrint('Sessão inválida: $e');
    _isAuthenticated = false;
    _sessionToken = null;
    notifyListeners();
    return false;
  }
}


  /// 👇 NOVO: Reautentica se a sessão expirou
  Future<void> reauthenticateIfNeeded() async {
    if (_isAuthenticated && _sessionToken != null) {
      final isValid = await validateSession();
      if (!isValid && _userToken != null) {
        await _silentAuthenticate();
      }
    }
  }

  /// 👇 NOVO: Limpa apenas a mensagem de erro
  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose(); // 👈 Importante: libera recursos do HTTP client
    super.dispose();
  }
}
