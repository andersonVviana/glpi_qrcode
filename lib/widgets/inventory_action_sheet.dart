import 'package:flutter/material.dart';
import 'package:glpi_flutter_app/services/glpi_service.dart';

typedef InventoryCallback = Future<void> Function(String userName);

class InventoryActionSheet extends StatefulWidget {
  final InventoryCallback onConfirm;
  final String sessionToken; // 👈 para buscar no GLPI

  const InventoryActionSheet({
    super.key,
    required this.onConfirm,
    required this.sessionToken,
  });

  @override
  State<InventoryActionSheet> createState() => _InventoryActionSheetState();
}

class _InventoryActionSheetState extends State<InventoryActionSheet> {
  final GLPIService _service = GLPIService();

  List<String> _users = [];
  String? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsersFromGroupTI();
  }

  Future<void> _loadUsersFromGroupTI() async {
    setState(() {
      _loading = true;
    });

    try {
      final techs = await _service.listUsersFromGroupTI(
        sessionToken: widget.sessionToken,
      );

      final names = <String>[];
      for (final u in techs) {
        final realname = (u['realname'] ?? '').toString().trim();
        final firstname = (u['firstname'] ?? '').toString().trim();
        final login = (u['name'] ?? '').toString().trim();

        String display =
            [realname, firstname].where((s) => s.isNotEmpty).join(' ');
        if (display.isEmpty) display = login;
        if (display.isEmpty) display = '(sem nome)';
        names.add(display);
      }

      if (!mounted) return;
      setState(() {
        _users = names;
        _selected = _users.isNotEmpty ? _users.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar usuários do grupo TI: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de puxar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Inventário Físico',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              )
            else if (_users.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Nenhum usuário encontrado no grupo TI.',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selected,
                    isExpanded: true,
                    onChanged: (v) {
                      setState(() => _selected = v);
                    },
                    items: _users
                        .map(
                          (u) => DropdownMenuItem<String>(
                            value: u,
                            child: Text(u),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _loading || _users.isEmpty
                        ? null
                        : () async {
                            if (_selected == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Selecione quem está realizando o inventário.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setState(() => _loading = true);
                            try {
                              await widget.onConfirm(_selected!);
                              if (!mounted) return;
                              Navigator.pop(context);
                            } finally {
                              if (mounted) setState(() => _loading = false);
                            }
                          },
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
