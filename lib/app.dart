import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

class LearnEnApp extends StatelessWidget {
  const LearnEnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: MaterialApp(
        title: 'LearnEN',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _AppBootstrap(),
      ),
    );
  }
}

class _AppBootstrap extends StatelessWidget {
  const _AppBootstrap();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (!provider.initialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return const MainShell();
      },
    );
  }
}
