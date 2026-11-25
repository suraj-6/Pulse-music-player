
import 'package:flutter/material.dart';
import 'features/player/player_page.dart';
import 'theme/app_colors.dart';

class AudioEqApp extends StatelessWidget {
  const AudioEqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse Music Player',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        scaffoldBackgroundColor: AppColors.cream,

        colorScheme: const ColorScheme.light(
          primary: AppColors.burgundy,
          onPrimary: AppColors.cream,
          secondary: AppColors.dustyRose,
          onSecondary: Colors.white,
          tertiary: AppColors.peach,
          surface: AppColors.surface,
          onSurface: AppColors.plum,
          outline: AppColors.border,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.plum,
          elevation: 0,
        ),

        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: AppColors.border,
              width: 0.8,
            ),
          ),
        ),

        sliderTheme: const SliderThemeData(
          activeTrackColor: AppColors.burgundy,
          inactiveTrackColor: AppColors.border,
          thumbColor: AppColors.burgundy,
          overlayColor: Color(0x33702F4A),
          trackHeight: 4,
        ),

        iconTheme: const IconThemeData(
          color: AppColors.plum,
        ),

        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.plum),
          bodyMedium: TextStyle(color: AppColors.plum),
          titleLarge: TextStyle(
            color: AppColors.plum,
            fontWeight: FontWeight.bold,
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.burgundy,
            foregroundColor: AppColors.cream,
          ),
        ),
      ),

      home: const PlayerPage(),
    );
  }
}
