import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_2jem/providers/language_provider.dart';
import 'package:app_2jem/providers/user_provider.dart';
import 'package:app_2jem/view_models/job_view_model.dart';
import 'package:app_2jem/views/login_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Firestore persistence on web can sometimes cause "client offline" errors
    // during development if the cache gets corrupted or locked.
    if (kIsWeb) {
      try {
        // Try to enable multi-tab persistence first
        await FirebaseFirestore.instance.enablePersistence(
          const PersistenceSettings(synchronizeTabs: true),
        );
      } catch (e) {
        // If that fails (e.g. "unimplemented" or "failed to initialize"),
        // we fallback to disabling persistence entirely for this session.
        // This ensures the app can at least connect to the internet.
        try {
          // We might need to terminate to clear any hung connection attempts
          // before disabling persistence.
          await FirebaseFirestore.instance.terminate();
          await FirebaseFirestore.instance.clearPersistence();

          // Re-initializing the instance with persistence disabled isn't a direct API,
          // but catching the error usually allows the default (memory-only)
          // persistence to take over on next access.
          print("Persistence failed, running in memory-only mode: $e");
        } catch (e2) {
          print("Double fault on persistence handling: $e2");
        }
      }
    }
    // -----------------------------------

    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(child: Text("Startup Error: $e")),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JobViewModel()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: '2JEM',
            locale: languageProvider.currentLocale,
            theme: ThemeData(
              // Changed primary swatch to Blue
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              colorScheme: ColorScheme.fromSeed(
                // A professional corporate blue seed color
                seedColor: const Color(0xFF1565C0),
                brightness: Brightness.light,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              appBarTheme: const AppBarTheme(
                // Matching blue for the AppBar
                backgroundColor: Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 2,
              ),
            ),
            home: const LoginPage(),
          );
        },
      ),
    );
  }
}
