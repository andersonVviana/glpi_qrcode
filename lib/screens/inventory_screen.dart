import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';
import '../models/inventory_item.dart';

// Telas de detalhes
import 'details_computer.dart';
import 'details_phone.dart';
import 'details_printer.dart';

enum InvTab { all, computers, phones, printers }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final GLPIService _service = GLPIService();

  InvTab _current = InvTab.all;
  List<InventoryItem> _items = [];
  bool _loading = false;
  String? _error;

  // 👇 Novo: mapa de "tem inventário" por item (chave: type-id)
  Map<String, bool> _hasInventory = {};

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load());
  }

  String _itemKey(InventoryItem it) => '${it.type}-${it.id}';

  Future<void> _load() async {
    final sessionToken = context.read<AuthProvider>().sessionToken;
    if (sessionToken == null || sessionToken.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final q = _searchCtrl.text.trim();
      final List<InventoryItem> result = [];

      if (_current == InvTab.all || _current == InvTab.computers) {
        result.addAll(
          await _service.listComputers(sessionToken: sessionToken, search: q),
        );
      }
      if (_current == InvTab.all || _current == InvTab.phones) {
        result.addAll(
          await _service.listPhones(sessionToken: sessionToken, search: q),
        );
      }
      if (_current == InvTab.all || _current == InvTab.printers) {
        result.addAll(
          await _service.listPrinters(sessionToken: sessionToken, search: q),
        );
      }

      // Ordena por tipo e hostname
      result.sort((a, b) {
        final t = a.type.compareTo(b.type);
        return t != 0
            ? t
            : a.hostname.toLowerCase().compareTo(b.hostname.toLowerCase());
      });

      // 👇 Novo: checar inventário atual para cada item
      final futures = <Future<MapEntry<String, bool>>>[];
      for (final it in result) {
        futures.add(() async {
          final info = await _service.getCurrentYearInventoryInfo(
            type: it.type,
            id: it.id,
            sessionToken: sessionToken,
          );
          return MapEntry(_itemKey(it), info != null);
        }());
      }

      final entries = await Future.wait(futures);
      final invMap = <String, bool>{for (final e in entries) e.key: e.value};

      if (!mounted) return;
      setState(() {
        _items = result;
        _hasInventory = invMap;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===== Segmented bar (1 linha, responsivo) =====

  String _fullLabel(InvTab t) {
    switch (t) {
      case InvTab.all:
        return 'Todos';
      case InvTab.computers:
        return 'Computadores';
      case InvTab.phones:
        return 'Telefones';
      case InvTab.printers:
        return 'Impressoras';
    }
  }

  String _shortLabel(InvTab t) {
    switch (t) {
      case InvTab.all:
        return 'Todos';
      case InvTab.computers:
        return 'PCs';
      case InvTab.phones:
        return 'Fones';
      case InvTab.printers:
        return 'Impr.';
    }
  }

  Widget _segment(BuildContext context, InvTab tab) {
    const purple = Color(0xFF522583);
    final selected = _current == tab;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final label = w < 92 ? _shortLabel(tab) : _fullLabel(tab);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _current = tab);
              _load();
            },
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? purple : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? purple : Colors.grey.shade400,
                ),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected)
                    const Icon(Icons.check, size: 16, color: Colors.white),
                  if (selected) const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: w < 92 ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topo rente ao status bar
        SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  _segment(context, InvTab.all),
                  const SizedBox(width: 8),
                  _segment(context, InvTab.computers),
                  const SizedBox(width: 8),
                  _segment(context, InvTab.phones),
                  const SizedBox(width: 8),
                  _segment(context, InvTab.printers),
                ],
              ),
            ),
          ),
        ),

        // Busca
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por hostname ou serial...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onSubmitted: (_) => _load(),
          ),
        ),

        // Lista
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erro: $_error'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _items.length,
                  itemBuilder: (context, i) {
                    final it = _items[i];
                    final hasInv = _hasInventory[_itemKey(it)] ?? false;
                    return _InventoryCard(
                      item: it,
                      hasInventory: hasInv,
                      onNeedReload:
                          _load, // 👈 recarrega ao voltar dos detalhes
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// =============================== INVENTORY CARD ===============================

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final bool hasInventory;
  final VoidCallback onNeedReload;

  const _InventoryCard({
    required this.item,
    required this.hasInventory,
    required this.onNeedReload,
  });

  IconData _icon() {
    switch (item.type) {
      case 'Computer':
        return Icons.computer_rounded;
      case 'Phone':
        return Icons.phone_iphone_rounded;
      case 'Printer':
        return Icons.print_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  // ---- Status: mapeia ID → nome/cor ----
  String _statusName(String? value) {
    if (value == null || value.isEmpty) return '-';
    switch (value) {
      case '1':
        return 'Ativo';
      case '2':
        return 'Assistência Técnica';
      case '4':
        return 'Disponível';
      case '5':
        return 'Em Análise';
      case '8':
        return 'Descarte';
      default:
        return 'Desconhecido';
    }
  }

  Color _statusColor(String? value) {
    switch (value) {
      case '1':
        return Colors.green.shade600; // Ativo
      case '2':
        return Colors.orange.shade600; // Assistência Técnica
      case '4':
        return Colors.purple.shade700; // Disponível
      case '5':
        return Colors.blue.shade700; // Em análise
      case '8':
        return Colors.red.shade600; // Descarte
      default:
        return Colors.grey.shade500; // Outros
    }
  }

  void _openDetails(BuildContext context) async {
    dynamic result;

    switch (item.type) {
      case 'Computer':
        result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsComputerPage(id: item.id)),
        );
        break;
      case 'Phone':
        result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsPhonePage(id: item.id)),
        );
        break;
      case 'Printer':
        result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsPrinterPage(id: item.id)),
        );
        break;
      default:
        return;
    }

    // Se a tela de detalhes retornar "true", recarrega a lista
    if (result == true) {
      onNeedReload();
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    final statusName = _statusName(item.status);
    final statusColor = _statusColor(item.status);

    return InkWell(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (ícone + hostname + inventário + status)
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: purple.withOpacity(0.12),
                    child: Icon(_icon(), color: purple),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.hostname.isEmpty
                                ? '(Sem hostname)'
                                : item.hostname,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasInventory) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Campos principais
              _kv('Fabricante', item.manufacturer),
              _kv('Modelo', item.model),
              _kv('Serial', item.serial),
              _kv('Usuário', item.userName),
              _kv('Localização', item.location),

              const SizedBox(height: 10),

              // Ação: Ver detalhes
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openDetails(context),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Ver detalhes'),
                  style: TextButton.styleFrom(foregroundColor: purple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              k,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(v.isEmpty ? '-' : v)),
        ],
      ),
    );
  }
}
