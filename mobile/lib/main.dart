import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/auth_provider.dart' show authProvider, AuthStatus;
import 'services/notification_service.dart';

// Controls whether the animated splash is still showing after auth resolves
final _splashDoneProvider = StateProvider<bool>((ref) => false);

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
    final splashDone = ref.watch(_splashDoneProvider);

    // Reset splash whenever user authenticates (covers both cold start & sign-in)
    ref.listen<AuthStatus>(
      authProvider.select((s) => s.status),
      (prev, next) {
        if (next == AuthStatus.authenticated && prev != AuthStatus.loading) {
          ref.read(_splashDoneProvider.notifier).state = false;
        }
      },
    );

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
      home: (!splashDone || authState.status == AuthStatus.loading)
          ? SplashScreen(
              onDone: () =>
                  ref.read(_splashDoneProvider.notifier).state = true,
            )
          : switch (authState.status) {
              AuthStatus.loading => const SizedBox.shrink(),
              AuthStatus.authenticated => const HomeScreen(),
              AuthStatus.onboarding => const OnboardingScreen(),
              AuthStatus.unauthenticated => const LoginScreen(),
            },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const SplashScreen({Key? key, this.onDone}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  int _affirmIdx = 0;

  static const _affirmations = [
    'You are stronger than you think.',
    'Every rep counts. Every step matters.',
    'Progress, not perfection.',
    'You showed up. That\'s already a win.',
    'Small habits lead to big results.',
    'Your only competition is yesterday\'s you.',
    'Consistency beats intensity every time.',
    'Fuel your body. Trust the process.',
  ];

  @override
  void initState() {
    super.initState();
    _affirmIdx = DateTime.now().day % _affirmations.length;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.82, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();

    // Minimum display time of 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryDark,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: kNeonYellow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.bolt, size: 56, color: Colors.black),
                ),
                const SizedBox(height: 20),
                const Text(
                  'SLAYFIT',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Weight Loss Journey',
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    '\u201c${_affirmations[_affirmIdx]}\u201d',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kNeonYellow,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
