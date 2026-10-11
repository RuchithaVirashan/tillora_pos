import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

class TilloraApp extends StatelessWidget {
  const TilloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tillora POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
