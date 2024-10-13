import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final String vid;

  ProfilePage({required this.uid, required this.vid});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _applicationState = 'No state provided';
  String _company = 'No company provided';
  String _role = 'No role provided';
  String _applicationDate = 'No application date provided';

  Map<String, dynamic> _answers = {}; // Dynamic answers map

  @override
  void initState() {
    super.initState();
    _loadApplicationDetails();
  }

  Future<void> _loadApplicationDetails() async {
    try {
      // Fetch application data based on userId and vacancyId
      QuerySnapshot applicationSnapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: widget.uid)
          .where('vacancyId', isEqualTo: widget.vid)
          .get();

      if (applicationSnapshot.docs.isNotEmpty) {
        DocumentSnapshot applicationDoc = applicationSnapshot.docs.first;
        Map<String, dynamic> data = applicationDoc.data() as Map<String, dynamic>;

        setState(() {
          _answers = data['answers'] ?? {}; // Fetch the dynamic answers map
          _applicationState = data['CurrentState']?.toString() ?? 'No state provided';
          _company = data['company']?.toString() ?? 'No company provided';
          _role = data['role']?.toString() ?? 'No role provided';
          _applicationDate = data['applicationDate']?.toDate().toString() ?? 'No application date provided';
        });
      }
    } catch (e) {
      print("Failed to load application details: $e");
    }
  }

  Future<void> _updateApplicationState(String newState) async {
    try {
      // Update application state in Firestore
      await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: widget.uid)
          .where('vacancyId', isEqualTo: widget.vid)
          .get()
          .then((applicationSnapshot) {
        if (applicationSnapshot.docs.isNotEmpty) {
          DocumentReference applicationRef = applicationSnapshot.docs.first.reference;
          applicationRef.update({'CurrentState': newState});
        }
      });
      setState(() {
        _applicationState = newState; // Update local state
      });
      Navigator.pop(context); // Pop the current screen after updating
    } catch (e) {
      print("Failed to update application state: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Response Details'),
        backgroundColor: Colors.white, // White color for app bar
        elevation: 0, // No shadow for a clean look
        iconTheme: IconThemeData(color: Colors.black), // Black icons
      ),
      body: _answers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildAnswersSection(),
            SizedBox(height: 16),
            // Buttons to update application state
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _updateApplicationState('Accepted'),
                  child: Text('Accept'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton(
                  onPressed: () => _updateApplicationState('Rejected'),
                  child: Text('Reject'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswersSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white, // White background for the card
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._answers.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade100, // Light grey background for contrast
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      title: Text(
                        '${entry.key}:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Black text for titles
                        ),
                      ),
                      subtitle: Text(
                        '${entry.value}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87, // Dark grey for answers
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

