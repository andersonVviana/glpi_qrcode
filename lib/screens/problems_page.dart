// lib/screens/problems_page.dart
import 'package:flutter/material.dart';
import 'package:glpi_flutter_app/screens/assistencia_tecnica_printer_page.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';
import 'assistencia_tecnica_page.dart';
import 'assistencia_tecnica_phone_page.dart';

class ProblemsPage extends StatefulWidget {
  final String type; // 'Computer' | 'Phone' | 'Printer'
  final int id;
  final String hostname;
  final String
  tipoComputador; // para Computer: tipo; Phone: modelo; Printer: modelo
  final String serial; // para Computer/Printer: serial; Phone: IMEI/serial

  const ProblemsPage({
    super.key,
    required this.type,
    required this.id,
    required this.hostname,
    required this.tipoComputador,
    required this.serial,
  });

  @override
  State<ProblemsPage> createState() => _ProblemsPageState();
}

class _ProblemsPageState extends State<ProblemsPage> {
  final _service = GLPIService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _problems = [];

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
      final list = await _service.listProblemsForItem(
        type: widget.type,
        id: widget.id,
        sessionToken: session,
      );
      if (!mounted) return;
      setState(() => _problems = list.cast<Map<String, dynamic>>());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusLabel(dynamic v) {
    final id = v is int ? v : int.tryParse('$v') ?? 0;
    switch (id) {
      case 1:
        return 'Novo';
      case 2:
        return 'Em andamento';
      case 3:
        return 'Pendente';
      case 4:
        return 'Resolvido';
      case 5:
        return 'Fechado';
      default:
        return 'Status $id';
    }
  }

  Future<void> _deleteProblemWithConfirm(Map<String, dynamic> p) async {
    final pidRaw = p['id'];
    final problemId = pidRaw is int
        ? pidRaw
        : int.tryParse('$pidRaw'.trim()) ?? 0;

    if (problemId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID do problema inválido, não foi possível excluir.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir problema'),
        content: const Text(
          'Deseja excluir permanentemente este problema do GLPI?\n'
          'Esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final session = context.read<AuthProvider>().sessionToken!;
      await _service.deleteProblemPermanently(
        problemId: problemId,
        sessionToken: session,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problema excluído permanentemente.'),
          backgroundColor: Colors.green,
        ),
      );

      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir problema: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Problemas do Equipamento'),
        backgroundColor: Colors.white,
        foregroundColor: purple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Erro: $_error'),
              ),
            )
          : _problems.isEmpty
          ? const Center(child: Text('Nenhum problema registrado.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _problems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = _problems[i];
                final name = (p['name'] ?? '').toString();
                final status = _statusLabel(p['status']);
                final date = (p['date_mod'] ?? p['date_creation'] ?? '')
                    .toString();

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _deleteProblemWithConfirm(p),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(
                          Icons.report_problem,
                          color: Colors.deepOrange,
                        ),
                      ),
                      title: Text(
                        name.isEmpty ? '(Sem título)' : name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: $status'),
                          if (date.isNotEmpty)
                            Text(
                              'Atualizado em: $date',
                              style: const TextStyle(color: Colors.black54),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Widget page;

          if (widget.type == 'Phone') {
            page = AssistenciaTecnicaPhonePage(
              type: widget.type, // 'Phone'
              id: widget.id,
              hostname: widget.hostname,
              modelo: widget.tipoComputador, // modelo do telefone
              imeiOuSerial: widget.serial, // IMEI/serial
            );
          } else if (widget.type == 'Printer') {
            page = AssistenciaTecnicaPrinterPage(
              type: widget.type, // 'Printer'
              id: widget.id,
              hostname: widget.hostname,
              modelo: widget.tipoComputador, // modelo da impressora
              serial: widget.serial, // serial
            );
          } else {
            // Computer
            page = AssistenciaTecnicaPage(
              type: widget.type, // 'Computer'
              id: widget.id,
              hostname: widget.hostname,
              tipoComputador: widget.tipoComputador,
              serial: widget.serial,
            );
          }

          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => page),
          );

          if (created == true) {
            await _load();
          }
        },
        backgroundColor: purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
