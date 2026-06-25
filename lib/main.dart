import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'providers/app_state_provider.dart';
import 'theme/app_theme.dart';
import 'views/login_view.dart';
import 'views/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI database factory for desktop applications
  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppStateProvider>(
      create: (_) => AppStateProvider()..init(),
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'PickleQ',
            theme: AppTheme.themeData,
            debugShowCheckedModeBanner: false,
            home: appState.isLoading
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: AppTheme.neonLime),
                    ),
                  )
                : appState.isAuthenticated
                    ? const MainLayout()
                    : const LoginView(),
          );
        },
      ),
    );
  }
}
