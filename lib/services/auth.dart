import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:job_verse/pages/CompanyHome.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/landing.dart';
import 'package:job_verse/pages/login.dart';

class AuthService {
  // Determine if the user is authenticated.
  handleAuthState() {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          return VacancyManager();
        } else {
          return Login();
        }
      },
    );
  }

  // Sign out
  signOut(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  Future<void> signIn(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

      if (userDoc.exists) {
        bool isCompany = userDoc.get('isCompany') ?? false;

        if (isCompany) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home()), // Navigate to Home() for company users
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => VacancyManager()), // Navigate to VacancyManager() for others
          );
        }
      } else {
        _showErrorDialog(context, 'User data not found.');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'invalid-email') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong password provided.';
      } else {
        message = 'An error occurred. Please try again. error: ${e.code}';
      }
      _showErrorDialog(context, message);
    } catch (e) {
      _showErrorDialog(context, 'An error occurred. Please try again.');
    }
  }

  // Sign up
  Future<void> signUp(String email, String password, String name,bool _isCompany, BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Store user data in Firestore
      if (userCredential.user != null) {
        // Store user data in Firestore
        await FirebaseFirestore.instance.collection('users').doc(
            userCredential.user!.uid).set({
          'email': email,
          'isCompany':_isCompany,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
        });

        // Navigate to the home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>
              Home()), // Navigate to Home or another appropriate page
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'An error occurred. Please try again. error: ${e.code}';
      }
      _showErrorDialog(context, message);
    } catch (e) {
      _showErrorDialog(context, 'An error occurred. Please try again.');
    }
  }


  // Helper function to show error dialogs
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }
}