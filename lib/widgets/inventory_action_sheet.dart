import 'package:flutter/material.dart';

typedef InventoryCallback = Future<void> Function(String userName);

class InventoryActionSheet extends StatefulWidget {
  final InventoryCallback onConfirm;

  const InventoryActionSheet({super.key, required this.onConfirm});

  @override
  State<InventoryActionSheet> createState() => _InventoryActionSheetState();
}

class _InventoryActionSheetState extends State<InventoryActionSheet> {
  static const List<String> _users = [
    'Anderson Viana',
    'Henrique Massayuki',
    'Felipe Albuquerque',
    'Ana Souza',
    'Nicolli Leite',
    'Sergio Cotrim',
  ];

  String _selected = 'Anderson Viana';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Inventário Físico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Seletor de nome
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
                  onChanged: _loading ? null : (v) => setState(() => _selected = v!),
                  items: _users.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botões
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
                    style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white),
                    onPressed: _loading ? null : () async {
                      setState(() => _loading = true);
                      try {
                        await widget.onConfirm(_selected);
                        if (!mounted) return;
                        Navigator.pop(context);
                      } finally {
                        if (mounted) setState(() => _loading = false);
                      }
                    },
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
