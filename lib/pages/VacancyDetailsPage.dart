import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/Vacancy.dart';
import 'package:job_verse/services/auth.dart';

class VacancyDetailsPage extends StatefulWidget {
  final Vacancy vacancy;

  VacancyDetailsPage({required this.vacancy});

  @override
  _VacancyDetailsPageState createState() => _VacancyDetailsPageState();
}

class _VacancyDetailsPageState extends State<VacancyDetailsPage> {
  bool _hasApplied = false;
  bool _isLoading = true;
  String _currentState = ''; // Holds the current state of the application

  @override
  void initState() {
    super.initState();
    _checkIfApplied();
  }

  Future<void> _checkIfApplied() async {
    try {
      String? userId = AuthService().currentUser?.uid;
      if (userId == null) {
        throw 'User not logged in';
      }

      // Check if the application already exists in Firestore
      var applicationSnapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('vacancyId', isEqualTo: widget.vacancy.vacancyId)
          .get();

      // If application exists, set _hasApplied to true and get the current state
      if (applicationSnapshot.docs.isNotEmpty) {
        setState(() {
          _hasApplied = true;
          _currentState = applicationSnapshot.docs.first['CurrentState']; // Retrieve the current state
        });
      }
    } catch (e) {
      // Handle any error (optional)
      print('Error checking application status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyForJob(BuildContext context) async {
    try {
      String? userId = AuthService().currentUser?.uid;
      if (userId == null) {
        throw 'User not logged in';
      }

      // Save the application data in Firestore
      await FirebaseFirestore.instance.collection('applications').add({
        'userId': userId,
        'vacancyId': widget.vacancy.vacancyId,
        'role': widget.vacancy.position,
        'company': widget.vacancy.company,
        'CurrentState': 'Applied',
        'applicationDate': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied successfully!')),
      );

      // Mark as applied after successful submission
      setState(() {
        _hasApplied = true;
        _currentState = 'Applied'; // Set the state as "Applied"
      });
    } catch (e) {
      // Show error message in case of any error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job Details'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator()) // Show loading indicator while checking application status
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.vacancy.company,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Divider(thickness: 1, color: Colors.grey[300]),
              SizedBox(height: 16),
              _buildDetailRow('Role:', widget.vacancy.position),
              _buildDetailRow('Job Type:', widget.vacancy.jobType),
              _buildDetailRow('Intake:', widget.vacancy.intake.toString()),
              SizedBox(height: 16),
              Text(
                'Description:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                widget.vacancy.description,
                style: TextStyle(fontSize: 19),
              ),
              SizedBox(height: 30),
              Center(
                child: _hasApplied
                    ? Column(
                  children: [
                    Text(
                      'Current Status: $_currentState',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                    : ElevatedButton(
                  onPressed: () => _applyForJob(context),
                  child: Text('Apply Now'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    textStyle: TextStyle(fontSize: 18),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }
}