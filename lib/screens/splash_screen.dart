import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _userToken = 'X9edb4od2YTLC0pHoN9WYtyHek7qXnRjzsbLNuzg';
  
  String _statusMessage = 'Validando sessão com o GLPI...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // 👇 MUDANÇA: Use WidgetsBinding para executar após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    
    setState(() {
      _statusMessage = 'Conectando ao servidor...';
      _hasError = false;
    });

    final auth = context.read<AuthProvider>();
    
    try {
      print('🚀 Iniciando autenticação...');
      print('🔑 User Token (primeiros 10 caracteres): ${_userToken.substring(0, 10)}...');
      
      setState(() {
        _statusMessage = 'Autenticando...';
      });
      
      await auth.authenticate(userToken: _userToken);
      
      print('✅ Autenticação bem-sucedida!');
      
      if (!mounted) return;
      
      setState(() {
        _statusMessage = 'Sucesso! Redirecionando...';
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      
    } catch (e) {
      print('❌ Erro na autenticação: $e');
      
      if (!mounted) return;
      
      final msg = auth.message ?? 'Falha ao autenticar.';
      
      setState(() {
        _statusMessage = msg;
        _hasError = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF522583),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent, size: 96, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'GLPI App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              
              // Remove o Consumer para evitar rebuild durante autenticação
              _hasError
                  ? const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.redAccent,
                    )
                  : const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
              
              const SizedBox(height: 24),
              
              Text(
                _statusMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (_hasError) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _bootstrap,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF522583),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}