// lib/screens/assistencia_tecnica_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';

class AssistenciaTecnicaPage extends StatefulWidget {
  final String type; // 'Computer'
  final int id;
  final String hostname;
  final String tipoComputador;
  final String serial;

  const AssistenciaTecnicaPage({
    super.key,
    required this.type,
    required this.id,
    required this.hostname,
    required this.tipoComputador,
    required this.serial,
  });

  @override
  State<AssistenciaTecnicaPage> createState() => _AssistenciaTecnicaPageState();
}

class _AssistenciaTecnicaPageState extends State<AssistenciaTecnicaPage> {
  final GLPIService _service = GLPIService();

  // ===== Checklists =====

  // 1.1 Estado geral
  bool semAvarias = false;
  bool tampaArranhada = false;
  bool tampaTrincada = false;
  bool baseArranhada = false;
  bool quebraChassi = false;
  bool dobradicaSolta = false;
  bool amassadoCarcaca = false;
  bool outroEstadoGeral = false;
  final TextEditingController outroEstadoGeralCtrl = TextEditingController();

  // 1.2 Tela
  bool telaSemDanos = false;
  bool telaArranhada = false;
  bool telaTrincada = false;
  bool telaDeadPixels = false;
  bool telaManchas = false;
  bool telaBacklightIrregular = false;

  // 1.3 Teclado / Touchpad
  bool teclasFaltando = false;
  bool teclasTravadas = false;
  bool touchNaoResponde = false;
  bool touchTrincado = false;
  bool tecladoLiquido = false;

  // 1.4 Portas / Conectores
  bool usbOk = false;
  bool hdmiOk = false;
  bool portaEnergiaFirme = false;
  bool portaEnergiaSolta = false;

  // 2. Acessórios
  bool acessFonte = false;
  bool acessCaboEnergia = false;
  bool acessDock = false;
  bool acessMouse = false;
  bool acessTecladoExt = false;
  bool acessBolsa = false;
  final TextEditingController observacoesAcessCtrl = TextEditingController();

  // 3.1 Energia
  bool energiaLigaNormal = false;
  bool energiaNaoLiga = false;
  bool energiaLigaDesliga = false;
  bool energiaSoFonte = false;
  bool energiaBatNaoCarrega = false;
  bool energiaBatDescarregaRapido = false;
  final TextEditingController energiaObsCtrl = TextEditingController();

  // 3.2 Sistema
  bool sistemaInicializa = false;
  bool sistemaNaoInicializa = false;
  bool sistemaTelaAzul = false;
  bool sistemaLento = false;

  // 3.3 Áudio / Vídeo
  bool audioAltoFalante = false;
  bool audioMic = false;
  bool audioWebcam = false;

  // 3.3 Rede
  bool redeWifi = false;
  bool redeEthernet = false;
  bool redeBluetooth = false;

  // 4 Problema reportado
  final TextEditingController problemaReportadoCtrl = TextEditingController();

  // 5 Testes
  bool testeHd = false;
  bool testeMemoria = false;
  bool testeTemperatura = false;
  bool testeBateria = false;
  bool testeDesempenho = false;
  final TextEditingController observacoesTestesCtrl = TextEditingController();

  // 6 Backup
  bool backupInfoUsuario = false;
  bool backupRealizadoUsuario = false;
  bool backupRealizadoTecnico = false;
  bool backupNaoSeAplica = false;

  // 7 Outras observações
  final TextEditingController outrasObsCtrl = TextEditingController();

