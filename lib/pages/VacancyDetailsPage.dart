// import 'package:flutter/material.dart';
// import 'package:job_verse/pages/Vacancy.dart';
//
// class VacancyDetailsPage extends StatelessWidget {
//   final Vacancy vacancy;
//
//   VacancyDetailsPage({required this.vacancy});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Job Details'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 vacancy.company,
//                 style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               Divider(thickness: 1, color: Colors.grey[300]),
//               SizedBox(height: 16),
//               _buildDetailRow('Role:', vacancy.position),
//               _buildDetailRow('Job Type:', vacancy.jobType),
//               _buildDetailRow('Intake:', vacancy.intake.toString()),
//               SizedBox(height: 16),
//               Text(
//                 'Description:',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
//               ),
//               SizedBox(height: 8),
//               Text(
//                 vacancy.description,
//                 style: TextStyle(fontSize: 19),
//               ),
//               SizedBox(height: 30),
//               Center(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Implement the apply functionality here
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text('Applied successfully!')),
//                     );
//                   },
//                   child: Text('Apply Now'),
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                     textStyle: TextStyle(fontSize: 18),
//                     backgroundColor: Colors.blue,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String title, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             title,
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
//           ),
//           Text(
//             value,
//             style: TextStyle(fontSize: 20),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/Vacancy.dart';
import 'package:job_verse/services/auth.dart';

class VacancyDetailsPage extends StatelessWidget {
  final Vacancy vacancy;

  VacancyDetailsPage({required this.vacancy});

  Future<void> _applyForJob(BuildContext context) async {
    try {
      // Get the current user ID
      String? userId = AuthService().currentUser?.uid;
      if (userId == null) {
        throw 'User not logged in';
      }

      // Save the application data in Firestore
      await FirebaseFirestore.instance.collection('applications').add({
        'userId': userId,
        'vacancyId': vacancy.vacancyId, // You may want to store the actual vacancy id if available
        'role': vacancy.position,
        'company': vacancy.company,
        'applicationDate': FieldValue.serverTimestamp(), // Store the application time
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied successfully!')),
      );
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vacancy.company,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Divider(thickness: 1, color: Colors.grey[300]),
              SizedBox(height: 16),
              _buildDetailRow('Role:', vacancy.position),
              _buildDetailRow('Job Type:', vacancy.jobType),
              _buildDetailRow('Intake:', vacancy.intake.toString()),
              SizedBox(height: 16),
              Text(
                'Description:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                vacancy.description,
                style: TextStyle(fontSize: 19),
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: () => _applyForJob(context), // Apply button logic
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