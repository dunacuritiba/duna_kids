import 'package:flutter/material.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/checkin/screens/checkin_screen.dart';
import 'features/classrooms/screens/classrooms_screen.dart';
import 'features/events/screens/events_screen.dart';
import 'features/profile/screens/meus_dados_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const DunaKidsApp());
}

class DunaKidsApp extends StatelessWidget {
  const DunaKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isUserLoggedIn = SupabaseService.instance.isAuthenticated;

    return MaterialApp(
      title: 'Duna Kids',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: isUserLoggedIn ? '/meus-dados' : '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/meus-dados': (context) => const MeusDadosScreen(),
        '/checkin': (context) => const CheckinScreen(),
        '/turmas': (context) => const ClassroomsScreen(),
        '/eventos': (context) => const EventsScreen(),
      },
    );
  }
}

typedef AzureAuthApp = DunaKidsApp;
