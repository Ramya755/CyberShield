import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../screens/main_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // If user is not logged in, they shouldn't be here
        if (!auth.isLoggedIn) {
          // Navigate back or to login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Dashboard main content - show MainScreen with logout option
        return MainScreen(
          isDark: true,
          onThemeChanged: () {},
        );
      },
    );
  }
}
