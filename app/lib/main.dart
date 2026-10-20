import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme.dart';

void main() => runApp(const FitTrackApp());

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: buildFitTrackTheme(),
      home: const LoginScreen(),
    );
  }
}
