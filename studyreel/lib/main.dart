import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'domain/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 화면을 벗어나면 피드 재생을 빠르게 멈추도록 가시성 갱신 간격을 줄인다.
  VisibilityDetectorController.instance.updateInterval =
      const Duration(milliseconds: 150);
  runApp(const ProviderScope(child: StudyReelApp()));
}

class StudyReelApp extends ConsumerWidget {
  const StudyReelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDark = ref.watch(isDarkProvider);

    return MaterialApp.router(
      title: 'StudyReel',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
