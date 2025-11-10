import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';

class DetailsPhonePage extends StatefulWidget {
  final int id;
  const DetailsPhonePage({super.key, required this.id});

  @override
  State<DetailsPhonePage> createState() => _DetailsPhonePageState();
}

class _DetailsPhonePageState extends State<DetailsPhonePage> {
  final GLPIService _service = GLPIService();
  Map<String, String>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      final map = await _service.getPhoneDetails(sessionToken: session, id: widget.id);
      setState(() {
        _data = map;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes - Telefone'),
        backgroundColor: Colors.white,
        foregroundColor: purple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erro: $_error'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _header(_data?['Nome'] ?? '(Sem nome)'),
                    const SizedBox(height: 12),
                    _kvCard(_data!),
                  ],
                ),
    );
  }

  Widget _header(String title) => Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF522583).withOpacity(0.1),
            child: const Icon(Icons.phone_iphone_rounded, color: Color(0xFF522583)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      );

  Widget _kvCard(Map<String, String> map) {
    final entries = map.entries.where((e) => e.value.trim().isNotEmpty).toList();
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
            SizedBox(width: 120, child: Text(k, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
            const SizedBox(width: 8),
            Expanded(child: Text(v)),
          ],
        ),
      );
}
