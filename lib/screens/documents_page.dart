// lib/screens/documents_page.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';
import '../models/glpi_document.dart';
import 'pdf_viewer_page.dart';

class DocumentsPage extends StatefulWidget {
  final String type; // 'Computer' | 'Phone' | 'Printer'
  final int id;

  const DocumentsPage({
    super.key,
    required this.type,
    required this.id,
  });

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final GLPIService _service = GLPIService();
  List<GlpiDocument> _docs = [];
  bool _loading = true;
  String? _error;

  String _itemName = ''; // Hostname/Nome do equipamento

  @override
  void initState() {
    super.initState();
    _load();
    _loadItemName();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  // ========= Carregar lista de documentos =========

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      final d = await _service.listDocumentsForItem(
        type: widget.type,
        id: widget.id,
        sessionToken: session,
      );
      if (!mounted) return;
      setState(() => _docs = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ========= Carregar nome/hostname do item =========

  Future<void> _loadItemName() async {
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      Map<String, String> details;

      if (widget.type == 'Computer') {
        details = await _service.getComputerDetails(
          sessionToken: session,
          id: widget.id,
        );
        _itemName = details['Hostname'] ?? details['Nome'] ?? '';
      } else if (widget.type == 'Phone') {
        details = await _service.getPhoneDetails(
          sessionToken: session,
          id: widget.id,
        );
        _itemName = details['Nome'] ?? '';
      } else if (widget.type == 'Printer') {
        details = await _service.getPrinterDetails(
          sessionToken: session,
          id: widget.id,
        );
        _itemName = details['Nome'] ?? '';
      } else {
        _itemName = '';
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Se der erro, só não usa o nome; cai no fallback (fileName)
      print('⚠️ Erro ao carregar nome do item: $e');
    }
  }

  // Tipo em PT-BR para o título do documento
  String _typeLabel() {
    switch (widget.type) {
      case 'Computer':
        return 'Computador';
      case 'Phone':
        return 'Telefone';
      case 'Printer':
        return 'Impressora';
      default:
        return widget.type;
    }
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ========= UPLOAD =========

  Future<void> _pickAndUploadDocument() async {
    try {
      // Escolher arquivo (apenas PDF por enquanto)
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

      // Se não vier bytes (algumas plataformas), lê do path
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        throw Exception('Não foi possível ler o arquivo selecionado.');
      }

      final session = context.read<AuthProvider>().sessionToken!;

      // Monta o nome padrão do documento
      final tipoLabel = _typeLabel();
      final hostnamePart =
          _itemName.isNotEmpty ? _itemName : fileName; // fallback se não conseguir hostname
      final docName = 'Documento: $tipoLabel - $hostnamePart';

      _showSnack('Enviando documento...', color: Colors.blueGrey);

      // Upload + vínculo ao item atual
      final docId = await _service.uploadAndLinkDocumentToItem(
        sessionToken: session,
        type: widget.type, // 'Computer' | 'Phone' | 'Printer'
        itemId: widget.id,
        fileName: fileName,
        fileBytes: bytes,
        documentName: docName,
      );

      if (!mounted) return;

      _showSnack(
        'Documento enviado e vinculado (ID $docId)',
        color: Colors.green.shade600,
      );

      // Recarrega lista
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Erro ao enviar documento: $e',
        color: Colors.red.shade600,
      );
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
                subtitle: Text(
                  'Vincular ao ${_typeLabel()} ID ${widget.id}'
                  '${_itemName.isNotEmpty ? ' ($_itemName)' : ''}',
                ),
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

  // ========= EXCLUSÃO =========

  void _showDocumentOptions(GlpiDocument d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final displayName =
            d.name.isNotEmpty ? d.name : (d.filename.isNotEmpty ? d.filename : '(sem nome)');
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Excluir documento'),
                subtitle: Text(displayName),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteDocument(d);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteDocument(GlpiDocument d) {
    final displayName =
        d.name.isNotEmpty ? d.name : (d.filename.isNotEmpty ? d.filename : '(sem nome)');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir documento'),
          content: Text(
            'Tem certeza que deseja excluir o documento:\n\n"$displayName"?\n\n'
            'Isso irá removê-lo do GLPI.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteDocument(d);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDocument(GlpiDocument d) async {
    try {
      final session = context.read<AuthProvider>().sessionToken!;
      await _service.deleteDocument(
        sessionToken: session,
        documentId: d.id,
      );

      if (!mounted) return;

      setState(() {
        _docs.removeWhere((doc) => doc.id == d.id);
      });

      _showSnack(
        'Documento excluído com sucesso.',
        color: Colors.green.shade600,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Erro ao excluir documento: $e',
        color: Colors.red.shade600,
      );
    }
  }

  // ========= BUILD =========

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos'),
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
              : _docs.isEmpty
                  ? const Center(child: Text('Sem documentos vinculados.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final d = _docs[i];

                        // Verifica se é PDF
                        final isPdf = d.mime.toLowerCase().contains('pdf') ||
                            d.filename.toLowerCase().endsWith('.pdf');

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isPdf
                                  ? Colors.red.shade50
                                  : Colors.grey.shade200,
                              child: Icon(
                                isPdf
                                    ? Icons.picture_as_pdf
                                    : Icons.description_outlined,
                                color: isPdf
                                    ? Colors.red
                                    : Colors.grey.shade600,
                              ),
                            ),
                            title: Text(
                              d.name.isEmpty ? '(Sem nome)' : d.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (d.filename.isNotEmpty) Text(d.filename),
                                if (d.mime.isNotEmpty)
                                  Text(
                                    d.mime,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                if (d.dateMod.isNotEmpty)
                                  Text(
                                    'Atualizado em: ${d.dateMod}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                if (d.heading.isNotEmpty)
                                  Text(
                                    d.heading,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            trailing: isPdf
                                ? const Icon(Icons.arrow_forward_ios, size: 16)
                                : null,
                            onTap: () {
                              if (isPdf) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PdfViewerPage(
                                      documentId: d.id,
                                      documentName: d.name.isEmpty
                                          ? d.filename
                                          : d.name,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Apenas arquivos PDF podem ser visualizados no momento',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            // Pressionar e segurar => opções (excluir)
                            onLongPress: () => _showDocumentOptions(d),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openFabMenu,
        backgroundColor: purple,
        icon: const Icon(Icons.add),
        label: const Text('Ações'),
      ),
    );
  }
}
