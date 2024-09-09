import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:job_verse/pages/home.dart';
import 'package:job_verse/pages/login.dart';
import 'package:job_verse/pages/landing.dart';

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
  signOut() {
    FirebaseAuth.instance.signOut();
  }

  Future<void> signIn(String email, String password, BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
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
  Future<void> signUp(String email, String password, BuildContext context) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
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
      _showErrorDialog(context, 'Please try again.');
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