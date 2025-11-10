import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Dica: substitua por um fluxo de input seguro (ex.: storage seguro)
  static const String _userToken = 'HXPhlV3YQyvvfNhRFXLAlfdcF4DGoEbSNqN7k101';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.authenticate(userToken: _userToken);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (_) {
      if (!mounted) return;
      final msg = context.read<AuthProvider>().message ?? 'Falha ao autenticar.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      // Permite tentar novamente com um toque longo, por exemplo
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isAuthenticating;

    return Scaffold(
      backgroundColor: const Color(0xFF522583),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent, size: 96, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'GLPI App',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const CircularProgressIndicator(color: Colors.white)
            else
              ElevatedButton(
                onPressed: _bootstrap,
                child: const Text('Tentar autenticar novamente'),
              ),
            const SizedBox(height: 12),
            const Text(
              'Validando sessão com o GLPI...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
