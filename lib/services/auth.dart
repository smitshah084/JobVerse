import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:job_verse/pages/CompanyHome.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/landing.dart';
import 'package:job_verse/pages/login.dart';

class AuthService {
  // Determine if the user is authenticated.
  StreamBuilder<User?> handleAuthState() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return _navigateToHomePage(snapshot.data!, context);
        } else {
          return Login();
        }
      },
    );
  }

  Widget _navigateToHomePage(User user, BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('profiles').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          bool isCompany = snapshot.data!.get('isCompany') ?? false;
          return isCompany ? Home() : VacancyManager();
        } else {
          return Login();
        }
      },
    );
  }

  // Sign out
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Login()),
    );
  }

  // Sign in
  Future<void> signIn(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _navigateAfterSignIn(userCredential.user!, context);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        default:
          message = 'An error occurred. Please try again. Error: ${e.code}';
          break;
      }
      _showErrorDialog(context, message);
    } catch (e) {
      _showErrorDialog(context, 'An error occurred. Please try again.');
    }
  }

  Future<void> _navigateAfterSignIn(User user, BuildContext context) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('profiles').doc(user.uid).get();
    if (userDoc.exists) {
      bool isCompany = userDoc.get('isCompany') ?? false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => isCompany ? Home() : VacancyManager()),
      );
    } else {
      _showErrorDialog(context, 'User data not found.');
    }
  }

  // Sign up
  Future<void> signUp(String email, String password, String name, bool isCompany, BuildContext context) async {
    try {

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );


      await _saveUserDataToFirestore(userCredential.user!, email, name, isCompany);


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => isCompany ? Home() : VacancyManager()),
      );
    } on FirebaseAuthException catch (e) {
      // Check for specific Firebase auth errors
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
          break;
        default:
          message = 'An error occurred. Please try again. Error: ${e.code}';
          break;
      }

      // Show the error message in a dialog
      _showErrorDialog(context, message);
    } catch (e) {
      // Handle any other errors
      _showErrorDialog(context, 'An error occurred. Please try again.');
    }
  }

  Future<void> _saveUserDataToFirestore(User user, String email, String name, bool isCompany) async {
    await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set({
      'email': email,
      'isCompany': isCompany,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });

  }

  void _showErrorDialog(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
            ),
          ],
        ),
      );
    });
  }

}
