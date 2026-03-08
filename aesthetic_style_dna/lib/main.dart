import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'config/theme.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ProviderScope(child: AestheticStyleDnaApp()));
}

class AestheticStyleDnaApp extends StatelessWidget {
  const AestheticStyleDnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aesthetic Style DNA',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const ShellScreen(),
    );
  }
}
