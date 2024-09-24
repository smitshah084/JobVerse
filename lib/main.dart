import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:job_verse/pages/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/SignupPage.dart';
import 'package:job_verse/pages/landing.dart'; // Assuming the file name for the normal user's homepage
import 'package:job_verse/pages/CompanyHome.dart'; // Assuming the file name for the company homepage
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JobVerse',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {

      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }


          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Login();
          }

          final data = snapshot.data!.data();
          if (data == null || data is! Map<String, dynamic>) {
            return Login();
          }

          // Navigate to the appropriate homepage based on user type
          return data['isCompany'] == true
              ? Home()
              : VacancyManager();
        },
      );
    } else {
      // If no user is logged in, navigate to login screen
      return Login();
    }
  }
}
