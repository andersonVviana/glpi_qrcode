// lib/screens/pdf_viewer_page.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../providers/auth_provider.dart';
import '../services/glpi_service.dart';

class PdfViewerPage extends StatefulWidget {
  final int documentId;
  final String documentName;

  const PdfViewerPage({
    super.key,
    required this.documentId,
    required this.documentName,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final GLPIService _service = GLPIService();

  Uint8List? _pdfBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Recupera o Session-Token do provider
      final sessionToken = context.read<AuthProvider>().sessionToken;
      if (sessionToken == null || sessionToken.isEmpty) {
        throw Exception('Sessão inválida. Faça login novamente.');
      }

      // Baixa os bytes do documento no GLPI
      final bytes = await _service.downloadDocumentBytes(
        documentId: widget.documentId,
        sessionToken: sessionToken,
      );

      if (!mounted) return;
      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF522583);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentName.isEmpty
              ? 'Visualizar PDF'
              : widget.documentName,
        ),
        backgroundColor: Colors.white,
        foregroundColor: purple,
        actions: [
          if (!_loading && _pdfBytes != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPdf,
              tooltip: 'Recarregar',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Erro ao carregar PDF:\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _pdfBytes == null
                  ? const Center(
                      child: Text('Não foi possível carregar o arquivo PDF.'),
                    )
                  : SfPdfViewer.memory(
                      _pdfBytes!,
                      canShowScrollHead: true,
                      canShowScrollStatus: true,
                    ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
