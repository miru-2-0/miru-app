import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/utils/app_messenger.dart';
import '../features/main_navigation/presentation/main_navigation_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_service.dart';

class MiruApp extends StatelessWidget {
  const MiruApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final useDynamic = themeService.useDynamicColor;

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
              theme: AppTheme.lightTheme(useDynamic ? lightDynamic : null),
              darkTheme: AppTheme.darkTheme(useDynamic ? darkDynamic : null),
              themeMode: themeService.flutterThemeMode,
              home: const MainNavigationScreen(),
            );
          },
        );
      },
    );
  }
}
