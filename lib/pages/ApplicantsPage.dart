import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/ViewProfilePage.dart';

class ApplicantsPage extends StatelessWidget {
  final String vacancyId;

  ApplicantsPage({required this.vacancyId});

  Future<List<Map<String, dynamic>>> _fetchApplicants() async {
    final applicantSnapshot = await FirebaseFirestore.instance
        .collection('applications')
        .where('vacancyId', isEqualTo: vacancyId)
        .get();

    List<Map<String, dynamic>> applicants = [];

    for (var doc in applicantSnapshot.docs) {
      final applicationData = doc.data() as Map<String, dynamic>;
      final userId = applicationData['userId'];

      // Fetch user profile information
      final userProfileSnapshot = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();
      final userProfileData = userProfileSnapshot.data();

      if (userProfileData != null) {
        applicants.add({
          'applicantName': userProfileData['name'] ?? 'Unknown',
          'applicantEmail': userProfileData['email'] ?? 'No email provided',
          'uid':userId,
        });
      }
    }

    return applicants;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Applicants'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchApplicants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final applicants = snapshot.data ?? [];
          if (applicants.isEmpty) {
            return Center(child: Text('No applicants found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicant = applicants[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              applicant['applicantName'] ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              applicant['applicantEmail'] ?? 'No email provided',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Ensure that applicant['uid'] is indeed a String
                          String? uid = applicant['uid'] as String?;
                          if (uid == null) {
                            print('Error: uid is null');
                            return; // Handle the case when uid is null
                          }

                          // Proceed with navigation
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(uid: uid,vid:vacancyId), // Pass the user ID to fetch complete profile
                            ),
                          );
                        },
                        child: Text('View Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Change the color as needed
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
