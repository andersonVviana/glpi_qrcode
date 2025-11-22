// lib/screens/details_computer.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:glpi_flutter_app/screens/documents_page.dart';
import 'package:glpi_flutter_app/screens/problems_page.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';
import '../widgets/inventory_action_sheet.dart';

class DetailsComputerPage extends StatefulWidget {
  final int id;
  const DetailsComputerPage({super.key, required this.id});

  @override
  State<DetailsComputerPage> createState() => _DetailsComputerPageState();
}

class _DetailsComputerPageState extends State<DetailsComputerPage> {
  final GLPIService _service = GLPIService();

  Map<String, String>? _data;
  Map<String, String>? _inv; // inventário do ano atual
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      final map = await _service.getComputerDetails(
        sessionToken: session,
        id: widget.id,
      );
      final inv = await _service.getCurrentYearInventoryInfo(
        type: 'Computer',
        id: widget.id,
        sessionToken: session,
      );
      if (!mounted) return;
      setState(() {
        _data = map;
        _inv = inv; // pode ser null
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
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
              type: 'Computer',
              id: widget.id,
              sessionToken: session,
              userName: userName,
            );
            if (!mounted) return;
            _changed = true; // 👈 houve alteração
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Inventário Criado'),
                backgroundColor: Colors.green.shade600,
              ),
            );
            await _load(); // recarrega para mostrar Nome / DataHora
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro: $e'),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteInventory() async {
    final session = context.read<AuthProvider>().sessionToken!;
    final year = DateTime.now().year.toString();

    // Primeiro verifica se existe inventário
    final inv = await _service.getCurrentYearInventoryInfo(
      type: 'Computer',
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
        type: 'Computer',
        id: widget.id,
        sessionToken: session,
      );
      if (!mounted) return;
      _changed = true; // 👈 houve alteração
      _inv = null;
      _showSnack(
        'Inventário do ano atual removido.',
        color: Colors.green.shade600,
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro: ${e.toString()}', color: Colors.red.shade600);
    }
  }

  // ========================= UPLOAD DOCUMENTO (opcional) =========================

  Future<void> _pickAndUploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // usuário cancelou
      }

      final file = result.files.single;
      final fileName = file.name;
      List<int>? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        throw Exception('Não foi possível ler o arquivo selecionado.');
      }

      final session = context.read<AuthProvider>().sessionToken!;
      _showSnack('Enviando documento...', color: Colors.blueGrey);

      final docId = await _service.uploadAndLinkDocumentToItem(
        sessionToken: session,
        type: 'Computer',
        itemId: widget.id,
        fileName: fileName,
        fileBytes: bytes,
        documentName: fileName,
      );

      if (!mounted) return;

      _showSnack(
        'Documento enviado e vinculado (ID $docId)',
        color: Colors.green.shade600,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro ao enviar documento: $e', color: Colors.red.shade600);
    }
  }

  void _openFabMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload de documento para o GLPI'),
                subtitle: const Text('Vincular documento a este computador'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return WillPopScope(
      onWillPop: () async {
        // Ao voltar, avisa a tela anterior se houve alteração de inventário
        Navigator.of(context).pop(_changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes - Computador'),
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
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Erro: $_error'),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _header(
                        _data?['Hostname'] ?? _data?['Nome'] ?? '(Sem nome)',
                      ),
                      const SizedBox(height: 12),
                      if (_data != null) _kvCard(_data!),
                      const SizedBox(height: 16),
                      _inventorySection(),
                      const SizedBox(height: 16),

                      // ===== Botões lado a lado: Inventário | Documentos | Problemas =====
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openInventorySheet,
                              icon: const Icon(Icons.inventory_2_outlined),
                              label: const Text(
                                'Inventário',
                                softWrap: false,
                                overflow: TextOverflow.fade,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: purple,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final hostname =
                                    _data?['Hostname'] ?? _data?['Nome'] ?? '(Sem nome)';
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DocumentsPage(
                                      type: 'Computer',
                                      id: widget.id,
                                      hostname: hostname,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.folder_open),
                              label: const Text(
                                'Documentos',
                                softWrap: false,
                                overflow: TextOverflow.fade,
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                side: const BorderSide(color: purple),
                                foregroundColor: purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProblemsPage(
                                      type: 'Computer',
                                      id: widget.id,
                                      hostname: _data?['Hostname'] ??
                                          _data?['Nome'] ??
                                          '',
                                      tipoComputador: _data?['Modelo'] ?? '',
                                      serial: _data?['Serial'] ?? '',
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                side: const BorderSide(color: purple),
                                foregroundColor: purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
        // Se quiser usar o FAB de upload em algum momento:
        // floatingActionButton: FloatingActionButton(
        //   onPressed: _openFabMenu,
        //   backgroundColor: purple,
        //   child: const Icon(Icons.upload_file),
        // ),
      ),
    );
  }

  // ---------------- UI Helpers ----------------

  Widget _header(String title) {
    const purple = Color(0xFF522583);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: purple.withOpacity(0.1),
          child: const Icon(Icons.computer_rounded, color: purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _kvCard(Map<String, String> map) {
    final entries = map.entries
        // 👇 remove Observações e campos vazios
        .where(
          (e) =>
              e.key != 'Observações' &&
              (e.value).trim().isNotEmpty,
        )
        .toList();

    final order = <String>[
      'Hostname',
      'Status',
      'Fabricante',
      'Modelo',
      'Serial',
      'Usuário',
      'Localização',
      'Sistema Oper.',
      'Domínio',
      'UUID',
      'Asset Tag',
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

  Widget _kvRow(String k, String v) {
    return Padding(
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
  }

  // --------- Seção “Inventário” ---------
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
}
