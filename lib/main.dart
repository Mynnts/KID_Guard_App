import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'logic/providers/auth_provider.dart';

import 'package:workmanager/workmanager.dart';
import 'logic/background_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Kid Guard',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.selectUser,
        routes: AppRoutes.getRoutes(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
