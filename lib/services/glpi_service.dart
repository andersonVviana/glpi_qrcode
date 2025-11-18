import 'dart:convert';
import 'package:glpi_flutter_app/models/glpi_document.dart';
import 'package:glpi_flutter_app/services/http_client_service.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/glpi_config.dart';
import '../models/inventory_item.dart';

class GLPIService {
  final String baseUrl;
  final String appToken;
  late http.Client _client;

  GLPIService({String? baseUrl, String? appToken})
    : baseUrl = baseUrl ?? GLPIConfig.baseUrl,
      appToken = appToken ?? GLPIConfig.appToken {
    _client = CustomHttpClient.getClient(); // 👈 ADICIONE ESTA LINHA
  }

  Future<String> initSessionWithUserToken(String userToken) async {
    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    final uriHeaders = Uri.parse('$base/initSession');
    final uriQuery = Uri.parse('$base/initSession?user_token=$userToken');

    // Tentativa A: headers (modo “correto”)
    {
      final headers = {
        'App-Token': appToken,
        'Authorization': 'user_token $userToken',
        'Accept': 'application/json',
      };
      final resp = await _client.post(uriHeaders, headers: headers);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return _extractSessionToken(resp.body);
      }
      // Se foi erro “parâmetros faltando”, tentamos os fallbacks
      final body = resp.body;
      final isMissing = body.contains('ERROR_LOGIN_PARAMETERS_MISSING');
      if (!isMissing) {
        // Outro erro real do GLPI
        throw Exception('Falha ao iniciar sessão (${resp.statusCode}): $body');
      }
    }