  // Estado geral
  bool _saving = false;
  bool _sentOnce = false;
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
    outroEstadoGeralCtrl.dispose();
    observacoesAcessCtrl.dispose();
    energiaObsCtrl.dispose();
    problemaReportadoCtrl.dispose();
    observacoesTestesCtrl.dispose();
    outrasObsCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _loadTechnicians() async {
    setState(() => _loadingTechs = true);
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      // 👇 pega só usuários do grupo "TI"
      final list = await _service.listUsersFromGroupTI(sessionToken: session);
      if (!mounted) return;
      setState(() {
        _technicians = list;
      });
    } catch (e) {
      print('⚠️ Erro ao carregar técnicos TI: $e');
    } finally {
      if (mounted) setState(() => _loadingTechs = false);
    }
  }

  bool _hasAnyChecklistMarked() {
    final all = [
      semAvarias,
      tampaArranhada,
      tampaTrincada,
      baseArranhada,
      quebraChassi,
      dobradicaSolta,
      amassadoCarcaca,
      outroEstadoGeral,
      telaSemDanos,
      telaArranhada,
      telaTrincada,
      telaDeadPixels,
      telaManchas,
      telaBacklightIrregular,
      teclasFaltando,
      teclasTravadas,
      touchNaoResponde,
      touchTrincado,
      tecladoLiquido,
      usbOk,
      hdmiOk,
      portaEnergiaFirme,
      portaEnergiaSolta,
      acessFonte,
      acessCaboEnergia,
      acessDock,
      acessMouse,
      acessTecladoExt,
      acessBolsa,
      energiaLigaNormal,
      energiaNaoLiga,
      energiaLigaDesliga,
      energiaSoFonte,
      energiaBatNaoCarrega,
      energiaBatDescarregaRapido,
      sistemaInicializa,
      sistemaNaoInicializa,
      sistemaTelaAzul,
      sistemaLento,
      audioAltoFalante,
      audioMic,
      audioWebcam,
      redeWifi,
      redeEthernet,
      redeBluetooth,
      testeHd,
      testeMemoria,
      testeTemperatura,
      testeBateria,
      testeDesempenho,
      backupInfoUsuario,
      backupRealizadoUsuario,
      backupRealizadoTecnico,
      backupNaoSeAplica,
    ];
    return all.any((v) => v);
  }

  String _buildFormText() {
    final b = StringBuffer();

    b.writeln('1. Condições Físicas do Equipamento');

    // 1.1 Estado geral
    b.writeln('\n1.1 - Estado geral:');
    void add1(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add1('Sem avarias', semAvarias);
    add1('Tampa arranhada', tampaArranhada);
    add1('Tampa trincada', tampaTrincada);
    add1('Base arranhada', baseArranhada);
    add1('Quebra no chassi', quebraChassi);
    add1('Dobradiça solta/trincada', dobradicaSolta);
    add1('Amassado na carcaça', amassadoCarcaca);
    if (outroEstadoGeral && outroEstadoGeralCtrl.text.trim().isNotEmpty) {
      add1('Outro: ${outroEstadoGeralCtrl.text.trim()}', true);
    }

    // 1.2 Tela
    b.writeln('\n1.2 - Tela:');
    void add12(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add12('Sem danos', telaSemDanos);
    add12('Arranhada', telaArranhada);
    add12('Trincada', telaTrincada);
    add12('Dead pixels', telaDeadPixels);
    add12('Manchas na tela', telaManchas);
    add12('Backlight irregular', telaBacklightIrregular);

    // 1.3 Teclado / Touchpad
    b.writeln('\n1.3 - Teclado / Touchpad:');
    void add13(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add13('Teclas faltando', teclasFaltando);
    add13('Teclas travadas', teclasTravadas);
    add13('Touchpad não responde', touchNaoResponde);
    add13('Touchpad trincado', touchTrincado);
    add13('Teclado com derramamento de líquido', tecladoLiquido);

    // 1.4 Portas / conectores
    b.writeln('\n1.4 - Portas e Conectores:');
    void add14(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add14('USB funcionando', usbOk);
    add14('HDMI/DisplayPort funcionando', hdmiOk);
    add14('Porta de energia firme', portaEnergiaFirme);
    add14('Porta de energia solta', portaEnergiaSolta);

    // 2 Acessórios
    b.writeln(
      '\n2. Acessórios Enviados (marcar apenas o que está indo junto):',
    );
    void add2(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add2('Fonte', acessFonte);
    add2('Cabo de energia', acessCaboEnergia);
    add2('Dock station', acessDock);
    add2('Mouse', acessMouse);
    add2('Teclado externo', acessTecladoExt);
    add2('Bolsa', acessBolsa);
    if (observacoesAcessCtrl.text.trim().isNotEmpty) {
      b.writeln('Observações: ${observacoesAcessCtrl.text.trim()}');
    }

    // 3 Estado de funcionamento
    b.writeln('\n3. Estado de Funcionamento');

    b.writeln('\n3.1 - Energia:');
    void add31(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add31('Liga normalmente', energiaLigaNormal);
    add31('Não liga', energiaNaoLiga);
    add31('Liga e desliga', energiaLigaDesliga);
    add31('Só liga na fonte', energiaSoFonte);
    add31('Bateria não carrega', energiaBatNaoCarrega);
    add31('Bateria descarrega rápido', energiaBatDescarregaRapido);
    if (energiaObsCtrl.text.trim().isNotEmpty) {
      b.writeln('Obs: ${energiaObsCtrl.text.trim()}');
    }

    b.writeln('\n3.2 - Sistema:');
    void add32(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add32('Sistema inicializa', sistemaInicializa);
    add32('Sistema não inicializa', sistemaNaoInicializa);
    add32('Tela azul (BSOD)', sistemaTelaAzul);
    add32('Lentidão excessiva', sistemaLento);

    b.writeln('\n3.3 - Áudio / Vídeo:');
    void add33(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add33('Alto-falante funciona', audioAltoFalante);
    add33('Microfone funciona', audioMic);
    add33('Webcam funciona', audioWebcam);

    b.writeln('\n3.3 - Rede:');
    void add33r(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add33r('Wi-Fi funcionando', redeWifi);
    add33r('Ethernet funcionando', redeEthernet);
    add33r('Bluetooth funcionando', redeBluetooth);

    // 4 Problema reportado
    b.writeln('\n4. Problema Reportado pelo Usuário:');
    if (problemaReportadoCtrl.text.trim().isNotEmpty) {
      b.writeln(problemaReportadoCtrl.text.trim());
    } else {
      b.writeln('(não informado)');
    }

    // 5 Testes realizados
    b.writeln('\n5. Testes Realizados:');
    void add5(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add5('Teste de HD/SSD', testeHd);
    add5('Teste de memória', testeMemoria);
    add5('Teste de temperatura', testeTemperatura);
    add5('Teste de bateria', testeBateria);
    add5('Teste de desempenho', testeDesempenho);
    if (observacoesTestesCtrl.text.trim().isNotEmpty) {
      b.writeln('Observações: ${observacoesTestesCtrl.text.trim()}');
    }

    // 6 Backup
    b.writeln('\n6. Backup:');
    void add6(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add6('Usuário informado sobre necessidade de backup', backupInfoUsuario);
    add6('Backup realizado pelo usuário', backupRealizadoUsuario);
    add6('Backup realizado pelo técnico', backupRealizadoTecnico);
    add6('Não se aplica', backupNaoSeAplica);

    // 7 Outras observações
    b.writeln('\n7. Outras Observações:');
    if (outrasObsCtrl.text.trim().isNotEmpty) {
      b.writeln(outrasObsCtrl.text.trim());
    } else {
      b.writeln('(sem observações adicionais)');
    }

    return b.toString();
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

      // 👇 Busca o técnico selecionado na lista e monta o nome
      final tecnicoSelecionado = _technicians.firstWhere((t) {
        final rawId = t['id'];
        final id = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
        return id == _selectedTechId;
      }, orElse: () => {});

      final nomeTecnico = tecnicoSelecionado.isNotEmpty
          ? _userDisplayName(tecnicoSelecionado)
          : '(técnico não encontrado)';

      final conteudo =
          '''
Técnico responsável: $nomeTecnico

$conteudoBase
'''
              .trim();

      if (!_sentOnce) {
        // PRIMEIRO ENVIO → cria Problem
        final titulo =
            'Assistência Técnica - ${widget.hostname} - Tipo : ${widget.tipoComputador} - S/N : ${widget.serial}';

        final problemId = await _service.createAssistenciaTecnicaProblemForItem(
          sessionToken: session,
          itemtype: widget.type, // 'Computer'
          itemsId: widget.id,
          titulo: titulo,
          conteudo: conteudo,
          tecnicoUserId: _selectedTechId!, // técnico GLPI (id)
        );

        setState(() {
          _sentOnce = true;
          _problemId = problemId;
        });

        _showSnack('Problema criado no GLPI.', color: Colors.green.shade600);
      } else {
        // COMPLEMENTO DE INFORMAÇÃO
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
                      '1. Condições Físicas do Equipamento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1.1 - Estado geral:'),
                    CheckboxListTile(
                      value: semAvarias,
                      onChanged: (v) => setState(() => semAvarias = v ?? false),
                      title: const Text('Sem avarias'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: tampaArranhada,
                      onChanged: (v) =>
                          setState(() => tampaArranhada = v ?? false),
                      title: const Text('Tampa arranhada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: tampaTrincada,
                      onChanged: (v) =>
                          setState(() => tampaTrincada = v ?? false),
                      title: const Text('Tampa trincada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: baseArranhada,
                      onChanged: (v) =>
                          setState(() => baseArranhada = v ?? false),
                      title: const Text('Base arranhada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: quebraChassi,
                      onChanged: (v) =>
                          setState(() => quebraChassi = v ?? false),
                      title: const Text('Quebra no chassi'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: dobradicaSolta,
                      onChanged: (v) =>
                          setState(() => dobradicaSolta = v ?? false),
                      title: const Text('Dobradiça solta/trincada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: amassadoCarcaca,
                      onChanged: (v) =>
                          setState(() => amassadoCarcaca = v ?? false),
                      title: const Text('Amassado na carcaça'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: outroEstadoGeral,
                      onChanged: (v) =>
                          setState(() => outroEstadoGeral = v ?? false),
                      title: const Text('Outro'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (outroEstadoGeral)
                      TextField(
                        controller: outroEstadoGeralCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descreva o outro estado geral',
                        ),
                      ),
                    const SizedBox(height: 12),

                    const Text('1.2 - Tela:'),
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
                      value: telaDeadPixels,
                      onChanged: (v) =>
                          setState(() => telaDeadPixels = v ?? false),
                      title: const Text('Dead pixels'),
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
                      value: telaBacklightIrregular,
                      onChanged: (v) =>
                          setState(() => telaBacklightIrregular = v ?? false),
                      title: const Text('Backlight irregular'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),
                    const Text('1.3 - Teclado / Touchpad:'),
                    CheckboxListTile(
                      value: teclasFaltando,
                      onChanged: (v) =>
                          setState(() => teclasFaltando = v ?? false),
                      title: const Text('Teclas faltando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: teclasTravadas,
                      onChanged: (v) =>
                          setState(() => teclasTravadas = v ?? false),
                      title: const Text('Teclas travadas'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: touchNaoResponde,
                      onChanged: (v) =>
                          setState(() => touchNaoResponde = v ?? false),
                      title: const Text('Touchpad não responde'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: touchTrincado,
                      onChanged: (v) =>
                          setState(() => touchTrincado = v ?? false),
                      title: const Text('Touchpad trincado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: tecladoLiquido,
                      onChanged: (v) =>
                          setState(() => tecladoLiquido = v ?? false),
                      title: const Text('Teclado com derramamento de líquido'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),
                    const Text('1.4 - Portas e Conectores:'),
                    CheckboxListTile(
                      value: usbOk,
                      onChanged: (v) => setState(() => usbOk = v ?? false),
                      title: const Text('USB funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: hdmiOk,
                      onChanged: (v) => setState(() => hdmiOk = v ?? false),
                      title: const Text('HDMI/DisplayPort funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portaEnergiaFirme,
                      onChanged: (v) =>
                          setState(() => portaEnergiaFirme = v ?? false),
                      title: const Text('Porta de energia firme'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portaEnergiaSolta,
                      onChanged: (v) =>
                          setState(() => portaEnergiaSolta = v ?? false),
                      title: const Text('Porta de energia solta'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '2. Acessórios Enviados (marcar apenas o que está indo junto)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      value: acessFonte,
                      onChanged: (v) => setState(() => acessFonte = v ?? false),
                      title: const Text('Fonte'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessCaboEnergia,
                      onChanged: (v) =>
                          setState(() => acessCaboEnergia = v ?? false),
                      title: const Text('Cabo de energia'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessDock,
                      onChanged: (v) => setState(() => acessDock = v ?? false),
                      title: const Text('Dock station'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessMouse,
                      onChanged: (v) => setState(() => acessMouse = v ?? false),
                      title: const Text('Mouse'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessTecladoExt,
                      onChanged: (v) =>
                          setState(() => acessTecladoExt = v ?? false),
                      title: const Text('Teclado externo'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessBolsa,
                      onChanged: (v) => setState(() => acessBolsa = v ?? false),
                      title: const Text('Bolsa'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: observacoesAcessCtrl,
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
                      value: energiaLigaNormal,
                      onChanged: (v) =>
                          setState(() => energiaLigaNormal = v ?? false),
                      title: const Text('Liga normalmente'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: energiaNaoLiga,
                      onChanged: (v) =>
                          setState(() => energiaNaoLiga = v ?? false),
                      title: const Text('Não liga'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: energiaLigaDesliga,
                      onChanged: (v) =>
                          setState(() => energiaLigaDesliga = v ?? false),
                      title: const Text('Liga e desliga'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: energiaSoFonte,
                      onChanged: (v) =>
                          setState(() => energiaSoFonte = v ?? false),
                      title: const Text('Só liga na fonte'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: energiaBatNaoCarrega,
                      onChanged: (v) =>
                          setState(() => energiaBatNaoCarrega = v ?? false),
                      title: const Text('Bateria não carrega'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: energiaBatDescarregaRapido,
                      onChanged: (v) => setState(
                        () => energiaBatDescarregaRapido = v ?? false,
                      ),
                      title: const Text('Bateria descarrega rápido'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: energiaObsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Obs. sobre energia',
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text('3.2 Sistema:'),
                    CheckboxListTile(
                      value: sistemaInicializa,
                      onChanged: (v) =>
                          setState(() => sistemaInicializa = v ?? false),
                      title: const Text('Sistema inicializa'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: sistemaNaoInicializa,
                      onChanged: (v) =>
                          setState(() => sistemaNaoInicializa = v ?? false),
                      title: const Text('Sistema não inicializa'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: sistemaTelaAzul,
                      onChanged: (v) =>
                          setState(() => sistemaTelaAzul = v ?? false),
                      title: const Text('Tela azul (BSOD)'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: sistemaLento,
                      onChanged: (v) =>
                          setState(() => sistemaLento = v ?? false),
                      title: const Text('Lentidão excessiva'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.3 Áudio / Vídeo:'),
                    CheckboxListTile(
                      value: audioAltoFalante,
                      onChanged: (v) =>
                          setState(() => audioAltoFalante = v ?? false),
                      title: const Text('Alto-falante funciona'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: audioMic,
                      onChanged: (v) => setState(() => audioMic = v ?? false),
                      title: const Text('Microfone funciona'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: audioWebcam,
                      onChanged: (v) =>
                          setState(() => audioWebcam = v ?? false),
                      title: const Text('Webcam funciona'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.3 Rede:'),
                    CheckboxListTile(
                      value: redeWifi,
                      onChanged: (v) => setState(() => redeWifi = v ?? false),
                      title: const Text('Wi-Fi funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: redeEthernet,
                      onChanged: (v) =>
                          setState(() => redeEthernet = v ?? false),
                      title: const Text('Ethernet funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: redeBluetooth,
                      onChanged: (v) =>
                          setState(() => redeBluetooth = v ?? false),
                      title: const Text('Bluetooth funcionando'),
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
                      value: testeHd,
                      onChanged: (v) => setState(() => testeHd = v ?? false),
                      title: const Text('Teste de HD/SSD'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeMemoria,
                      onChanged: (v) =>
                          setState(() => testeMemoria = v ?? false),
                      title: const Text('Teste de memória'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeTemperatura,
                      onChanged: (v) =>
                          setState(() => testeTemperatura = v ?? false),
                      title: const Text('Teste de temperatura'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeBateria,
                      onChanged: (v) =>
                          setState(() => testeBateria = v ?? false),
                      title: const Text('Teste de bateria'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeDesempenho,
                      onChanged: (v) =>
                          setState(() => testeDesempenho = v ?? false),
                      title: const Text('Teste de desempenho'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: observacoesTestesCtrl,
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
                      value: backupInfoUsuario,
                      onChanged: (v) =>
                          setState(() => backupInfoUsuario = v ?? false),
                      title: const Text(
                        'Usuário informado sobre necessidade de backup',
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
                            items: _technicians.map((u) {
                              final rawId = u['id'];
                              final id = rawId is int
                                  ? rawId
                                  : int.tryParse('$rawId') ?? 0;

                              final display = _userDisplayName(u);

                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(display),
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
