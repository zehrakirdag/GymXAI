import 'package:flutter/material.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'features/trainer/screens/trainer_home_screen.dart';
import 'features/client/screens/client_home_screen.dart';

import 'data/services/local_notification_service.dart';
import 'data/services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalNotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getStartScreen() async {
    final isLoggedIn = await SessionService.isLoggedIn();

    if (!isLoggedIn) {
      return const LoginScreen();
    }

    final user = await SessionService.getUser();

    if (user == null) {
      await SessionService.logout();
      return const LoginScreen();
    }

    final String role = user["role"] ?? "";
    final String fullName = user["fullName"] ?? "";
    final int userId = user["id"];

    if (role == "ADMIN") {
      return const AdminHomeScreen();
    }

    if (role == "TRAINER") {
      return TrainerHomeScreen(
        trainerName: fullName,
        trainerUserId: userId,
      );
    }

    if (role == "CLIENT") {
      return ClientHomeScreen(
        clientName: fullName,
        clientUserId: userId,
      );
    }

    await SessionService.logout();
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GymXAI',
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }
}