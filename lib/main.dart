import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/questions/screens/practice_screen.dart';
import 'features/questions/screens/exam_screen.dart';
import 'features/stats/screens/stats_screen.dart';
import 'features/achievements/screens/achievements_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://owlmamzfbdesiycbqgig.supabase.co',
    anonKey: 'sb_publishable_yjZGEM-2qBMGd8nlBaYUEA_UdKn9JEd',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NurseCalc Pro',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),   // start here
      routes: {
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/login': (context) => const LoginScreen(),
        '/practice': (context) => const PracticeScreen(),
        '/exam': (context) => const ExamScreen(),
        '/stats': (context) => const StatsScreen(),
        '/achievements': (context) => const AchievementsScreen(),
      },
    );
  }
}
