import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'core/router.dart';

void main() {
  runApp(const ProviderScope(child: StudyReelApp()));
}

class StudyReelApp extends StatelessWidget {
  const StudyReelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StudyReel',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
