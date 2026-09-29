import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kut' al-takrar fi al-te'reef
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: kIsWeb
            ? const FirebaseOptions(
                apiKey: "AIzaSyDauIgpKO8_O4GGcrUVdx9wSjejE4f-PoU",
                authDomain: "prepmateai-cc161.firebaseapp.com",
                projectId: "prepmateai-cc161",
                storageBucket: "prepmateai-cc161.firebasestorage.app",
                messagingSenderId: "212543200056",
                appId: "1:212543200056:web:28980e9d502a0f5a70ffcd",
                measurementId: "G-KPM5KC298Y",
              )
            : null,
      );
    } catch (e) {
      debugPrint('Firebase Initialization Error: $e');
    }
  }

  runApp(const PrepMateApp());
}

class PrepMateApp extends StatelessWidget {
  const PrepMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'PrepMate AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
