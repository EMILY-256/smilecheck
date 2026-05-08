import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/scan_provider.dart';
import 'services/ai_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? modelLoadError;
  AiService? aiService;
  try {
    aiService = AiService();
    await aiService.loadModel();
    print("✅ AI model loaded");
  } catch (e) {
    print("❌ Failed to load model: $e");
    modelLoadError = e.toString();
  }

  runApp(MyApp(aiService: aiService, modelLoadError: modelLoadError));
}

class MyApp extends StatelessWidget {
  final AiService? aiService;
  final String? modelLoadError;
  const MyApp({super.key, this.aiService, this.modelLoadError});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
            create: (_) => ScanProvider(aiService: aiService)),
      ],
      child: MaterialApp(
        title: 'SmileCheck',
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
        home: modelLoadError != null
            ? Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Model Initialization Failed',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(modelLoadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            // Reload the app – simple restart (for development)
                            // Note: reassemble() removed as it's not available on BuildContext
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.user != null) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}
