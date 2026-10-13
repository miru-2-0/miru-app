import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import '../core/utils/app_messenger.dart';
import '../features/main_navigation/presentation/main_navigation_screen.dart';
import '../l10n/app_localizations.dart';
import 'l10n/language_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_service.dart';

class MiruApp extends StatelessWidget {
  const MiruApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService.instance;
    final languageService = LanguageService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, languageService]),
      builder: (context, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final useDynamic = themeService.useDynamicColor;

            return MaterialApp(
              title: 'Miru',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: appScaffoldMessengerKey,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: languageService.currentLocale,
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
