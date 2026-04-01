import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const CivicApp());
}

class CivicApp extends StatelessWidget {
  const CivicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Civic Pulse',
      home: const MapScreen(),
    );
  }
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firebase Check")),
      body: Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("Firebase Connected ✅"),
      const SizedBox(height: 20),
      ElevatedButton(
  onPressed: () async {
    print("Button clicked");

    try {
      await FirestoreService().testWrite();
      print("Firestore write success");
    } catch (e) {
      print("ERROR: $e");
    }
  },
  child: const Text("Test Firestore"),
),
    ],
  ),
),
    );
  }
}