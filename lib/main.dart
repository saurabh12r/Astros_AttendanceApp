import 'package:newastros/firebase_options.dart';
import 'package:newastros/login/auth_gate.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:flutter/material.dart';

Future<void> main() async {
  try {
    // Ensure Flutter bindings are initialized before calling native code
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform, // Make sure this is configured
    );
    FirebaseDatabase.instance.databaseURL =
        'https://astros-45a3f-default-rtdb.asia-southeast1.firebasedatabase.app';

    // Run your main application
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // If initialization fails, catch the error
    print('Firebase initialization failed: $e');
    print(stackTrace);

    // And run an app that shows the error message
    runApp(MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AuthGate(),
    );
  }
}
