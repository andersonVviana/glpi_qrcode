import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/glpi_config.dart';
import '../models/inventory_item.dart';

class GLPIService {
  final String baseUrl;
  final String appToken;

  GLPIService({String? baseUrl, String? appToken})
    : baseUrl = baseUrl ?? GLPIConfig.baseUrl,
      appToken = appToken ?? GLPIConfig.appToken;

  // ======================= Autenticação =======================
  Future<String> initSessionWithUserToken(String userToken) async {
    final uri = Uri.parse('$baseUrl/initSession');
    final headers = {
      'Authorization': 'user_token $userToken',
      'App-Token': appToken,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final resp = await http.post(uri, headers: headers);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final sessionToken =
          data['session_token'] ??
          data['sessionToken'] ??
          data['Session-Token'];
      if (sessionToken is String && sessionToken.isNotEmpty) {
        return sessionToken;
      }
      throw Exception('Não foi possível obter o Session-Token.');
    }
    throw Exception('Falha ao iniciar sessão no GLPI (${resp.statusCode})');
  }

  Map<String, String> _authHeaders(String sessionToken) => {
    'Session-Token': sessionToken,
    'App-Token': appToken,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ======================= Lookups com cache =======================
  // Muitos campos vêm como IDs. Buscamos o "name" ou "completename".
  final Map<int, String> _manufacturerCache = {};
  final Map<int, String> _userCache = {};
  final Map<int, String> _locationCache = {};
  final Map<int, String> _computerModelCache = {};
  final Map<int, String> _phoneModelCache = {};
  final Map<int, String> _printerModelCache = {};

  Future<String> _getNameById(
    String endpoint,
    int? id,
    String sessionToken, {
    String fallback = '',
    String nameKey = 'name',
  }) async {
    if (id == null || id == 0) return fallback;
    final uri = Uri.parse('$baseUrl$endpoint/$id');
    final resp = await http.get(uri, headers: _authHeaders(sessionToken));
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

  Future<String> _getComputerModelName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_computerModelCache.containsKey(id)) return _computerModelCache[id]!;
    final name = await _getNameById('/Computermodel', id, sessionToken);
    _computerModelCache[id] = name;
    return name;
  }

