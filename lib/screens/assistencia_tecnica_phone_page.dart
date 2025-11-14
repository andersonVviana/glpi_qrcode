// lib/screens/assistencia_tecnica_phone_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';

class AssistenciaTecnicaPhonePage extends StatefulWidget {
  final String type; // 'Phone'
  final int id;
  final String hostname;      // Nome do aparelho no GLPI
  final String modelo;        // Modelo do telefone
  final String imeiOuSerial;  // IMEI ou serial

  const AssistenciaTecnicaPhonePage({
    super.key,
    required this.type,
    required this.id,
    required this.hostname,
    required this.modelo,
    required this.imeiOuSerial,
  });

  @override
  State<AssistenciaTecnicaPhonePage> createState() =>
      _AssistenciaTecnicaPhonePageState();
}

class _AssistenciaTecnicaPhonePageState
    extends State<AssistenciaTecnicaPhonePage> {
  final GLPIService _service = GLPIService();

  // ===================== CHECKLISTS =====================

  // 1.1 Carcaça
  bool carSemAvarias = false;
  bool carArranhado = false;
  bool carTrincado = false;
  bool carAmassado = false;
  bool carTampaTraseiraSolta = false;
  bool carTampasLateraisQuebradas = false;
  bool carOxidacao = false;

  // 1.2 Tela
  bool telaSemDanos = false;
  bool telaArranhada = false;
  bool telaTrincada = false;
  bool telaQuebrada = false;
  bool telaManchas = false;
  bool telaSensibilidadeIrregular = false;
  bool telaGhostTouch = false;

  // 1.3 Botões
  bool btPowerOk = false;
  bool btPowerFalhando = false;
  bool btVolMaisOk = false;
  bool btVolMenosOk = false;
  bool btTravando = false;

  // 1.4 Portas / Conectores
  bool portCargaOk = false;
  bool portCargaFrouxo = false;
  bool portFoneOk = false;
  bool portFoneDanificada = false;
  bool portChipOk = false;
  bool portChipDefeito = false;

  // 2. Acessórios
  bool accCarregador = false;
  bool accCaboUSB = false;
  bool accFoneOuvido = false;
  bool accCapaProtetora = false;
  bool accPelicula = false;
  bool accSuporteChip = false;
  final TextEditingController accObsCtrl = TextEditingController();

  // 3.1 Energia
  bool eneLigaNormal = false;
  bool eneNaoLiga = false;
  bool eneLigaEDesliga = false;
  bool eneNaoRecarrega = false;
  bool eneCarregaLentamente = false;
  bool eneSuperaquecendo = false;

  // 3.2 Sistema
  bool sisInicializa = false;
  bool sisTravamentos = false;
  bool sisLentidao = false;
  bool sisReiniciaSozinho = false;
  bool sisFalhaSO = false;

  // 3.3 Comunicação
  bool comWifiOk = false;
  bool comBtOk = false;
  bool com4g5gOk = false;
  bool comSemSinal = false;
  bool comChipNaoReconhece = false;

  // 3.4 Áudio / Vídeo
  bool avSpeakerOk = false;
  bool avMicOk = false;
  bool avFoneSaidaOk = false;
  bool avCamFrontalOk = false;
  bool avCamTraseiraOk = false;
  bool avCamErro = false;

  // 3.5 Sensores
  bool senBiometriaOk = false;
  bool senFaceIdOk = false;
  bool senGiroscopioOk = false;
  bool senNfcOk = false;
  bool senGpsOk = false;

  // 4 Testes realizados
  bool testResetSimples = false;
  bool testBateria = false;
  bool testSensores = false;
  bool testAcessorios = false;
  bool testAtualizacaoSO = false;
  bool testComunicacao = false;
  final TextEditingController testObsCtrl = TextEditingController();

  // 5 Backup
  bool backupUsuarioInformado = false;
  bool backupRealizadoUsuario = false;
  bool backupRealizadoTecnico = false;
  bool backupNaoSeAplica = false;

  // 4 Problema reportado (texto livre)
  final TextEditingController problemaReportadoCtrl = TextEditingController();

  // 7 Outras observações
  final TextEditingController outrasObsCtrl = TextEditingController();

  // Estado geral
  bool _saving = false;
  bool _sentOnce = false; // já criou o Problem?
  int? _problemId;

  // Técnicos (grupo TI)
  List<Map<String, dynamic>> _technicians = [];
  int? _selectedTechId;
  bool _loadingTechs = false;

  @override
  void initState() {
    super.initState();
    _loadTechnicians();
  }

  @override
  void dispose() {
    accObsCtrl.dispose();
    testObsCtrl.dispose();
    problemaReportadoCtrl.dispose();
    outrasObsCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ============ CARREGAR TÉCNICOS DO GRUPO "TI" ============

  Future<void> _loadTechnicians() async {
    setState(() => _loadingTechs = true);
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      // 👇 EXATAMENTE IGUAL À ASSISTENCIA_TECNICA_PAGE (computador)
      final list = await _service.listUsersFromGroupTI(
        sessionToken: session,
      );
      if (!mounted) return;
      setState(() {
        _technicians = list;
      });
      print(
        '👥 Técnicos TI (Phone): encontrados ${list.length} registros',
      );
    } catch (e) {
      print('⚠️ Erro ao carregar técnicos TI (Phone): $e');
    } finally {
      if (mounted) setState(() => _loadingTechs = false);
    }
  }

  String _userDisplayName(Map<String, dynamic> u) {
    final realname = (u['realname'] ?? '').toString().trim();
    final firstname = (u['firstname'] ?? '').toString().trim();
    final loginName = (u['name'] ?? '').toString().trim();

    String display = [realname, firstname].where((s) => s.isNotEmpty).join(' ');
    if (display.isEmpty) display = loginName;
    if (display.isEmpty) display = '(sem nome)';
    return display;
  }

  bool _hasAnyChecklistMarked() {
    final all = <bool>[
      carSemAvarias,
      carArranhado,
      carTrincado,
      carAmassado,
      carTampaTraseiraSolta,
      carTampasLateraisQuebradas,
      carOxidacao,
      telaSemDanos,
      telaArranhada,
      telaTrincada,
      telaQuebrada,
      telaManchas,
      telaSensibilidadeIrregular,
      telaGhostTouch,
      btPowerOk,
      btPowerFalhando,
      btVolMaisOk,
      btVolMenosOk,
      btTravando,
      portCargaOk,
      portCargaFrouxo,
      portFoneOk,
      portFoneDanificada,
      portChipOk,
      portChipDefeito,
      accCarregador,
      accCaboUSB,
      accFoneOuvido,
      accCapaProtetora,
      accPelicula,
      accSuporteChip,
      eneLigaNormal,
      eneNaoLiga,
      eneLigaEDesliga,
      eneNaoRecarrega,
      eneCarregaLentamente,
      eneSuperaquecendo,
      sisInicializa,
      sisTravamentos,
      sisLentidao,
      sisReiniciaSozinho,
      sisFalhaSO,
      comWifiOk,
      comBtOk,
      com4g5gOk,
      comSemSinal,
      comChipNaoReconhece,
      avSpeakerOk,
      avMicOk,
      avFoneSaidaOk,
      avCamFrontalOk,
      avCamTraseiraOk,
      avCamErro,
      senBiometriaOk,
      senFaceIdOk,
      senGiroscopioOk,
      senNfcOk,
      senGpsOk,
      testResetSimples,
      testBateria,
      testSensores,
      testAcessorios,
      testAtualizacaoSO,
      testComunicacao,
      backupUsuarioInformado,
      backupRealizadoUsuario,
      backupRealizadoTecnico,
      backupNaoSeAplica,
    ];

    return all.any((b) => b);
  }

  String _buildFormText() {
    final b = StringBuffer();

    b.writeln('1. Condições Físicas do Aparelho');

    // 1.1 Carcaça
    b.writeln('\n1.1 Carcaça:');
    void add11(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add11('Sem avarias', carSemAvarias);
    add11('Arranhado', carArranhado);
    add11('Trincado', carTrincado);
    add11('Amassado', carAmassado);
    add11('Tampa traseira solta', carTampaTraseiraSolta);
    add11('Tampas/laterais quebradas', carTampasLateraisQuebradas);
    add11('Oxidação aparente', carOxidacao);

    // 1.2 Tela
    b.writeln('\n1.2 Tela:');
    void add12(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add12('Sem danos', telaSemDanos);
    add12('Arranhada', telaArranhada);
    add12('Trincada', telaTrincada);
    add12('Quebrada', telaQuebrada);
    add12('Manchas na tela', telaManchas);
    add12('Sensibilidade irregular (toque falhando)', telaSensibilidadeIrregular);
    add12('Ghost touch', telaGhostTouch);

    // 1.3 Botões
    b.writeln('\n1.3 Botões:');
    void add13(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add13('Power funcionando', btPowerOk);
    add13('Power falhando', btPowerFalhando);
    add13('Volume + funcionando', btVolMaisOk);
    add13('Volume - funcionando', btVolMenosOk);
    add13('Botões travando', btTravando);

    // 1.4 Portas e Conectores
    b.writeln('\n1.4 Portas e Conectores:');
    void add14(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add14('Conector de carga funcionando', portCargaOk);
    add14('Conector de carga frouxo', portCargaFrouxo);
    add14('Entrada de fone funcionando', portFoneOk);
    add14('Entrada de fone danificada', portFoneDanificada);
    add14('Leitor de chip funcionando', portChipOk);
    add14('Leitor de chip com defeito', portChipDefeito);

    // 2. Acessórios enviados
    b.writeln('\n2. Acessórios Enviados (marcar apenas o que está indo junto):');
    void add2(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add2('Carregador', accCarregador);
    add2('Cabo USB', accCaboUSB);
    add2('Fone de ouvido', accFoneOuvido);
    add2('Capa protetora', accCapaProtetora);
    add2('Película', accPelicula);
    add2('Suporte de chip', accSuporteChip);
    if (accObsCtrl.text.trim().isNotEmpty) {
      b.writeln('Observações (acessórios): ${accObsCtrl.text.trim()}');
    }

    // 3. Estado de Funcionamento
    b.writeln('\n3. Estado de Funcionamento');

    // 3.1 Energia
    b.writeln('\n3.1 Energia:');
    void add31(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add31('Liga normalmente', eneLigaNormal);
    add31('Não liga', eneNaoLiga);
    add31('Liga e desliga', eneLigaEDesliga);
    add31('Não recarrega', eneNaoRecarrega);
    add31('Carrega lentamente', eneCarregaLentamente);
    add31('Superaquecendo', eneSuperaquecendo);

    // 3.2 Sistema
    b.writeln('\n3.2 Sistema:');
    void add32(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add32('Sistema inicializa', sisInicializa);
    add32('Travamentos constantes', sisTravamentos);
    add32('Lentidão', sisLentidao);
    add32('Reiniciando sozinho', sisReiniciaSozinho);
    add32('Falha no SO (Android/iOS)', sisFalhaSO);

    // 3.3 Comunicação
    b.writeln('\n3.3 Comunicação:');
    void add33(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add33('Wi-Fi funcionando', comWifiOk);
    add33('Bluetooth funcionando', comBtOk);
    add33('4G/5G funcionando', com4g5gOk);
    add33('Sem sinal', comSemSinal);
    add33('Chip não reconhece', comChipNaoReconhece);

    // 3.4 Áudio / Vídeo
    b.writeln('\n3.4 Áudio/Vídeo:');
    void add34(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add34('Alto-falante ok', avSpeakerOk);
    add34('Microfone ok', avMicOk);
    add34('Fone/saída de áudio funcionando', avFoneSaidaOk);
    add34('Câmera frontal ok', avCamFrontalOk);
    add34('Câmera traseira ok', avCamTraseiraOk);
    add34('Câmera com erro / não abre', avCamErro);

    // 3.5 Sensores
    b.writeln('\n3.5 Sensores:');
    void add35(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add35('Biometria funcionando', senBiometriaOk);
    add35('Face ID funcionando', senFaceIdOk);
    add35('Giroscópio/rotação funcionando', senGiroscopioOk);
    add35('NFC funcionando', senNfcOk);
    add35('GPS funcionando', senGpsOk);

    // 4 Problema reportado
    b.writeln('\n4. Problema Reportado pelo Usuário:');
    if (problemaReportadoCtrl.text.trim().isNotEmpty) {
      b.writeln(problemaReportadoCtrl.text.trim());
    } else {
      b.writeln('(não informado)');
    }

    // 4 (nos seus tópicos é 4, mas aqui já usamos 4 acima) – Testes realizados
    b.writeln('\n5. Testes Realizados:');
    void addTest(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    addTest('Reset simples', testResetSimples);
    addTest('Teste de bateria', testBateria);
    addTest('Teste de sensores', testSensores);
    addTest('Teste de acessórios', testAcessorios);
    addTest('Verificação de atualização do sistema', testAtualizacaoSO);
    addTest('Teste de comunicação (chamada, dados, Wi-Fi)', testComunicacao);
    if (testObsCtrl.text.trim().isNotEmpty) {
      b.writeln('Observações (testes): ${testObsCtrl.text.trim()}');
    }

    // 5 Backup
    b.writeln('\n6. Backup:');
    void addBk(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    addBk('Usuário informado sobre o backup', backupUsuarioInformado);
    addBk('Backup realizado pelo usuário', backupRealizadoUsuario);
    addBk('Backup realizado pelo técnico', backupRealizadoTecnico);
    addBk('Não se aplica', backupNaoSeAplica);

    // 7 Outras observações
    b.writeln('\n7. Outras Observações:');
    if (outrasObsCtrl.text.trim().isNotEmpty) {
      b.writeln(outrasObsCtrl.text.trim());
    } else {
      b.writeln('(sem observações adicionais)');
    }

    return b.toString();
  }

  Future<void> _onSave() async {
    if (!_hasAnyChecklistMarked()) {
      _showSnack(
        'Marque pelo menos um item do checklist antes de salvar.',
        color: Colors.orange,
      );
      return;
    }

    if (_selectedTechId == null) {
      _showSnack(
        'Selecione o técnico responsável antes de salvar.',
        color: Colors.orange,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      final conteudoBase = _buildFormText();

      // Técnico selecionado (igual ao computador)
      final tecnicoSelecionado = _technicians.firstWhere(
        (t) {
          final rawId = t['id'];
          final id = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
          return id == _selectedTechId;
        },
        orElse: () => {},
      );

      final nomeTecnico = tecnicoSelecionado.isNotEmpty
          ? _userDisplayName(tecnicoSelecionado)
          : '(técnico não encontrado)';

      final conteudo = '''
Técnico responsável: $nomeTecnico

$conteudoBase
'''.trim();

      if (!_sentOnce) {
        // PRIMEIRO ENVIO → cria Problem
        final titulo =
            'Assistência Técnica - ${widget.hostname} - Modelo: ${widget.modelo} - ID: ${widget.imeiOuSerial}';

        final problemId = await _service.createAssistenciaTecnicaProblemForItem(
          sessionToken: session,
          itemtype: widget.type, // 'Phone'
          itemsId: widget.id,
          titulo: titulo,
          conteudo: conteudo,
          tecnicoUserId: _selectedTechId!, // Requerente / Atribuído
        );

        setState(() {
          _sentOnce = true;
          _problemId = problemId;
        });

        _showSnack('Problema criado no GLPI.', color: Colors.green.shade600);
      } else {
        // COMPLEMENTO
        if (_problemId == null) {
          throw Exception('ID do problema não encontrado para complemento.');
        }
        await _service.addProblemComplement(
          sessionToken: session,
          problemId: _problemId!,
          complementText: conteudo,
        );

        _showSnack(
          'Complemento de informação enviado.',
          color: Colors.green.shade600,
        );
      }
    } catch (e) {
      _showSnack('Erro ao enviar: $e', color: Colors.red.shade600);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Assistência Técnica - ${widget.hostname}',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: purple,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Condições Físicas do Aparelho',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1.1 Carcaça:'),
                    CheckboxListTile(
                      value: carSemAvarias,
                      onChanged: (v) =>
                          setState(() => carSemAvarias = v ?? false),
                      title: const Text('Sem avarias'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: carArranhado,
                      onChanged: (v) =>
                          setState(() => carArranhado = v ?? false),
                      title: const Text('Arranhado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: carTrincado,
                      onChanged: (v) =>
                          setState(() => carTrincado = v ?? false),
                      title: const Text('Trincado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: carAmassado,
                      onChanged: (v) =>
                          setState(() => carAmassado = v ?? false),
                      title: const Text('Amassado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: carTampaTraseiraSolta,
                      onChanged: (v) => setState(
                        () => carTampaTraseiraSolta = v ?? false,
                      ),
                      title: const Text('Tampa traseira solta'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: carTampasLateraisQuebradas,
                      onChanged: (v) => setState(
                        () => carTampasLateraisQuebradas = v ?? false,
                      ),
                      title: const Text('Tampas/laterais quebradas'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: carOxidacao,
                      onChanged: (v) =>
                          setState(() => carOxidacao = v ?? false),
                      title: const Text('Oxidação aparente'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),
                    const Text('1.2 Tela:'),
                    CheckboxListTile(
                      value: telaSemDanos,
                      onChanged: (v) =>
                          setState(() => telaSemDanos = v ?? false),
                      title: const Text('Sem danos'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: telaArranhada,
                      onChanged: (v) =>
                          setState(() => telaArranhada = v ?? false),
                      title: const Text('Arranhada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: telaTrincada,
                      onChanged: (v) =>
                          setState(() => telaTrincada = v ?? false),
                      title: const Text('Trincada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: telaQuebrada,
                      onChanged: (v) =>
                          setState(() => telaQuebrada = v ?? false),
                      title: const Text('Quebrada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: telaManchas,
                      onChanged: (v) =>
                          setState(() => telaManchas = v ?? false),
                      title: const Text('Manchas na tela'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: telaSensibilidadeIrregular,
                      onChanged: (v) =>
                          setState(() => telaSensibilidadeIrregular = v ?? false),
                      title: const Text('Sensibilidade irregular (toque falhando)'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: telaGhostTouch,
                      onChanged: (v) =>
                          setState(() => telaGhostTouch = v ?? false),
                      title: const Text('Ghost touch'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),
                    const Text('1.3 Botões:'),
                    CheckboxListTile(
                      value: btPowerOk,
                      onChanged: (v) =>
                          setState(() => btPowerOk = v ?? false),
                      title: const Text('Power funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: btPowerFalhando,
                      onChanged: (v) =>
                          setState(() => btPowerFalhando = v ?? false),
                      title: const Text('Power falhando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: btVolMaisOk,
                      onChanged: (v) =>
                          setState(() => btVolMaisOk = v ?? false),
                      title: const Text('Volume + funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: btVolMenosOk,
                      onChanged: (v) =>
                          setState(() => btVolMenosOk = v ?? false),
                      title: const Text('Volume - funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: btTravando,
                      onChanged: (v) =>
                          setState(() => btTravando = v ?? false),
                      title: const Text('Botões travando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),
                    const Text('1.4 Portas e Conectores:'),
                    CheckboxListTile(
                      value: portCargaOk,
                      onChanged: (v) =>
                          setState(() => portCargaOk = v ?? false),
                      title: const Text('Conector de carga funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portCargaFrouxo,
                      onChanged: (v) =>
                          setState(() => portCargaFrouxo = v ?? false),
                      title: const Text('Conector de carga frouxo'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portFoneOk,
                      onChanged: (v) =>
                          setState(() => portFoneOk = v ?? false),
                      title: const Text('Entrada de fone funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portFoneDanificada,
                      onChanged: (v) =>
                          setState(() => portFoneDanificada = v ?? false),
                      title: const Text('Entrada de fone danificada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portChipOk,
                      onChanged: (v) =>
                          setState(() => portChipOk = v ?? false),
                      title: const Text('Leitor de chip funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portChipDefeito,
                      onChanged: (v) =>
                          setState(() => portChipDefeito = v ?? false),
                      title: const Text('Leitor de chip com defeito'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '2. Acessórios Enviados',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      value: accCarregador,
                      onChanged: (v) =>
                          setState(() => accCarregador = v ?? false),
                      title: const Text('Carregador'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: accCaboUSB,
                      onChanged: (v) =>
                          setState(() => accCaboUSB = v ?? false),
                      title: const Text('Cabo USB'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: accFoneOuvido,
                      onChanged: (v) =>
                          setState(() => accFoneOuvido = v ?? false),
                      title: const Text('Fone de ouvido'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: accCapaProtetora,
                      onChanged: (v) =>
                          setState(() => accCapaProtetora = v ?? false),
                      title: const Text('Capa protetora'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: accPelicula,
                      onChanged: (v) =>
                          setState(() => accPelicula = v ?? false),
                      title: const Text('Película'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: accSuporteChip,
                      onChanged: (v) =>
                          setState(() => accSuporteChip = v ?? false),
                      title: const Text('Suporte de chip'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: accObsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observações (acessórios)',
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '3. Estado de Funcionamento',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('3.1 Energia:'),
                    CheckboxListTile(
                      value: eneLigaNormal,
                      onChanged: (v) =>
                          setState(() => eneLigaNormal = v ?? false),
                      title: const Text('Liga normalmente'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: eneNaoLiga,
                      onChanged: (v) =>
                          setState(() => eneNaoLiga = v ?? false),
                      title: const Text('Não liga'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: eneLigaEDesliga,
                      onChanged: (v) =>
                          setState(() => eneLigaEDesliga = v ?? false),
                      title: const Text('Liga e desliga'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: eneNaoRecarrega,
                      onChanged: (v) =>
                          setState(() => eneNaoRecarrega = v ?? false),
                      title: const Text('Não recarrega'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: eneCarregaLentamente,
                      onChanged: (v) =>
                          setState(() => eneCarregaLentamente = v ?? false),
                      title: const Text('Carrega lentamente'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: eneSuperaquecendo,
                      onChanged: (v) =>
                          setState(() => eneSuperaquecendo = v ?? false),
                      title: const Text('Superaquecendo'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.2 Sistema:'),
                    CheckboxListTile(
                      value: sisInicializa,
                      onChanged: (v) =>
                          setState(() => sisInicializa = v ?? false),
                      title: const Text('Sistema inicializa'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: sisTravamentos,
                      onChanged: (v) =>
                          setState(() => sisTravamentos = v ?? false),
                      title: const Text('Travamentos constantes'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: sisLentidao,
                      onChanged: (v) =>
                          setState(() => sisLentidao = v ?? false),
                      title: const Text('Lentidão'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: sisReiniciaSozinho,
                      onChanged: (v) =>
                          setState(() => sisReiniciaSozinho = v ?? false),
                      title: const Text('Reiniciando sozinho'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: sisFalhaSO,
                      onChanged: (v) =>
                          setState(() => sisFalhaSO = v ?? false),
                      title: const Text('Falha no SO (Android/iOS)'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.3 Comunicação:'),
                    CheckboxListTile(
                      value: comWifiOk,
                      onChanged: (v) =>
                          setState(() => comWifiOk = v ?? false),
                      title: const Text('Wi-Fi funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: comBtOk,
                      onChanged: (v) =>
                          setState(() => comBtOk = v ?? false),
                      title: const Text('Bluetooth funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: com4g5gOk,
                      onChanged: (v) =>
                          setState(() => com4g5gOk = v ?? false),
                      title: const Text('4G/5G funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: comSemSinal,
                      onChanged: (v) =>
                          setState(() => comSemSinal = v ?? false),
                      title: const Text('Sem sinal'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: comChipNaoReconhece,
                      onChanged: (v) =>
                          setState(() => comChipNaoReconhece = v ?? false),
                      title: const Text('Chip não reconhece'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.4 Áudio/Vídeo:'),
                    CheckboxListTile(
                      value: avSpeakerOk,
                      onChanged: (v) =>
                          setState(() => avSpeakerOk = v ?? false),
                      title: const Text('Alto-falante ok'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: avMicOk,
                      onChanged: (v) =>
                          setState(() => avMicOk = v ?? false),
                      title: const Text('Microfone ok'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: avFoneSaidaOk,
                      onChanged: (v) =>
                          setState(() => avFoneSaidaOk = v ?? false),
                      title: const Text('Fone/saída de áudio funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: avCamFrontalOk,
                      onChanged: (v) =>
                          setState(() => avCamFrontalOk = v ?? false),
                      title: const Text('Câmera frontal ok'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: avCamTraseiraOk,
                      onChanged: (v) =>
                          setState(() => avCamTraseiraOk = v ?? false),
                      title: const Text('Câmera traseira ok'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: avCamErro,
                      onChanged: (v) =>
                          setState(() => avCamErro = v ?? false),
                      title: const Text('Câmera com erro / não abre'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.5 Sensores:'),
                    CheckboxListTile(
                      value: senBiometriaOk,
                      onChanged: (v) =>
                          setState(() => senBiometriaOk = v ?? false),
                      title: const Text('Biometria funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: senFaceIdOk,
                      onChanged: (v) =>
                          setState(() => senFaceIdOk = v ?? false),
                      title: const Text('Face ID funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: senGiroscopioOk,
                      onChanged: (v) =>
                          setState(() => senGiroscopioOk = v ?? false),
                      title: const Text('Giroscópio/rotação funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: senNfcOk,
                      onChanged: (v) =>
                          setState(() => senNfcOk = v ?? false),
                      title: const Text('NFC funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: senGpsOk,
                      onChanged: (v) =>
                          setState(() => senGpsOk = v ?? false),
                      title: const Text('GPS funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '4. Problema Reportado pelo Usuário',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: problemaReportadoCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Descreva claramente o que o usuário relata',
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '5. Testes Realizados',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      value: testResetSimples,
                      onChanged: (v) =>
                          setState(() => testResetSimples = v ?? false),
                      title: const Text('Reset simples'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testBateria,
                      onChanged: (v) =>
                          setState(() => testBateria = v ?? false),
                      title: const Text('Teste de bateria'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testSensores,
                      onChanged: (v) =>
                          setState(() => testSensores = v ?? false),
                      title: const Text('Teste de sensores'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testAcessorios,
                      onChanged: (v) =>
                          setState(() => testAcessorios = v ?? false),
                      title: const Text('Teste de acessórios'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testAtualizacaoSO,
                      onChanged: (v) =>
                          setState(() => testAtualizacaoSO = v ?? false),
                      title: const Text('Verificação de atualização do sistema'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testComunicacao,
                      onChanged: (v) =>
                          setState(() => testComunicacao = v ?? false),
                      title: const Text(
                        'Teste de comunicação (chamada, dados, Wi-Fi)',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: testObsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observações (testes)',
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '6. Backup',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      value: backupUsuarioInformado,
                      onChanged: (v) => setState(
                        () => backupUsuarioInformado = v ?? false,
                      ),
                      title: const Text(
                        'Usuário informado sobre o backup',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: backupRealizadoUsuario,
                      onChanged: (v) =>
                          setState(() => backupRealizadoUsuario = v ?? false),
                      title: const Text('Backup realizado pelo usuário'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: backupRealizadoTecnico,
                      onChanged: (v) =>
                          setState(() => backupRealizadoTecnico = v ?? false),
                      title: const Text('Backup realizado pelo técnico'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: backupNaoSeAplica,
                      onChanged: (v) =>
                          setState(() => backupNaoSeAplica = v ?? false),
                      title: const Text('Não se aplica'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '7. Outras Observações',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: outrasObsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Digite outras observações relevantes',
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Técnico Responsável (Requerente / Atribuído)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _loadingTechs
                        ? const LinearProgressIndicator()
                        : DropdownButtonFormField<int>(
                            value: _selectedTechId,
                            decoration: const InputDecoration(
                              labelText: 'Selecione o técnico',
                              border: OutlineInputBorder(),
                            ),
                            isExpanded: true,
                            items: _technicians.map((u) {
                              final rawId = u['id'];
                              final id = rawId is int
                                  ? rawId
                                  : int.tryParse('$rawId') ?? 0;

                              final display = _userDisplayName(u);

                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  display,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() => _selectedTechId = v);
                            },
                          ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _onSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _sentOnce
                                  ? 'Complemento de Informação'
                                  : 'Salvar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