    // Tentativa B: query string (?user_token=...)
    {
      final headers = {'App-Token': appToken, 'Accept': 'application/json'};
      final resp = await _client.post(uriQuery, headers: headers);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return _extractSessionToken(resp.body);
      }
      final body = resp.body;
      final isMissing = body.contains('ERROR_LOGIN_PARAMETERS_MISSING');
      if (!isMissing) {
        throw Exception(
          'Falha ao iniciar sessão (query) (${resp.statusCode}): $body',
        );
      }
    }

    // Tentativa C: form-urlencoded (algumas instalações aceitam só isso)
    {
      final headers = {
        'App-Token': appToken,
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      final resp = await _client.post(
        uriHeaders,
        headers: headers,
        body: 'user_token=$userToken',
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return _extractSessionToken(resp.body);
      }
      throw Exception(
        'Falha ao iniciar sessão (form) (${resp.statusCode}): ${resp.body}',
      );
    }
  }

  String _extractSessionToken(String responseBody) {
    final data = json.decode(responseBody) as Map<String, dynamic>;
    print('✅ Dados recebidos: $data');

    final sessionToken =
        data['session_token'] ?? data['sessionToken'] ?? data['Session-Token'];

    if (sessionToken is String && sessionToken.isNotEmpty) {
      print('✅ Session Token obtido: ${sessionToken.substring(0, 10)}...');
      return sessionToken;
    }
    throw Exception(
      'Não foi possível obter o Session-Token da resposta: $data',
    );
  }

  Map<String, String> _authHeaders(String sessionToken) => {
    'Session-Token': sessionToken,
    'App-Token': appToken,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ======================= Lookups com cache =======================
  final Map<int, String> _manufacturerCache = {};
  final Map<int, String> _userCache = {};
  final Map<int, String> _locationCache = {};
  final Map<int, String> _computerModelCache = {};
  final Map<int, String> _phoneModelCache = {};
  final Map<int, String> _printerModelCache = {};
  final Map<int, String> _osCache = {};
  final Map<int, String> _osVersionCache = {};

  Future<String> _getNameById(
    String endpoint,
    int? id,
    String sessionToken, {
    String fallback = '',
    String nameKey = 'name',
  }) async {
    if (id == null || id == 0) return fallback;
    final uri = Uri.parse('$baseUrl$endpoint/$id');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(resp.body);
      return (data[nameKey] ?? data['completename'] ?? data['name'] ?? fallback)
          .toString();
    }
    return fallback;
  }

  Future<String> _getManufacturerName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_manufacturerCache.containsKey(id)) return _manufacturerCache[id]!;
    final name = await _getNameById('/Manufacturer', id, sessionToken);
    _manufacturerCache[id] = name;
    return name;
  }

  Future<String> _getUserName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_userCache.containsKey(id)) return _userCache[id]!;
    final name = await _getNameById('/User', id, sessionToken);
    _userCache[id] = name;
    return name;
  }

  Future<Map<String, dynamic>> getFullSession({
    required String sessionToken,
  }) async {
    final uri = Uri.parse('$baseUrl/getFullSession');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('getFullSession falhou: ${resp.statusCode} ${resp.body}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  Future<void> killSession({required String sessionToken}) async {
    final uri = Uri.parse('$baseUrl/killSession');
    final resp = await _client.post(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      // Algumas instâncias aceitam GET; fallback:
      final alt = await _client.get(uri, headers: _authHeaders(sessionToken));
      if (alt.statusCode != 200) {
        throw Exception('killSession falhou: ${resp.statusCode} ${resp.body}');
      }
    }
  }

  Future<String> _getLocationName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_locationCache.containsKey(id)) return _locationCache[id]!;
    final name = await _getNameById(
      '/Location',
      id,
      sessionToken,
      nameKey: 'completename',
    );
    _locationCache[id] = name;
    return name;
  }

  // ✅ Troque estes três métodos pelos abaixo

  Future<String> _getComputerModelName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_computerModelCache.containsKey(id)) return _computerModelCache[id]!;
    // GLPI 10: endpoint correto é /ComputerModel
    final name = await _getNameById('/ComputerModel', id, sessionToken);
    _computerModelCache[id] = name;
    return name;
  }

  Future<String> _getPhoneModelName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_phoneModelCache.containsKey(id)) return _phoneModelCache[id]!;
    // GLPI 10: endpoint correto é /PhoneModel
    final name = await _getNameById('/PhoneModel', id, sessionToken);
    _phoneModelCache[id] = name;
    return name;
  }

  Future<String> _getPrinterModelName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_printerModelCache.containsKey(id)) return _printerModelCache[id]!;
    // GLPI 10: endpoint correto é /PrinterModel
    final name = await _getNameById('/PrinterModel', id, sessionToken);
    _printerModelCache[id] = name;
    return name;
  }

  Future<List<dynamic>> _getAll(
    String endpoint,
    String sessionToken, {
    int pageSize = 200,
    int maxPages = 100,
  }) async {
    final List<dynamic> all = [];
    final Set<int> seenIds = {};
    int start = 0;

    for (int page = 1; page <= maxPages; page++) {
      final hasQuery = endpoint.contains('?');
      final sep = hasQuery ? '&' : '?';
      final uri = Uri.parse(
        '$baseUrl$endpoint${sep}range=$start-${start + pageSize - 1}',
      );

      final resp = await _client.get(uri, headers: _authHeaders(sessionToken));

      if (resp.statusCode != 200 && resp.statusCode != 206) {
        throw Exception('Erro ao buscar $endpoint (${resp.statusCode})');
      }

      final pageData = json.decode(resp.body);
      if (pageData is! List) break;

      int appended = 0;
      for (final e in pageData) {
        final id = (e is Map && e['id'] != null)
            ? (e['id'] is int
                  ? e['id'] as int
                  : int.tryParse(e['id'].toString()) ?? -1)
            : -1;
        if (id >= 0 && seenIds.add(id)) {
          all.add(e);
          appended++;
        }
      }

      if (pageData.isEmpty || appended == 0) break;

      start += pageData.length;
    }

    return all;
  }

  // ======================= LISTAGENS =======================
  Future<List<InventoryItem>> listComputers({
    required String sessionToken,
    String? search,
  }) async {
    print('🔍 Buscando computadores...');
    final data = await _getAll('/Computer', sessionToken);
    print('✅ Total de computadores encontrados: ${data.length}');

    final List<InventoryItem> items = [];
    for (final raw in data) {
      final mId = _asInt(raw['manufacturers_id']);
      final uId = _asInt(raw['users_id']);
      final lId = _asInt(raw['locations_id']);
      final modelId = _asInt(raw['computermodels_id']);
      final hostname = (raw['name'] ?? '').toString();
      final serial = (raw['serial'] ?? raw['otherserial'] ?? '').toString();

      if (_matchesSearch(hostname, serial, search)) {
        items.add(
          InventoryItem(
            type: 'Computer',
            id: _asInt(raw['id']) ?? 0,
            hostname: hostname,
            status: (raw['states_id'] ?? raw['status'] ?? '').toString(),
            manufacturer: await _getManufacturerName(mId, sessionToken),
            model: await _getComputerModelName(modelId, sessionToken),
            serial: serial,
            userName: await _getUserName(uId, sessionToken),
            location: await _getLocationName(lId, sessionToken),
          ),
        );
      }
    }
    print('✅ Computadores após filtro: ${items.length}');
    return items;
  }

  Future<List<InventoryItem>> listPhones({
    required String sessionToken,
    String? search,
  }) async {
    print('🔍 Buscando telefones...');
    final data = await _getAll('/Phone', sessionToken);
    print('✅ Total de telefones encontrados: ${data.length}');

    final List<InventoryItem> items = [];
    for (final raw in data) {
      final mId = _asInt(raw['manufacturers_id']);
      final uId = _asInt(raw['users_id']);
      final lId = _asInt(raw['locations_id']);
      final modelId = _asInt(raw['phonemodels_id']);
      final hostname = (raw['name'] ?? '').toString();
      final serial = (raw['serial'] ?? raw['otherserial'] ?? '').toString();

      if (_matchesSearch(hostname, serial, search)) {
        items.add(
          InventoryItem(
            type: 'Phone',
            id: _asInt(raw['id']) ?? 0,
            hostname: hostname,
            status: (raw['states_id'] ?? raw['status'] ?? '').toString(),
            manufacturer: await _getManufacturerName(mId, sessionToken),
            model: await _getPhoneModelName(modelId, sessionToken),
            serial: serial,
            userName: await _getUserName(uId, sessionToken),
            location: await _getLocationName(lId, sessionToken),
          ),
        );
      }
    }
    print('✅ Telefones após filtro: ${items.length}');
    return items;
  }

  Future<List<InventoryItem>> listPrinters({
    required String sessionToken,
    String? search,
  }) async {
    print('🔍 Buscando impressoras...');
    final data = await _getAll('/Printer', sessionToken);
    print('✅ Total de impressoras encontradas: ${data.length}');

    final List<InventoryItem> items = [];
    for (final raw in data) {
      final mId = _asInt(raw['manufacturers_id']);
      final uId = _asInt(raw['users_id']);
      final lId = _asInt(raw['locations_id']);
      final modelId = _asInt(raw['printermodels_id']);
      final hostname = (raw['name'] ?? '').toString();
      final serial = (raw['serial'] ?? raw['otherserial'] ?? '').toString();

      if (_matchesSearch(hostname, serial, search)) {
        items.add(
          InventoryItem(
            type: 'Printer',
            id: _asInt(raw['id']) ?? 0,
            hostname: hostname,
            status: (raw['states_id'] ?? raw['status'] ?? '').toString(),
            manufacturer: await _getManufacturerName(mId, sessionToken),
            model: await _getPrinterModelName(modelId, sessionToken),
            serial: serial,
            userName: await _getUserName(uId, sessionToken),
            location: await _getLocationName(lId, sessionToken),
          ),
        );
      }
    }
    print('✅ Impressoras após filtro: ${items.length}');
    return items;
  }

  Future<Map<String, String>> getComputerDetails({
    required String sessionToken,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/Computer/$id');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar computador ($id): ${resp.statusCode}');
    }
    final Map<String, dynamic> raw = json.decode(resp.body);

    final mId = _asInt(raw['manufacturers_id']);
    final uId = _asInt(raw['users_id']);
    final lId = _asInt(raw['locations_id']);
    final modelId = _asInt(raw['computermodels_id']);

    final osText = await _composeOperatingSystemText(raw, sessionToken); // 👈

    return {
      'Tipo': 'Computador',
      'ID': '${raw['id'] ?? ''}',
      'Hostname': '${raw['name'] ?? ''}',
      'Status': '${raw['states_id'] ?? raw['status'] ?? ''}',
      'Fabricante': await _getManufacturerName(mId, sessionToken),
      'Modelo': await _getComputerModelName(modelId, sessionToken),
      'Serial': '${raw['serial'] ?? raw['otherserial'] ?? ''}',
      'Asset Tag': '${raw['otherserial'] ?? ''}',
      'Usuário': await _getUserName(uId, sessionToken),
      'Localização': await _getLocationName(lId, sessionToken),
      'UUID': '${raw['uuid'] ?? ''}',
      'Sistema Oper.': osText, // 👈 agora sempre tentamos preencher
      'Domínio': '${raw['domain'] ?? ''}',
      'Criado em': '${raw['date_creation'] ?? ''}',
      'Atualizado em': '${raw['date_mod'] ?? ''}',
    };
  }

  Future<Map<String, String>> getPhoneDetails({
    required String sessionToken,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/Phone/$id');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar telefone ($id): ${resp.statusCode}');
    }
    final Map<String, dynamic> raw = json.decode(resp.body);

    final mId = _asInt(raw['manufacturers_id']);
    final uId = _asInt(raw['users_id']);
    final lId = _asInt(raw['locations_id']);
    final modelId = _asInt(raw['phonemodels_id']);

    final osText = await _composeOperatingSystemText(raw, sessionToken); // 👈

    return {
      'Tipo': 'Telefone',
      'ID': '${raw['id'] ?? ''}',
      'Nome': '${raw['name'] ?? ''}',
      'Status': '${raw['states_id'] ?? raw['status'] ?? ''}',
      'Fabricante': await _getManufacturerName(mId, sessionToken),
      'Modelo': await _getPhoneModelName(modelId, sessionToken),
      'Serial': '${raw['serial'] ?? raw['otherserial'] ?? ''}',
      'IMEI': '${raw['imei'] ?? ''}',
      'Linha': '${raw['number'] ?? ''}',
      'Sistema Oper.': osText, // 👈 idem
      'Usuário': await _getUserName(uId, sessionToken),
      'Localização': await _getLocationName(lId, sessionToken),
      'Criado em': '${raw['date_creation'] ?? ''}',
      'Atualizado em': '${raw['date_mod'] ?? ''}',
    };
  }

  Future<Map<String, String>> getPrinterDetails({
    required String sessionToken,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/Printer/$id');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar impressora ($id): ${resp.statusCode}');
    }
    final Map<String, dynamic> raw = json.decode(resp.body);

    final mId = _asInt(raw['manufacturers_id']);
    final uId = _asInt(raw['users_id']);
    final lId = _asInt(raw['locations_id']);
    final modelId = _asInt(raw['printermodels_id']);

    return {
      'Tipo': 'Impressora',
      'ID': '${raw['id'] ?? ''}',
      'Nome': '${raw['name'] ?? ''}',
      'Status': '${raw['states_id'] ?? raw['status'] ?? ''}',
      'Fabricante': await _getManufacturerName(mId, sessionToken),
      'Modelo': await _getPrinterModelName(modelId, sessionToken),
      'Serial': '${raw['serial'] ?? raw['otherserial'] ?? ''}',
      'End. IP': '${raw['ip'] ?? ''}',
      'Usuário': await _getUserName(uId, sessionToken),
      'Localização': await _getLocationName(lId, sessionToken),
      'Criado em': '${raw['date_creation'] ?? ''}',
      'Atualizado em': '${raw['date_mod'] ?? ''}',
    };
  }

  // ======================= Helpers =======================
  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  bool _matchesSearch(String name, String serial, String? q) {
    if (q == null || q.trim().isEmpty) return true;
    final s = q.toLowerCase().trim();
    return name.toLowerCase().contains(s) || serial.toLowerCase().contains(s);
  }

  String _endpointForType(String type) {
    switch (type) {
      case 'Computer':
        return '/Computer';
      case 'Phone':
        return '/Phone';
      case 'Printer':
        return '/Printer';
      default:
        throw Exception('Tipo desconhecido: $type');
    }
  }

  Future<Map<String, dynamic>> _getItemRaw({
    required String type,
    required int id,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('$baseUrl${_endpointForType(type)}/$id');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar $type($id): ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  Future<void> _putItemComment({
    required String type,
    required int id,
    required String sessionToken,
    required String newComment,
  }) async {
    final uri = Uri.parse('$baseUrl${_endpointForType(type)}/$id');

    final body = json.encode({
      'input': {'id': id, 'comment': newComment},
    });

    final headers = _authHeaders(sessionToken);
    var resp = await _client.put(uri, headers: headers, body: body);

    if (resp.statusCode == 400 || resp.statusCode == 405) {
      resp = await _client.patch(uri, headers: headers, body: body);
    }

    if (resp.statusCode != 200) {
      String reason = 'status=${resp.statusCode}';
      try {
        final err = json.decode(resp.body);
        reason = '$reason body=${err.toString()}';
      } catch (_) {}
      throw Exception('Falha ao atualizar comentário de $type($id): $reason');
    }
  }

  String _buildInventoryBlock({
    required String userName,
    required int year,
    required DateTime whenSP,
    required bool updated,
  }) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final status = updated ? 'Inventariado (Atualizado)' : 'Inventariado';
    return '''
      [INVENTARIO-$year]
      Nome: $userName
      Data/Hora: ${fmt.format(whenSP)} (São Paulo)
      Status: $status
      [/INVENTARIO-$year]'''
        .trim();
  }

  final RegExp _blockRegexAnyYear = RegExp(
    r'\[INVENTARIO-(\d{4})\][\s\S]*?\[/INVENTARIO-\1\]',
  );

  String _upsertYearBlock(
    String comment,
    int year,
    String newBlock, {
    bool updateOnlyThisYear = true,
  }) {
    final specific = RegExp(
      r'\[INVENTARIO-' +
          year.toString() +
          r'\][\s\S]*?\[/INVENTARIO-' +
          year.toString() +
          r'\]',
    );
    if (specific.hasMatch(comment)) {
      return comment.replaceAll(specific, newBlock);
    } else {
      final trimmed = comment.trimRight();
      if (trimmed.isEmpty) return newBlock;
      return '$trimmed\n\n$newBlock';
    }
  }

  String _removeYearBlock(String comment, int year) {
    final specific = RegExp(
      r'\[INVENTARIO-' +
          year.toString() +
          r'\][\s\S]*?\[/INVENTARIO-' +
          year.toString() +
          r'\]',
    );
    return comment
        .replaceAll(specific, '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  DateTime _nowSaoPaulo() {
    return DateTime.now();
  }

  Future<String> createOrUpdateInventory({
    required String type,
    required int id,
    required String sessionToken,
    required String userName,
  }) async {
    final raw = await _getItemRaw(
      type: type,
      id: id,
      sessionToken: sessionToken,
    );
    final currentComment = (raw['comment'] ?? '').toString();
    final year = DateTime.now().year;
    final whenSP = _nowSaoPaulo();

    final existsCurrent = RegExp(
      r'\[INVENTARIO-' + year.toString() + r'\]',
    ).hasMatch(currentComment);
    final block = _buildInventoryBlock(
      userName: userName,
      year: year,
      whenSP: whenSP,
      updated: existsCurrent,
    );

    final newComment = _upsertYearBlock(currentComment, year, block);
    if (newComment == currentComment) {
      return existsCurrent ? 'Inventariado (Atualizado)' : 'Inventariado';
    }
    await _putItemComment(
      type: type,
      id: id,
      sessionToken: sessionToken,
      newComment: newComment,
    );
    return existsCurrent ? 'Inventariado (Atualizado)' : 'Inventariado';
  }

  Future<Map<String, String>?> getCurrentYearInventoryInfo({
    required String type,
    required int id,
    required String sessionToken,
  }) async {
    final raw = await _getItemRaw(
      type: type,
      id: id,
      sessionToken: sessionToken,
    );
    final comment = (raw['comment'] ?? '').toString();
    final year = DateTime.now().year;

    final specific = RegExp(
      r'\[INVENTARIO-' +
          year.toString() +
          r'\]([\s\S]*?)\[/INVENTARIO-' +
          year.toString() +
          r'\]',
    );
    final m = specific.firstMatch(comment);
    if (m == null) return null;

    final block = m.group(1)!;

    String _extract(String key) {
      final r = RegExp(
        r'^\s*' + RegExp.escape(key) + r':\s*(.*)$',
        multiLine: true,
      );
      final mm = r.firstMatch(block);
      return (mm?.group(1) ?? '').trim();
    }

    final nome = _extract('Nome');
    final dataHora = _extract('Data/Hora');

    return {'nome': nome, 'dataHora': dataHora, 'ano': '$year'};
  }

  Future<void> deleteCurrentYearInventory({
    required String type,
    required int id,
    required String sessionToken,
  }) async {
    final raw = await _getItemRaw(
      type: type,
      id: id,
      sessionToken: sessionToken,
    );
    final currentComment = (raw['comment'] ?? '').toString();
    final year = DateTime.now().year;
    final newComment = _removeYearBlock(currentComment, year);
    await _putItemComment(
      type: type,
      id: id,
      sessionToken: sessionToken,
      newComment: newComment,
    );
  }

  Future<String> _getOperatingSystemName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_osCache.containsKey(id)) return _osCache[id]!;
    final name = await _getNameById('/OperatingSystem', id, sessionToken);
    _osCache[id] = name;
    return name;
  }

  // Nome da Versão do SO
  Future<String> _getOperatingSystemVersionName(
    int? id,
    String sessionToken,
  ) async {
    if (id == null || id == 0) return '';
    if (_osVersionCache.containsKey(id)) return _osVersionCache[id]!;
    final name = await _getNameById(
      '/OperatingSystemVersion',
      id,
      sessionToken,
    );
    _osVersionCache[id] = name;
    return name;
  }

  Future<String> _composeOperatingSystemText(
    Map<String, dynamic> raw,
    String sessionToken,
  ) async {
    // 1) Preferir por IDs (algumas instâncias usam chaves ligeiramente diferentes)
    final osId = _asInt(
      raw['operatingsystems_id'] ?? raw['operatingsystem_id'],
    );
    final osvId = _asInt(
      raw['operatingsystemversions_id'] ?? raw['operatingsystemversion_id'],
    );

    final osName = await _getOperatingSystemName(osId, sessionToken);
    final osVer = await _getOperatingSystemVersionName(osvId, sessionToken);

    final fromIds = [
      osName,
      osVer,
    ].where((s) => s.trim().isNotEmpty).join(' ').trim();
    if (fromIds.isNotEmpty) return fromIds;

    // 2) Fallback por texto (varia conforme versão/configuração do GLPI)
    final textCandidates =
        [
              raw['operatingsystem_name'],
              raw['operatingsystem'],
              raw['os_name'],
              raw['os'],
            ]
            .map((e) => (e ?? '').toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();

    if (textCandidates.isNotEmpty) return textCandidates.first;

    return ''; // nada encontrado
  }

  Future<List<Map<String, dynamic>>> _listDocumentLinks({
    required String type, // 'Computer' | 'Phone' | 'Printer' ...
    required int id,
    required String sessionToken,
  }) async {
    // Construir endpoint com filtros corretos
    final endpoint = '/Document_Item';

    // Buscar todos os Document_Item com paginação
    final List<dynamic> allRows = await _getAll(
      endpoint,
      sessionToken,
      pageSize: 200,
      maxPages: 50,
    );

    // Filtrar apenas os que correspondem ao itemtype e items_id corretos
    final filtered = allRows.whereType<Map<String, dynamic>>().where((row) {
      final itemType = (row['itemtype'] ?? '').toString();
      final itemsId = _asInt(row['items_id']);

      // Debug: imprimir para verificar
      print(
        'Document_Item: itemtype=$itemType, items_id=$itemsId (buscando: type=$type, id=$id)',
      );

      return itemType == type && itemsId == id;
    }).toList();

    print('Total Document_Item encontrados: ${allRows.length}');
    print('Filtrados para $type($id): ${filtered.length}');

    return filtered;
  }

  // Busca um documento por id
  Future<Map<String, dynamic>> _getDocumentRaw({
    required int id,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('$baseUrl/Document/$id');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar Document($id): ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  // Lista todos os documentos relacionados ao item
  Future<List<GlpiDocument>> listDocumentsForItem({
    required String type, // 'Computer' | 'Phone' | 'Printer'
    required int id,
    required String sessionToken,
  }) async {
    final links = await _listDocumentLinks(
      type: type,
      id: id,
      sessionToken: sessionToken,
    );

    // Alguns GLPI usam 'documents_id', outros 'document_id'
    final ids = <int>{};
    for (final l in links) {
      final did = _asInt(l['documents_id'] ?? l['document_id']);
      if (did != null) ids.add(did);
    }

    final docs = <GlpiDocument>[];
    for (final did in ids) {
      final raw = await _getDocumentRaw(id: did, sessionToken: sessionToken);
      docs.add(GlpiDocument.fromJson(raw));
    }

    // Ordena por data de modificação desc, depois nome
    docs.sort((a, b) {
      final d = b.dateMod.compareTo(a.dateMod);
      return d != 0 ? d : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return docs;
  }

  Future<List<int>> downloadDocumentBytes({
    required int documentId,
    required String sessionToken,
  }) async {
    print('📥 Iniciando download do documento ID: $documentId');

    // Forma compatível com seu GLPI:
    // GET apirest.php/Document/{id}?alt=media
    final uri = Uri.parse('$baseUrl/Document/$documentId?alt=media');

    final headers = {
      'Session-Token': sessionToken,
      'App-Token': appToken,
      'Accept': 'application/octet-stream',
    };

    print('🔗 Fazendo GET em: $uri');

    final resp = await _client.get(uri, headers: headers);

    print(
      '↩️ status=${resp.statusCode} '
      'len=${resp.bodyBytes.length} '
      'content-type=${resp.headers['content-type']}',
    );

    if (resp.statusCode != 200) {
      // tenta decodificar como texto/JSON pra mostrar erro do GLPI
      String msg;
      try {
        msg = utf8.decode(resp.bodyBytes);
      } catch (_) {
        msg = 'Resposta binária com erro (não deu pra decodificar).';
      }
      throw Exception(
        'Falha ao baixar documento (status ${resp.statusCode}): $msg',
      );
    }

    final bytes = resp.bodyBytes;
    if (bytes.isEmpty) {
      throw Exception('Documento retornou vazio (0 bytes).');
    }

    // (Opcional) checar se parece PDF (%PDF)
    if (bytes.length > 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      print('✅ PDF válido recebido: ${bytes.length} bytes');
    } else {
      print(
        '⚠️ Arquivo não começa com %PDF (primeiros bytes: ${bytes.take(10).toList()})',
      );
    }

    return bytes;
  }

  Future<int> uploadDocument({
    required String sessionToken,
    required String documentName, // nome exibido no GLPI
    required String fileName, // nome do arquivo (ex: contrato.pdf)
    required List<int> fileBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/Document/');
    print('📤 Upload de documento para: $uri');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Session-Token': sessionToken,
      'App-Token': appToken,
      'Accept': 'application/json',
      // Content-Type multipart/form-data é setado automaticamente
    });

    // Manifesto em JSON dentro do campo uploadManifest
    final uploadManifest = {
      'input': {
        'name': documentName,
        '_filename': [fileName],
      },
    };

    request.fields['uploadManifest'] = json.encode(uploadManifest);

    // Arquivo em si – o campo precisa se chamar filename[0]
    request.files.add(
      http.MultipartFile.fromBytes(
        'filename[0]',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    print('↩️ Upload status=${response.statusCode} body=${response.body}');

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Falha ao fazer upload (status ${response.statusCode}): ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final docId = _asInt(data['id']);

    if (docId == null || docId <= 0) {
      throw Exception(
        'Upload OK, mas não consegui obter o ID do documento: $data',
      );
    }

    print('✅ Documento criado com ID $docId');
    return docId;
  }

  // Cria o vínculo Document_Item
  Future<void> linkDocumentToItem({
    required String sessionToken,
    required String type, // 'Computer', 'Phone', 'Printer'...
    required int itemId,
    required int documentId,
  }) async {
    final uri = Uri.parse('$baseUrl/Document_Item');
    print('🔗 Vinculando Document($documentId) -> $type($itemId)');

    final body = json.encode({
      'input': {
        'itemtype': type,
        'items_id': itemId,
        'documents_id': documentId,
      },
    });

    final resp = await _client.post(
      uri,
      headers: _authHeaders(sessionToken),
      body: body,
    );

    print('↩️ Document_Item status=${resp.statusCode} body=${resp.body}');

    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(
        'Falha ao vincular documento ao item (status ${resp.statusCode}): ${resp.body}',
      );
    }
  }

  // Helper completo: upload + vincular em uma chamada só
  Future<int> uploadAndLinkDocumentToItem({
    required String sessionToken,
    required String type, // ex: 'Computer'
    required int itemId,
    required String fileName,
    required List<int> fileBytes,
    String? documentName,
  }) async {
    final docId = await uploadDocument(
      sessionToken: sessionToken,
      documentName: documentName ?? fileName,
      fileName: fileName,
      fileBytes: fileBytes,
    );

    await linkDocumentToItem(
      sessionToken: sessionToken,
      type: type,
      itemId: itemId,
      documentId: docId,
    );

    return docId;
  }

  Future<void> deleteDocument({
    required String sessionToken,
    required int documentId,
  }) async {
    // Força exclusão definitiva
    final uri = Uri.parse('$baseUrl/Document/$documentId?force_purge=1');
    print('🗑️ DELETANDO PERMANENTEMENTE Document($documentId) → $uri');

    final headers = _authHeaders(sessionToken);

    // Alguns GLPI permitem body, mas permanente não precisa.
    final resp = await _client.delete(uri, headers: headers);

    print('↩️ deleteDocument status=${resp.statusCode} body=${resp.body}');

    if (resp.statusCode != 200 &&
        resp.statusCode != 204 &&
        resp.statusCode != 201) {
      throw Exception(
        'Falha ao excluir permanentemente (status ${resp.statusCode}): ${resp.body}',
      );
    }

    print('✅ Documento $documentId removido PERMANENTEMENTE.');
  }

  Future<Map<String, dynamic>> getItemRawForName(
    String type,
    int id,
    String sessionToken,
  ) async {
    final uri = Uri.parse('$baseUrl/$type/$id');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));

    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar $type($id): ${resp.statusCode}');
    }

    return json.decode(resp.body) as Map<String, dynamic>;
  }

  // ====== PROBLEMAS / ASSISTÊNCIA TÉCNICA ======

  Future<List<dynamic>> _listProblemLinks({
    required String type, // 'Computer', 'Phone', ...
    required int id,
    required String sessionToken,
  }) async {
    final allRows = await _getAll('/Item_Problem', sessionToken);
    final filtered = allRows.whereType<Map<String, dynamic>>().where((row) {
      final itemType = (row['itemtype'] ?? '').toString();
      final itemsId = _asInt(row['items_id']);
      return itemType == type && itemsId == id;
    }).toList();

    print(
      '🔗 Item_Problem total=${allRows.length} filtrados=${filtered.length}',
    );
    return filtered;
  }

  Future<Map<String, dynamic>> _getProblemRaw({
    required int id,
    required String sessionToken,
  }) async {
    final uri = Uri.parse('$baseUrl/Problem/$id');
    final resp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar Problem($id): ${resp.statusCode}');
    }
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listProblemsForItem({
    required String type, // 'Computer' | 'Phone' | 'Printer'
    required int id,
    required String sessionToken,
  }) async {
    final links = await _listProblemLinks(
      type: type,
      id: id,
      sessionToken: sessionToken,
    );

    final ids = <int>{};
    for (final l in links) {
      final pid = _asInt(l['problems_id'] ?? l['problem_id']);
      if (pid != null) ids.add(pid);
    }

    final problems = <Map<String, dynamic>>[];
    for (final pid in ids) {
      final raw = await _getProblemRaw(id: pid, sessionToken: sessionToken);
      problems.add(raw);
    }

    // Ordena por data de modificação desc
    problems.sort((a, b) {
      final aDate = (a['date_mod'] ?? a['date_creation'] ?? '') as String;
      final bDate = (b['date_mod'] ?? b['date_creation'] ?? '') as String;
      return bDate.compareTo(aDate);
    });

    return problems;
  }

  Future<void> _linkProblemToItem({
    required String sessionToken,
    required String itemtype,
    required int itemsId,
    required int problemsId,
  }) async {
    final uri = Uri.parse('$baseUrl/Item_Problem');
    final body = json.encode({
      'input': {
        'itemtype': itemtype,
        'items_id': itemsId,
        'problems_id': problemsId,
      },
    });

    final resp = await _client.post(
      uri,
      headers: _authHeaders(sessionToken),
      body: body,
    );

    print('↩️ Item_Problem status=${resp.statusCode} body=${resp.body}');
    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(
        'Falha ao vincular Problem ao item (status ${resp.statusCode}): ${resp.body}',
      );
    }
  }

  Future<int> createAssistenciaTecnicaProblemForItem({
    required String sessionToken,
    required String itemtype, // 'Computer'
    required int itemsId,
    required String titulo, // título montado na tela
    required String conteudo, // corpo com checklist
    required int tecnicoUserId, // 👈 NOVO: técnico selecionado
  }) async {
    final uri = Uri.parse('$baseUrl/Problem');
    final body = json.encode({
      'input': {
        'name': titulo,
        'content': conteudo,
        'status': 1, // Novo
        'users_id_recipient': tecnicoUserId, // Requerente
        'users_id_assign': tecnicoUserId, // Atribuído
      },
    });

    final resp = await _client.post(
      uri,
      headers: _authHeaders(sessionToken),
      body: body,
    );

    print('↩️ Problem create status=${resp.statusCode} body=${resp.body}');

    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(
        'Falha ao criar Problem (status ${resp.statusCode}): ${resp.body}',
      );
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    final problemId = _asInt(data['id']);
    if (problemId == null || problemId <= 0) {
      throw Exception(
        'Problem criado mas id não retornado corretamente: $data',
      );
    }

    // Vincula ao item
    await _linkProblemToItem(
      sessionToken: sessionToken,
      itemtype: itemtype,
      itemsId: itemsId,
      problemsId: problemId,
    );

    return problemId;
  }

  Future<int?> getGroupIdByName({
    required String sessionToken,
    required String groupName,
  }) async {
    final groups = await _getAll('/Group', sessionToken);

    for (final g in groups.whereType<Map<String, dynamic>>()) {
      final name = (g['name'] ?? '').toString().trim();

      if (name.toLowerCase() == groupName.toLowerCase()) {
        return g['id'] is int ? g['id'] : int.tryParse('${g['id']}');
      }
    }

    return null;
  }

  // Lista usuários do GLPI com categoria "TI"
  Future<List<Map<String, dynamic>>> listTechniciansFromGroupTI({
    required String sessionToken,
  }) async {
    // Busca todos os usuários (ajuste pageSize/maxPages se tiver muito usuário)
    final allUsers = await _getAll(
      '/User',
      sessionToken,
      pageSize: 200,
      maxPages: 20,
    );

    final techs = <Map<String, dynamic>>[];

    for (final raw in allUsers) {
      if (raw is! Map<String, dynamic>) continue;

      final id = _asInt(raw['id']) ?? 0;
      if (id == 0) continue;

      // Aqui estou assumindo que o campo "category" (ou "category_name")
      // identifica o usuário como TI. Ajuste se o seu GLPI usar outro campo.
      final category = (raw['category'] ?? raw['category_name'] ?? '')
          .toString()
          .toUpperCase();

      if (category == 'TI') {
        techs.add({
          'id': id,
          'realname': raw['realname'] ?? '',
          'firstname': raw['firstname'] ?? '',
        });
      }
    }

    // Ordena por nome
    techs.sort((a, b) {
      final na = ('${a['realname']} ${a['firstname']}').trim().toLowerCase();
      final nb = ('${b['realname']} ${b['firstname']}').trim().toLowerCase();
      return na.compareTo(nb);
    });

    return techs;
  }

  Future<List<Map<String, dynamic>>> listUsersFromGroupTI({
    required String sessionToken,
  }) async {
    // 1) Buscar ID do grupo TI
    final groupId = await getGroupIdByName(
      sessionToken: sessionToken,
      groupName: 'TI',
    );

    if (groupId == null) {
      print('⚠️ Grupo "TI" não encontrado no GLPI');
      return [];
    }

    // 2) Buscar usuários ligados ao grupo
    final groupUsers = await _getAll('/Group_User', sessionToken);

    final userIds = <int>{};

    for (final row in groupUsers.whereType<Map<String, dynamic>>()) {
      final gId = (row['groups_id'] ?? '').toString();
      if (gId == '$groupId') {
        final uId = row['users_id'];
        if (uId != null) {
          userIds.add(uId is int ? uId : int.tryParse('$uId') ?? 0);
        }
      }
    }

    if (userIds.isEmpty) {
      print('⚠️ Nenhum usuário encontrado no grupo TI');
      return [];
    }

    // 3) Buscar dados dos usuários
    final allUsers = await _getAll('/User', sessionToken);

    final filtered = allUsers.whereType<Map<String, dynamic>>().where((u) {
      final id = u['id'] is int ? u['id'] : int.tryParse('${u['id']}') ?? 0;
      return userIds.contains(id);
    }).toList();

    // Ordena pelo nome
    filtered.sort((a, b) {
      final aName = ((a['realname'] ?? '') + ' ' + (a['firstname'] ?? ''))
          .trim();
      final bName = ((b['realname'] ?? '') + ' ' + (b['firstname'] ?? ''))
          .trim();
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    print('👥 Técnicos TI encontrados: ${filtered.length}');
    return filtered;
  }

  Future<void> addProblemComplement({
    required String sessionToken,
    required int problemId,
    required String complementText,
  }) async {
    final uri = Uri.parse('$baseUrl/Problem/$problemId');

    // Busca conteúdo atual
    final getResp = await _client.get(uri, headers: _authHeaders(sessionToken));
    if (getResp.statusCode != 200) {
      throw Exception(
        'Falha ao buscar Problem($problemId) para complemento: ${getResp.statusCode}',
      );
    }
    final raw = json.decode(getResp.body) as Map<String, dynamic>;
    final oldContent = (raw['content'] ?? '').toString();

    final now = DateTime.now();
    final complementBlock =
        '''

-----------------------------
Complemento em ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:
$complementText
'''
            .trimRight();

    final newContent = oldContent.trimRight().isEmpty
        ? complementBlock
        : '$oldContent\n\n$complementBlock';

    final body = json.encode({
      'input': {'id': problemId, 'content': newContent},
    });

    var resp = await _client.put(
      uri,
      headers: _authHeaders(sessionToken),
      body: body,
    );

    if (resp.statusCode == 400 || resp.statusCode == 405) {
      resp = await _client.patch(
        uri,
        headers: _authHeaders(sessionToken),
        body: body,
      );
    }

    print(
      '↩️ addProblemComplement status=${resp.statusCode} body=${resp.body}',
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'Falha ao adicionar complemento ao Problem (status ${resp.statusCode}): ${resp.body}',
      );
    }
  }

  // Lista usuários ativos (para usar como técnicos no combo)
  Future<List<Map<String, dynamic>>> listActiveUsers({
    required String sessionToken,
  }) async {
    final all = await _getAll('/User', sessionToken);

    final users = all.whereType<Map<String, dynamic>>().where((u) {
      final isActive = (u['is_active'] ?? 1).toString() == '1';
      final isDeleted = (u['is_deleted'] ?? 0).toString() == '0';
      return isActive && !isDeleted;
    }).toList();

    // Ordenar pelo nome
    users.sort((a, b) {
      final aName = ((a['realname'] ?? '') + ' ' + (a['firstname'] ?? ''))
          .trim();
      final bName = ((b['realname'] ?? '') + ' ' + (b['firstname'] ?? ''))
          .trim();
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return users;
  }

  Future<void> deleteProblemPermanently({
    required int problemId,
    required String sessionToken,
  }) async {
    // DELETE /Problem/:id?force_purge=1&history=false
    final uri = Uri.parse(
      '$baseUrl/Problem/$problemId?force_purge=1&history=false',
    );

    final resp = await _client.delete(uri, headers: _authHeaders(sessionToken));

    // GLPI pode retornar 200 ou 204 na deleção
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception(
        'Falha ao excluir permanentemente Problem($problemId): '
        '${resp.statusCode} ${resp.body}',
      );
    }

    print('🗑️ Problem $problemId excluído permanentemente (force_purge=1)');
  }

  void dispose() {
    _client.close();
  }
}