  Future<String> _getPhoneModelName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_phoneModelCache.containsKey(id)) return _phoneModelCache[id]!;
    final name = await _getNameById('/Phonemodel', id, sessionToken);
    _phoneModelCache[id] = name;
    return name;
  }

  Future<String> _getPrinterModelName(int? id, String sessionToken) async {
    if (id == null || id == 0) return '';
    if (_printerModelCache.containsKey(id)) return _printerModelCache[id]!;
    final name = await _getNameById('/Printermodel', id, sessionToken);
    _printerModelCache[id] = name;
    return name;
  }

  Future<List<InventoryItem>> listComputers({
    required String sessionToken,
    String? search,
  }) async {
    final data = await _getAll('/Computer', sessionToken); // 👈 pega TODOS
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
    return items;
  }

  Future<List<InventoryItem>> listPhones({
    required String sessionToken,
    String? search,
  }) async {
    final data = await _getAll('/Phone', sessionToken); // 👈
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
    return items;
  }

  Future<List<InventoryItem>> listPrinters({
    required String sessionToken,
    String? search,
  }) async {
    final data = await _getAll('/Printer', sessionToken); // 👈
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
    return items;
  }

  Future<List<dynamic>> _getList(
    String endpoint,
    String sessionToken, {
    String range = '0-99',
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = _authHeaders(sessionToken);
    headers['Range'] = range; // 👈 GLPI espera Range no header
    final resp = await http.get(uri, headers: headers);

    // 200 (OK) ou 206 (Partial Content) são respostas válidas
    if (resp.statusCode == 200 || resp.statusCode == 206) {
      final body = json.decode(resp.body);
      if (body is List) return body;
      throw Exception('Resposta inesperada do GLPI em $endpoint.');
    }
    throw Exception('Erro ao buscar $endpoint (${resp.statusCode})');
  }

  // ========= Detalhes por tipo =========

  Future<Map<String, String>> getComputerDetails({
    required String sessionToken,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/Computer/$id');
    final resp = await http.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar computador ($id): ${resp.statusCode}');
    }
    final Map<String, dynamic> raw = json.decode(resp.body);

    final mId = _asInt(raw['manufacturers_id']);
    final uId = _asInt(raw['users_id']);
    final lId = _asInt(raw['locations_id']);
    final modelId = _asInt(raw['computermodels_id']);

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
      'Sistema Oper.': '${raw['os_name'] ?? raw['os'] ?? ''}',
      'Domínio': '${raw['domain'] ?? ''}',
      'Observações': '${raw['comment'] ?? ''}',
      'Criado em': '${raw['date_creation'] ?? ''}',
      'Atualizado em': '${raw['date_mod'] ?? ''}',
    };
  }

  Future<Map<String, String>> getPhoneDetails({
    required String sessionToken,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/Phone/$id');
    final resp = await http.get(uri, headers: _authHeaders(sessionToken));
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar telefone ($id): ${resp.statusCode}');
    }
    final Map<String, dynamic> raw = json.decode(resp.body);

    final mId = _asInt(raw['manufacturers_id']);
    final uId = _asInt(raw['users_id']);
    final lId = _asInt(raw['locations_id']);
    final modelId = _asInt(raw['phonemodels_id']);

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
      'Usuário': await _getUserName(uId, sessionToken),
      'Localização': await _getLocationName(lId, sessionToken),
      'Observações': '${raw['comment'] ?? ''}',
      'Criado em': '${raw['date_creation'] ?? ''}',
      'Atualizado em': '${raw['date_mod'] ?? ''}',
    };
  }

  Future<Map<String, String>> getPrinterDetails({
    required String sessionToken,
    required int id,
  }) async {
    final uri = Uri.parse('$baseUrl/Printer/$id');
    final resp = await http.get(uri, headers: _authHeaders(sessionToken));
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
      'Observações': '${raw['comment'] ?? ''}',
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
    final resp = await http.get(uri, headers: _authHeaders(sessionToken));
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
      'input': {
        'id': id, // 👈 GLPI exige o id dentro de "input"
        'comment': newComment, // campo a atualizar
      },
    });

    final headers = _authHeaders(sessionToken);

    // Tenta com PUT (padrão GLPI)
    var resp = await http.put(uri, headers: headers, body: body);

    // Alguns setups aceitam PATCH melhor que PUT; tenta fallback se 400/405
    if (resp.statusCode == 400 || resp.statusCode == 405) {
      resp = await http.patch(uri, headers: headers, body: body);
    }

    if (resp.statusCode != 200) {
      // opcional: inspecione a mensagem que o GLPI retornou
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
    final fmt = DateFormat('dd/MM/yyyy HH:mm'); // 👈 formato solicitado
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
      // substitui SOMENTE o bloco do ano corrente
      return comment.replaceAll(specific, newBlock);
    } else {
      // adiciona no final com linha em branco, sem mexer em anos anteriores
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
    required String type, // 'Computer' | 'Phone' | 'Printer'
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
      updated: existsCurrent, // se já existe, marca "(Atualizado)"
    );

    final newComment = _upsertYearBlock(currentComment, year, block);
    if (newComment == currentComment) {
      // nada mudou
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

  // Retorna TODAS as linhas de um endpoint paginando via header Range
  Future<List<dynamic>> _getAll(
    String endpoint,
    String sessionToken, {
    int pageSize = 200,
  }) async {
    final List<dynamic> all = [];
    int start = 0;
    int? total; // lido do Content-Range (ex.: "items 0-199/1342")

    while (true) {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = _authHeaders(sessionToken);
      headers['Range'] = '$start-${start + pageSize - 1}';

      final resp = await http.get(uri, headers: headers);

      if (resp.statusCode != 200 && resp.statusCode != 206) {
        throw Exception('Erro ao buscar $endpoint (${resp.statusCode})');
      }

      // Somar os itens desta página
      final page = json.decode(resp.body);
      if (page is! List) throw Exception('Resposta inesperada em $endpoint.');
      all.addAll(page);

      // Tentar ler o total do header Content-Range
      final cr = resp.headers['content-range'] ?? resp.headers['Content-Range'];
      // Formato esperado: items 0-199/1342
      if (cr != null) {
        final m = RegExp(r'items\s+(\d+)-(\d+)/(\d+|\*)').firstMatch(cr);
        if (m != null) {
          final end = int.parse(m.group(2)!);
          final totStr = m.group(3)!;
          total = totStr == '*' ? null : int.tryParse(totStr);
          // Se soubermos o total e já passamos do fim, para
          if (total != null && end >= total! - 1) break;
        }
      }

      // Critério de parada seguro quando o servidor não informa o total
      if (page.length < pageSize) break;

      start += pageSize;
    }

    return all;
  }

  /// Lê o comentário e retorna os dados do inventário do ano atual, se existir.
  Future<Map<String, String>?> getCurrentYearInventoryInfo({
    required String type, // 'Computer' | 'Phone' | 'Printer'
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
      final r = RegExp('^$key:\\s*(.*)\$', multiLine: true);
      final mm = r.firstMatch(block);
      return (mm?.group(1) ?? '').trim();
    }

    final nome = _extract('Nome');
    final dataHora = _extract('Data/Hora'); // já vem no formato salvo
    // status não é obrigatório para exibir, mas fica aqui se quiser usar
    // final status = _extract('Status');

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
}
