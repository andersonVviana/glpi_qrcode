import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';
import '../widgets/inventory_action_sheet.dart';
import 'documents_page.dart';
import 'problems_page.dart';

class DetailsPrinterPage extends StatefulWidget {
  final int id;

  const DetailsPrinterPage({super.key, required this.id});

  @override
  State<DetailsPrinterPage> createState() => _DetailsPrinterPageState();
}

class _DetailsPrinterPageState extends State<DetailsPrinterPage> {
  final GLPIService _service = GLPIService();

  Map<String, String>? _data;
  Map<String, String>? _inv; // {nome, dataHora, ano}
  bool _loading = true;
  String? _error;

  bool _changed = false; // 👈 se inventário foi alterado (criado/atualizado/excluído)

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color color = Colors.black87}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = context.read<AuthProvider>().sessionToken!;
      final map = await _service.getPrinterDetails(
        sessionToken: session,
        id: widget.id,
      );
      final inv = await _service.getCurrentYearInventoryInfo(
        type: 'Printer',
        id: widget.id,
        sessionToken: session,
      );

      if (!mounted) return;
      setState(() {
        _data = map;
        _inv = inv;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openInventorySheet() async {
    final session = context.read<AuthProvider>().sessionToken!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => InventoryActionSheet(
        sessionToken: session,
        onConfirm: (userName) async {
          try {
            await _service.createOrUpdateInventory(
              type: 'Printer',
              id: widget.id,
              sessionToken: session,
              userName: userName,
            );
            if (!mounted) return;
            _changed = true;
            _showSnack(
              'Inventário registrado com sucesso.',
              color: Colors.green.shade600,
            );
            await _load();
          } catch (e) {
            if (!mounted) return;
            _showSnack(
              'Erro ao registrar inventário: $e',
              color: Colors.red.shade600,
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteInventory() async {
    final session = context.read<AuthProvider>().sessionToken!;
    final year = DateTime.now().year.toString();

    // Garante que ainda existe inventário para o ano atual
    final inv = await _service.getCurrentYearInventoryInfo(
      type: 'Printer',
      id: widget.id,
      sessionToken: session,
    );

    if (inv == null) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Inventário'),
          content: const Text(
            'Não há inventário para o ano atual para excluir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir inventário'),
        content: Text(
          'Tem certeza que deseja excluir o inventário do ano ${inv['ano'] ?? year}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteCurrentYearInventory(
        type: 'Printer',
        id: widget.id,
        sessionToken: session,
      );

      if (!mounted) return;
      _changed = true;
      setState(() {
        _inv = null;
      });

      _showSnack(
        'Inventário do ano atual excluído.',
        color: Colors.green.shade600,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Erro ao excluir inventário: $e',
        color: Colors.red.shade600,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes - Impressora'),
          backgroundColor: Colors.white,
          foregroundColor: purple,
          actions: [
            IconButton(
              tooltip: 'Excluir inventário (ano atual)',
              onPressed: _deleteInventory,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Erro: $_error'))
                : _data == null
                    ? const Center(child: Text('Dados não encontrados.'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _header(_data!['Nome'] ?? '(Sem nome)'),
                          const SizedBox(height: 12),
                          _kvCard(_data!),
                          const SizedBox(height: 16),
                          _inventorySection(),
                          const SizedBox(height: 16),
                          _actionsRow(context),
                        ],
                      ),
      ),
    );
  }

  Widget _header(String title) => Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF522583).withOpacity(0.1),
            child:
                const Icon(Icons.print_rounded, color: Color(0xFF522583)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _kvCard(Map<String, String> map) {
    final entries = map.entries
        .where(
          (e) =>
              e.key != 'Observações' && e.value.trim().isNotEmpty,
        )
        .toList();

    final order = <String>[
      'Nome',
      'Status',
      'Fabricante',
      'Modelo',
      'Serial',
      'End. IP',
      'Usuário',
      'Localização',
      'Criado em',
      'Atualizado em',
      'ID',
      'Tipo',
    ];

    entries.sort((a, b) {
      final ia = order.indexOf(a.key);
      final ib = order.indexOf(b.key);
      if (ia == -1 && ib == -1) return a.key.compareTo(b.key);
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: entries.map((e) => _kvRow(e.key, e.value)).toList(),
        ),
      ),
    );
  }

  Widget _kvRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                k,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Widget _inventorySection() {
    const purple = Color(0xFF522583);
    final year = DateTime.now().year.toString();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventário',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_inv == null)
              Text(
                'Sem inventário para este ano ($year)',
                style: TextStyle(color: Colors.grey.shade700),
              )
            else ...[
              _kvRow('Nome', _inv!['nome'] ?? '-'),
              _kvRow('Data e Hora', _inv!['dataHora'] ?? '-'),
              _kvRow('Ano', _inv!['ano'] ?? year),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openInventorySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: Text(
                      _inv == null
                          ? 'Registrar inventário'
                          : 'Atualizar inventário',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _inv == null ? null : _deleteInventory,
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                  ),
                  tooltip: 'Excluir inventário do ano atual',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionsRow(BuildContext context) {
    const purple = Color(0xFF522583);
    final nome = _data?['Nome'] ?? '(Sem nome)';
    final modelo = _data?['Modelo'] ?? '';
    final serial = _data?['Serial'] ?? '';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentsPage(
                    type: 'Printer',
                    id: widget.id,
                    hostname: nome,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.description_outlined),
            label: const Text(
              'Documentos',
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: const BorderSide(color: purple),
              foregroundColor: purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProblemsPage(
                    type: 'Printer',
                    id: widget.id,
                    hostname: nome,
                    tipoComputador: modelo,
                    serial: serial,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text(
              'Problemas',
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: const BorderSide(color: purple),
              foregroundColor: purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
