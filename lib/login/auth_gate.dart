import 'package:newastros/login/login.dart';

import 'package:newastros/main_pages/mainpage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 If already logged in → go to Home
        if (snapshot.hasData) {
          return AttendanceStatusWidget();
        }

        // 🔹 Else → show LoginPage
        return Login();
      },
    );
  }
}
