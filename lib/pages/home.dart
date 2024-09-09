import 'package:flutter/material.dart';
import 'package:job_verse/services/auth.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut();
            },
          )
        ],
      ),
      body: Center(
        child: Text('Welcome! You are logged in.'),
      ),
    );
  }
}
