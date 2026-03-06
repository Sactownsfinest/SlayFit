import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/auth_provider.dart' show authProvider, AuthStatus;
import 'services/notification_service.dart';

// SlayFit brand colors
const kPrimaryDark = Color(0xFF0A0E1A);
const kSurfaceDark = Color(0xFF111827);
const kCardDark = Color(0xFF1A2235);
const kNeonYellow = Color(0xFFE8FF00);
const kNeonYellowDim = Color(0xFFCCE000);
const kTextPrimary = Color(0xFFFFFFFF);
const kTextSecondary = Color(0xFF8A9BB8);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: SlayFitApp(),
    ),
  );
}

class SlayFitApp extends ConsumerWidget {
  const SlayFitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'SlayFit',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kPrimaryDark,
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme.dark(
          primary: kNeonYellow,
          onPrimary: Colors.black,
          secondary: kNeonYellowDim,
          onSecondary: Colors.black,
          surface: kSurfaceDark,
          onSurface: kTextPrimary,
          surfaceContainerHighest: kCardDark,
          onSurfaceVariant: kTextSecondary,
          outline: Color(0xFF2A3550),
        ),
        cardTheme: CardThemeData(
          color: kCardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kPrimaryDark,
          foregroundColor: kTextPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kSurfaceDark,
          selectedItemColor: kNeonYellow,
          unselectedItemColor: kTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kNeonYellow,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A3550)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A3550)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kNeonYellow, width: 1.5),
          ),
          hintStyle: const TextStyle(color: kTextSecondary),
          labelStyle: const TextStyle(color: kTextSecondary),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          headlineMedium: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
          headlineSmall: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          titleLarge: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          titleMedium: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          bodyLarge: TextStyle(color: kTextPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: kTextSecondary, fontSize: 13),
          labelSmall: TextStyle(color: kTextSecondary, fontSize: 11),
        ),
      ),
      home: switch (authState.status) {
        AuthStatus.loading => const SplashScreen(),
        AuthStatus.authenticated => const HomeScreen(),
        AuthStatus.onboarding => const OnboardingScreen(),
        AuthStatus.unauthenticated => const LoginScreen(),
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kPrimaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, size: 80, color: kNeonYellow),
            SizedBox(height: 16),
            Text(
              'SLAYFIT',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your Weight Loss Journey',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
