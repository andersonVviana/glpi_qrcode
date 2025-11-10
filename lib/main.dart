import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'services/glpi_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Define estilo global do Status Bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFFF4F3F8),        // mesma cor do fundo
    statusBarIconBrightness: Brightness.dark, // ícones escuros (Android)
    statusBarBrightness: Brightness.light,    // iOS
  ));

  runApp(const GlpiApp());
}

class GlpiApp extends StatelessWidget {
  const GlpiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(GLPIService()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GLPI Flutter App',

        // 🔹 Tema global do app
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF4F3F8), // fundo padrão claro
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF522583), // roxo Arcade Beauty
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF4F3F8),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Color(0xFFF4F3F8),
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
          ),
        ),

        // 🔹 Rotas
        routes: {
          '/': (_) => const SplashScreen(),
          '/home': (_) => const HomeScreen(),
        },
        initialRoute: '/',
      ),
    );
  }
}
