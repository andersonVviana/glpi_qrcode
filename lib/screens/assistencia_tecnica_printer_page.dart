// lib/screens/assistencia_tecnica_printer_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';

class AssistenciaTecnicaPrinterPage extends StatefulWidget {
  final String type; // 'Printer'
  final int id;
  final String hostname;
  final String modelo;      // modelo da impressora
  final String serial;      // serial ou outro identificador

  const AssistenciaTecnicaPrinterPage({
    super.key,
    required this.type,
    required this.id,
    required this.hostname,
    required this.modelo,
    required this.serial,
  });

  @override
  State<AssistenciaTecnicaPrinterPage> createState() =>
      _AssistenciaTecnicaPrinterPageState();
}

class _AssistenciaTecnicaPrinterPageState
    extends State<AssistenciaTecnicaPrinterPage> {
  final GLPIService _service = GLPIService();

  // ========= 1. Condição Física =========

  // 1.1 Estrutura / Carcaça
  bool estruturaSemAvarias = false;
  bool estruturaArranhado = false;
  bool estruturaTrincado = false;
  bool estruturaTampaSolta = false;
  bool estruturaBaseInstavel = false;
  bool estruturaAmassadoImpacto = false;

  // 1.2 Painel / Controles
  bool painelBotoesOK = false;
  bool painelLcdOK = false;
  bool painelLedsOK = false;
  bool painelBotoesTravando = false;

  // 1.3 Portas / Cabos / Conectores
  bool portasCaboAlimentacaoFirme = false;
  bool portasCaboRedeUsbOK = false;
  bool portasLeitorMidiaOK = false;
  bool portasBandejaBemAjustada = false;
  bool portasCartuchoBemEncaixado = false;

  // ========= 2. Acessórios =========
  bool acessCaboAlimentacao = false;
  bool acessCaboUSB = false;
  bool acessCaboRede = false;
  bool acessTonerCartuchos = false;
  bool acessLabelRoll = false;
  bool acessDocDrivers = false;
  bool acessManualGuia = false;
  final TextEditingController observacoesAcessCtrl = TextEditingController();

  // ========= 3. Estado de Funcionamento =========

  // 3.1 Energia e Inicialização
  bool energiaLigaNormal = false;
  bool energiaNaoLiga = false;
  bool energiaLigaDesliga = false;
  bool energiaLigaSemResposta = false;

  // 3.2 Impressão
  bool impressaoNormal = false;
  bool impressaoFalhas = false;
  bool impressaoLenta = false;
  bool impressaoNaoImprime = false;
  bool impressaoErroSemPapel = false;
  bool impressaoErroSemToner = false;

  // 3.3 Qualidade de Impressão
  bool qualidadeSemManchas = false;
  bool qualidadeLetrasFaltando = false;
  bool qualidadeEsmaecida = false;
  bool qualidadeCoresErradas = false;
  bool qualidadeEtiquetaDesalinhada = false;
  bool qualidadeCorteAutoFuncional = false;

  // 3.4 Rede / Conectividade
  bool redeUsbFunc = false;
  bool redeEthernetFunc = false;
  bool redeWifiFunc = false;
  bool redeVisivelServidor = false;

  // ========= 4. Testes Realizados =========
  bool testeDriver = false;
  bool testeImpressaoSimples = false;
  bool testeQualidade = false;
  bool testePaginaDiag = false;
  bool testeBandejasAlimentador = false;
  bool testeSensores = false;
  bool testeRede = false;
  final TextEditingController observacoesTestesCtrl = TextEditingController();

  // ========= 5. Consumíveis / Manutenção Preventiva =========
  bool consTonerValidadeOK = false;
  bool consEtiquetasOK = false;
  bool consCilindroFusorChecado = false;
  bool consCabecaImpressaoLimpa = false;
  bool consBandejasLimpas = false;
  bool consFirmwareAtualizado = false;
  final TextEditingController observacoesConsCtrl = TextEditingController();

  // ========= 6. Observações Gerais =========
  final TextEditingController obsGeraisCtrl = TextEditingController();

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
    observacoesAcessCtrl.dispose();
    observacoesTestesCtrl.dispose();
    observacoesConsCtrl.dispose();
    obsGeraisCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _loadTechnicians() async {
    setState(() => _loadingTechs = true);
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      final list = await _service.listUsersFromGroupTI(sessionToken: session);
      if (!mounted) return;
      setState(() {
        _technicians = list;
      });
    } catch (e) {
      print('⚠️ Erro ao carregar técnicos TI (Printer): $e');
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
    final all = [
      // 1.1
      estruturaSemAvarias,
      estruturaArranhado,
      estruturaTrincado,
      estruturaTampaSolta,
      estruturaBaseInstavel,
      estruturaAmassadoImpacto,
      // 1.2
      painelBotoesOK,
      painelLcdOK,
      painelLedsOK,
      painelBotoesTravando,
      // 1.3
      portasCaboAlimentacaoFirme,
      portasCaboRedeUsbOK,
      portasLeitorMidiaOK,
      portasBandejaBemAjustada,
      portasCartuchoBemEncaixado,
      // 2
      acessCaboAlimentacao,
      acessCaboUSB,
      acessCaboRede,
      acessTonerCartuchos,
      acessLabelRoll,
      acessDocDrivers,
      acessManualGuia,
      // 3.1
      energiaLigaNormal,
      energiaNaoLiga,
      energiaLigaDesliga,
      energiaLigaSemResposta,
      // 3.2
      impressaoNormal,
      impressaoFalhas,
      impressaoLenta,
      impressaoNaoImprime,
      impressaoErroSemPapel,
      impressaoErroSemToner,
      // 3.3
      qualidadeSemManchas,
      qualidadeLetrasFaltando,
      qualidadeEsmaecida,
      qualidadeCoresErradas,
      qualidadeEtiquetaDesalinhada,
      qualidadeCorteAutoFuncional,
      // 3.4
      redeUsbFunc,
      redeEthernetFunc,
      redeWifiFunc,
      redeVisivelServidor,
      // 4
      testeDriver,
      testeImpressaoSimples,
      testeQualidade,
      testePaginaDiag,
      testeBandejasAlimentador,
      testeSensores,
      testeRede,
      // 5
      consTonerValidadeOK,
      consEtiquetasOK,
      consCilindroFusorChecado,
      consCabecaImpressaoLimpa,
      consBandejasLimpas,
      consFirmwareAtualizado,
    ];
    return all.any((v) => v);
  }

  String _buildFormText() {
    final b = StringBuffer();

    b.writeln('1. Condição Física do Equipamento');

    // 1.1 Estrutura / Carcaça
    b.writeln('\n1.1 Estrutura / Carcaça:');
    void add11(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add11('Sem avarias', estruturaSemAvarias);
    add11('Arranhado', estruturaArranhado);
    add11('Trincado / quebrado', estruturaTrincado);
    add11('Tampa solta', estruturaTampaSolta);
    add11('Base instável', estruturaBaseInstavel);
    add11('Amassado / dado impacto', estruturaAmassadoImpacto);

    // 1.2 Painel / Controles
    b.writeln('\n1.2 Painel / Controles:');
    void add12(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add12('Botões funcionando', painelBotoesOK);
    add12('Tela LCD ok', painelLcdOK);
    add12('Indicadores LED funcionando', painelLedsOK);
    add12('Botões travando', painelBotoesTravando);

    // 1.3 Portas / Cabos / Conectores
    b.writeln('\n1.3 Portas / Cabos / Conectores:');
    void add13(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add13('Cabo de alimentação firme', portasCaboAlimentacaoFirme);
    add13('Cabo de rede (Ethernet) / USB funcionando', portasCaboRedeUsbOK);
    add13('Leitor de mídia (etiqueta) funcionando', portasLeitorMidiaOK);
    add13('Bandeja de papel bem ajustada', portasBandejaBemAjustada);
    add13('Cartucho / Toner bem encaixado', portasCartuchoBemEncaixado);

    // 2. Acessórios
    b.writeln('\n2. Acessórios Enviados / Fornecidos:');
    void add2(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add2('Cabo de alimentação', acessCaboAlimentacao);
    add2('Cabo USB', acessCaboUSB);
    add2('Cabo de rede (Ethernet)', acessCaboRede);
    add2('Toner ou Cartuchos', acessTonerCartuchos);
    add2('Label Roll / Etiquetas', acessLabelRoll);
    add2('Documentação ou CD de drivers', acessDocDrivers);
    add2('Manual ou guia rápido', acessManualGuia);
    if (observacoesAcessCtrl.text.trim().isNotEmpty) {
      b.writeln(
        'Observações (acessórios): ${observacoesAcessCtrl.text.trim()}',
      );
    }

    // 3. Estado de Funcionamento
    b.writeln('\n3. Estado de Funcionamento');

    // 3.1 Energia e Inicialização
    b.writeln('\n3.1 Energia e Inicialização:');
    void add31(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add31('Liga normalmente', energiaLigaNormal);
    add31('Não liga', energiaNaoLiga);
    add31('Liga e desliga', energiaLigaDesliga);
    add31('Liga mas sem resposta', energiaLigaSemResposta);

    // 3.2 Impressão
    b.writeln('\n3.2 Impressão:');
    void add32(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add32('Imprime normalmente', impressaoNormal);
    add32('Imprime mas com falhas (faixas, manchas)', impressaoFalhas);
    add32('Imprime lentamente', impressaoLenta);
    add32('Não imprime', impressaoNaoImprime);
    add32('Erro de "sem papel" quando há papel', impressaoErroSemPapel);
    add32(
      'Erro de "sem toner/cartucho" quando está instalado',
      impressaoErroSemToner,
    );

    // 3.3 Qualidade de Impressão
    b.writeln('\n3.3 Qualidade de Impressão:');
    void add33(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add33('Sem manchas ou borrões', qualidadeSemManchas);
    add33('Letras/pixels faltando', qualidadeLetrasFaltando);
    add33('Impressão esmaecida', qualidadeEsmaecida);
    add33('Cores erradas (no colorido)', qualidadeCoresErradas);
    add33('Etiqueta desalinhada (na etiquetadora)', qualidadeEtiquetaDesalinhada);
    add33('Corte automático funcional', qualidadeCorteAutoFuncional);

    // 3.4 Rede / Conectividade
    b.writeln('\n3.4 Rede / Conectividade:');
    void add34(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add34('USB funcionando', redeUsbFunc);
    add34('Ethernet funcionando', redeEthernetFunc);
    add34('Wi-Fi funcionando', redeWifiFunc);
    add34('Impressora visível no servidor ou rede', redeVisivelServidor);

    // 4. Testes Realizados
    b.writeln('\n4. Testes Realizados:');
    void add4(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add4('Verificação de driver instalado e atualizado', testeDriver);
    add4('Teste de impressão simples', testeImpressaoSimples);
    add4('Teste de qualidade de impressão (padrão de teste)', testeQualidade);
    add4('Impressão de página de diagnóstico', testePaginaDiag);
    add4('Verificação de bandejas e alimentador de mídia', testeBandejasAlimentador);
    add4('Verificação de sensores (papel, atolamento)', testeSensores);
    add4('Verificação de rede/conexão', testeRede);
    if (observacoesTestesCtrl.text.trim().isNotEmpty) {
      b.writeln(
        'Observações (testes): ${observacoesTestesCtrl.text.trim()}',
      );
    }

    // 5. Consumíveis e Manutenção Preventiva
    b.writeln('\n5. Consumíveis e Manutenção Preventiva:');
    void add5(String label, bool v) {
      if (v) b.writeln('- $label');
    }

    add5('Toner/cartucho está dentro da validade', consTonerValidadeOK);
    add5('Etiquetas/label-roll sem rasgos ou falhas', consEtiquetasOK);
    add5('Cilindro/fusor checado', consCilindroFusorChecado);
    add5('Cabeça de impressão limpa (etiquetadora)', consCabecaImpressaoLimpa);
    add5('Bandejas limpas e ajustadas', consBandejasLimpas);
    add5('Firmware atualizado', consFirmwareAtualizado);
    if (observacoesConsCtrl.text.trim().isNotEmpty) {
      b.writeln(
        'Observações (consumíveis/manutenção): '
        '${observacoesConsCtrl.text.trim()}',
      );
    }

    // 6. Observações Gerais
    b.writeln('\n6. Observações Gerais:');
    if (obsGeraisCtrl.text.trim().isNotEmpty) {
      b.writeln(obsGeraisCtrl.text.trim());
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

      // Técnico selecionado
      final tecnicoSelecionado = _technicians.firstWhere((t) {
        final rawId = t['id'];
        final id = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
        return id == _selectedTechId;
      }, orElse: () => {});

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
            'Assistência Técnica - ${widget.hostname} - Modelo : ${widget.modelo} - S/N : ${widget.serial}';

        final problemId = await _service
            .createAssistenciaTecnicaProblemForItem(
          sessionToken: session,
          itemtype: widget.type, // 'Printer'
          itemsId: widget.id,
          titulo: titulo,
          conteudo: conteudo,
          tecnicoUserId: _selectedTechId!,
        );

        setState(() {
          _sentOnce = true;
          _problemId = problemId;
        });

        _showSnack(
          'Problema de impressora criado no GLPI.',
          color: Colors.green.shade600,
        );
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
                      '1. Condição Física do Equipamento',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1.1 Estrutura / Carcaça:'),
                    CheckboxListTile(
                      value: estruturaSemAvarias,
                      onChanged: (v) =>
                          setState(() => estruturaSemAvarias = v ?? false),
                      title: const Text('Sem avarias'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: estruturaArranhado,
                      onChanged: (v) =>
                          setState(() => estruturaArranhado = v ?? false),
                      title: const Text('Arranhado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: estruturaTrincado,
                      onChanged: (v) =>
                          setState(() => estruturaTrincado = v ?? false),
                      title: const Text('Trincado / quebrado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: estruturaTampaSolta,
                      onChanged: (v) =>
                          setState(() => estruturaTampaSolta = v ?? false),
                      title: const Text('Tampa solta'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: estruturaBaseInstavel,
                      onChanged: (v) =>
                          setState(() => estruturaBaseInstavel = v ?? false),
                      title: const Text('Base instável'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: estruturaAmassadoImpacto,
                      onChanged: (v) => setState(
                        () => estruturaAmassadoImpacto = v ?? false,
                      ),
                      title: const Text('Amassado / dado impacto'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),
                    const Text('1.2 Painel / Controles:'),
                    CheckboxListTile(
                      value: painelBotoesOK,
                      onChanged: (v) =>
                          setState(() => painelBotoesOK = v ?? false),
                      title: const Text('Botões funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: painelLcdOK,
                      onChanged: (v) => setState(() => painelLcdOK = v ?? false),
                      title: const Text('Tela LCD (se aplicável) ok'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: painelLedsOK,
                      onChanged: (v) =>
                          setState(() => painelLedsOK = v ?? false),
                      title: const Text('Indicadores LED funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: painelBotoesTravando,
                      onChanged: (v) =>
                          setState(() => painelBotoesTravando = v ?? false),
                      title: const Text('Botões travando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),
                    const Text('1.3 Portas / Cabos / Conectores:'),
                    CheckboxListTile(
                      value: portasCaboAlimentacaoFirme,
                      onChanged: (v) => setState(
                        () => portasCaboAlimentacaoFirme = v ?? false,
                      ),
                      title: const Text('Cabo de alimentação firme'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portasCaboRedeUsbOK,
                      onChanged: (v) => setState(
                        () => portasCaboRedeUsbOK = v ?? false,
                      ),
                      title: const Text('Cabo de rede (Ethernet) / USB funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portasLeitorMidiaOK,
                      onChanged: (v) =>
                          setState(() => portasLeitorMidiaOK = v ?? false),
                      title: const Text('Leitor de mídia (etiqueta) funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portasBandejaBemAjustada,
                      onChanged: (v) => setState(
                        () => portasBandejaBemAjustada = v ?? false,
                      ),
                      title: const Text('Bandeja de papel bem ajustada'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: portasCartuchoBemEncaixado,
                      onChanged: (v) => setState(
                        () => portasCartuchoBemEncaixado = v ?? false,
                      ),
                      title: const Text('Cartucho / Toner bem encaixado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '2. Acessórios Enviados / Fornecidos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      value: acessCaboAlimentacao,
                      onChanged: (v) =>
                          setState(() => acessCaboAlimentacao = v ?? false),
                      title: const Text('Cabo de alimentação'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessCaboUSB,
                      onChanged: (v) =>
                          setState(() => acessCaboUSB = v ?? false),
                      title: const Text('Cabo USB'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessCaboRede,
                      onChanged: (v) =>
                          setState(() => acessCaboRede = v ?? false),
                      title: const Text('Cabo de rede (Ethernet)'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessTonerCartuchos,
                      onChanged: (v) =>
                          setState(() => acessTonerCartuchos = v ?? false),
                      title: const Text('Toner ou Cartuchos'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessLabelRoll,
                      onChanged: (v) =>
                          setState(() => acessLabelRoll = v ?? false),
                      title: const Text('Label Roll / Etiquetas'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessDocDrivers,
                      onChanged: (v) =>
                          setState(() => acessDocDrivers = v ?? false),
                      title: const Text('Documentação ou CD de drivers'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: acessManualGuia,
                      onChanged: (v) =>
                          setState(() => acessManualGuia = v ?? false),
                      title: const Text('Manual ou guia rápido'),
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
                    const Text('3.1 Energia e Inicialização:'),
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
                      value: energiaLigaSemResposta,
                      onChanged: (v) =>
                          setState(() => energiaLigaSemResposta = v ?? false),
                      title: const Text('Liga mas sem resposta'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.2 Impressão:'),
                    CheckboxListTile(
                      value: impressaoNormal,
                      onChanged: (v) =>
                          setState(() => impressaoNormal = v ?? false),
                      title: const Text('Imprime normalmente'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: impressaoFalhas,
                      onChanged: (v) =>
                          setState(() => impressaoFalhas = v ?? false),
                      title: const Text('Imprime mas com falhas (faixas, manchas)'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: impressaoLenta,
                      onChanged: (v) =>
                          setState(() => impressaoLenta = v ?? false),
                      title: const Text('Imprime lentamente'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: impressaoNaoImprime,
                      onChanged: (v) =>
                          setState(() => impressaoNaoImprime = v ?? false),
                      title: const Text('Não imprime'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: impressaoErroSemPapel,
                      onChanged: (v) => setState(
                        () => impressaoErroSemPapel = v ?? false,
                      ),
                      title: const Text(
                        'Erro de "sem papel" quando há papel',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: impressaoErroSemToner,
                      onChanged: (v) => setState(
                        () => impressaoErroSemToner = v ?? false,
                      ),
                      title: const Text(
                        'Erro de "sem toner/cartucho" quando está instalado',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.3 Qualidade de Impressão:'),
                    CheckboxListTile(
                      value: qualidadeSemManchas,
                      onChanged: (v) =>
                          setState(() => qualidadeSemManchas = v ?? false),
                      title: const Text('Sem manchas ou borrões'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: qualidadeLetrasFaltando,
                      onChanged: (v) =>
                          setState(() => qualidadeLetrasFaltando = v ?? false),
                      title: const Text('Letras/pixels faltando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: qualidadeEsmaecida,
                      onChanged: (v) =>
                          setState(() => qualidadeEsmaecida = v ?? false),
                      title: const Text('Impressão esmaecida'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: qualidadeCoresErradas,
                      onChanged: (v) =>
                          setState(() => qualidadeCoresErradas = v ?? false),
                      title: const Text('Cores erradas (no colorido)'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: qualidadeEtiquetaDesalinhada,
                      onChanged: (v) => setState(
                        () => qualidadeEtiquetaDesalinhada = v ?? false,
                      ),
                      title: const Text('Etiqueta desalinhada (na etiquetadora)'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: qualidadeCorteAutoFuncional,
                      onChanged: (v) => setState(
                        () => qualidadeCorteAutoFuncional = v ?? false,
                      ),
                      title: const Text('Corte automático funcional'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 8),
                    const Text('3.4 Rede / Conectividade:'),
                    CheckboxListTile(
                      value: redeUsbFunc,
                      onChanged: (v) =>
                          setState(() => redeUsbFunc = v ?? false),
                      title: const Text('USB funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: redeEthernetFunc,
                      onChanged: (v) =>
                          setState(() => redeEthernetFunc = v ?? false),
                      title: const Text('Ethernet funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: redeWifiFunc,
                      onChanged: (v) =>
                          setState(() => redeWifiFunc = v ?? false),
                      title: const Text('Wi-Fi funcionando'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: redeVisivelServidor,
                      onChanged: (v) =>
                          setState(() => redeVisivelServidor = v ?? false),
                      title: const Text('Impressora visível no servidor ou rede'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '4. Testes Realizados',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      value: testeDriver,
                      onChanged: (v) =>
                          setState(() => testeDriver = v ?? false),
                      title: const Text(
                        'Verificação de driver instalado e atualizado',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeImpressaoSimples,
                      onChanged: (v) => setState(
                        () => testeImpressaoSimples = v ?? false,
                      ),
                      title: const Text('Teste de impressão simples'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeQualidade,
                      onChanged: (v) =>
                          setState(() => testeQualidade = v ?? false),
                      title: const Text(
                        'Teste de qualidade de impressão (padrão de teste)',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testePaginaDiag,
                      onChanged: (v) =>
                          setState(() => testePaginaDiag = v ?? false),
                      title: const Text(
                        'Impressão de página de diagnóstico (se suportado)',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeBandejasAlimentador,
                      onChanged: (v) => setState(
                        () => testeBandejasAlimentador = v ?? false,
                      ),
                      title: const Text(
                        'Verificação de bandejas e alimentador de mídia',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeSensores,
                      onChanged: (v) =>
                          setState(() => testeSensores = v ?? false),
                      title: const Text(
                        'Verificação de sensores (papel, atolamento)',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: testeRede,
                      onChanged: (v) => setState(() => testeRede = v ?? false),
                      title: const Text('Verificação de rede/conexão'),
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
                      '5. Consumíveis e Manutenção Preventiva',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    CheckboxListTile(
                      value: consTonerValidadeOK,
                      onChanged: (v) =>
                          setState(() => consTonerValidadeOK = v ?? false),
                      title: const Text(
                        'Toner/cartucho está dentro da validade',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: consEtiquetasOK,
                      onChanged: (v) =>
                          setState(() => consEtiquetasOK = v ?? false),
                      title: const Text(
                        'Etiquetas/label-roll sem rasgos ou falhas',
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: consCilindroFusorChecado,
                      onChanged: (v) => setState(
                        () => consCilindroFusorChecado = v ?? false,
                      ),
                      title: const Text('Cilindro/fusor checado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: consCabecaImpressaoLimpa,
                      onChanged: (v) => setState(
                        () => consCabecaImpressaoLimpa = v ?? false,
                      ),
                      title: const Text('Cabeça de impressão limpa (etiquetadora)'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: consBandejasLimpas,
                      onChanged: (v) =>
                          setState(() => consBandejasLimpas = v ?? false),
                      title: const Text('Bandejas limpas e ajustadas'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      value: consFirmwareAtualizado,
                      onChanged: (v) => setState(
                        () => consFirmwareAtualizado = v ?? false,
                      ),
                      title: const Text('Firmware atualizado'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: observacoesConsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Observações (consumíveis/manutenção)',
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      '6. Observações Gerais',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: obsGeraisCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Digite observações gerais',
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
                            initialValue: _selectedTechId,
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
