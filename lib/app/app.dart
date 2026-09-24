import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/utils/app_messenger.dart';
import '../features/main_navigation/presentation/main_navigation_screen.dart';
import 'theme/app_theme.dart';

class MiruApp extends StatelessWidget {
  const MiruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Miru',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en'),
      ],
      locale: const Locale('zh', 'CN'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigationScreen(),
    );
  }
}
