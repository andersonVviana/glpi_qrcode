import 'package:flutter/material.dart';

class QrCodeScannerScreen extends StatelessWidget {
  const QrCodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leitor de QR Code')),
      body: const Center(
        child: Icon(Icons.qr_code_scanner, size: 120, color: Colors.grey),
      ),
    );
  }
}
