import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'providers/role_permissions_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize default role permissions if they don't exist
    final roleRepo = RolePermissionsRepository(FirebaseFirestore.instance);
    await roleRepo.initializeDefaults();

    runApp(
      const ProviderScope(
        child: PFRApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('Error initializing app: $e');
    debugPrint('Stack trace: $stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error initializing app:\n$e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
