import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/study_provider.dart';
import 'screens/splash_screen.dart';

import 'package:flutter/foundation.dart'; // Added for kIsWeb

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // 🔥 FOR CHROME / WEB: Web keys synced from google-services.json
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDlb9obW7FYhNB-Zlgdr_Ugsudhc69eCo0",
        appId: "1:21286114771:android:5e048fddffac08433d0b26",
        messagingSenderId: "21286114771",
        projectId: "ai-study-planner-3ef4b",
      ),
    );
  } else {
    // FOR ANDROID: It uses the google-services.json file automatically!
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth state — always alive
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        // Study data — re-initialised whenever the logged-in user changes
        ChangeNotifierProxyProvider<AuthProvider, StudyProvider>(
          create: (_) => StudyProvider(),
          update: (_, auth, study) {
            if (auth.isLoggedIn && auth.user != null) {
              study!.init(auth.user!.uid);
            } else {
              study!.resetUser();
            }
            return study;
          },
        ),
      ],
      child: MaterialApp(
        title: 'AI Study Planner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}