import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatusPage extends StatefulWidget {
  final String userId;

  StatusPage({required this.userId});

  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  List<Application> applications = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: widget.userId)
          .where('CurrentState', whereIn: ['Applied', 'Rejected', 'Accepted'])
          .get();

      setState(() {
        applications = snapshot.docs
            .map((doc) => Application.fromFirestore(doc))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching applications: $e';
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Applied':
        return Colors.blue;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Application Status'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : ListView.builder(
        itemCount: applications.length,
        itemBuilder: (context, index) {
          Application app = applications[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: Icon(
                Icons.work_outline,
                color: getStatusColor(app.currentState),
                size: 40,
              ),
              title: Text(
                app.jobTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    'Company: ${app.company}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Status: ${app.currentState}',
                    style: TextStyle(
                      fontSize: 16,
                      color: getStatusColor(app.currentState),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class Application {
  final String jobTitle;
  final String currentState;
  final String company;

  Application({
    required this.jobTitle,
    required this.currentState,
    required this.company,
  });

  factory Application.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Application(
      jobTitle: data['role'] != null ? data['role'] as String : 'Unknown Job',
      currentState: data['CurrentState'] != null ? data['CurrentState'] as String : 'Unknown Status',
      company: data['company'] != null ? data['company'] as String : 'Unknown Company',
    );
  }
}
