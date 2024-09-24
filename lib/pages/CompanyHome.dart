import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/services/auth.dart';
import 'package:job_verse/pages/Profile.dart';
import 'package:job_verse/pages/AddVacancyPage.dart';  // Make sure to import the new page
import 'package:job_verse/pages/UpdateVacancyPage.dart';
import 'DeleteVacancy.dart';
import 'ApplicantsPage.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> vacancies = [];

  @override
  void initState() {
    super.initState();
    _fetchVacancies();
  }

  Future<void> _fetchVacancies() async {
    String? companyId = AuthService().currentUser?.uid;

    if (companyId != null) {
      final vacancySnapshot = await _firestore
          .collection('vacancies')
          .where('companyId', isEqualTo: companyId)
          .get();

      final companySnapshot = await _firestore.collection('profiles').doc(companyId).get();
      String companyName = companySnapshot.data()?['name'] ?? 'Unknown Company';

      setState(() {
        vacancies = vacancySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Store the document ID
          data['companyName'] = companyName; // Store the company name
          return data;
        }).toList();
      });
    }
  }

  // Fetch applicants for a specific vacancy
  Future<List<Map<String, dynamic>>> _fetchApplicants(String vacancyId) async {
    // Step 1: Fetch applications for the given vacancy
    final applicantSnapshot = await _firestore
        .collection('applications')
        .where('vacancyId', isEqualTo: vacancyId)
        .get();

    List<Map<String, dynamic>> applicants = [];

    // Step 2: Loop through each application and fetch user details
    for (var doc in applicantSnapshot.docs) {
      final applicationData = doc.data() as Map<String, dynamic>;
      final userId = applicationData['userId'];

      // Step 3: Fetch the profile information for the userId
      final userProfileSnapshot = await _firestore.collection('profiles').doc(userId).get();
      final userProfileData = userProfileSnapshot.data();

      if (userProfileData != null) {
        // Combine application data with user profile information
        applicants.add({
          'applicantName': userProfileData['name'] ?? 'Unknown',
          'applicantEmail': userProfileData['email'] ?? 'No email provided',
        });
      }
    }

    return applicants;
  }

  void _navigateToAddVacancyPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVacancyPage(
          onVacancyAdded: _fetchVacancies,  // Pass the callback to refresh vacancies after adding
        ),
      ),
    );
  }

  void _updateVacancy(BuildContext context, String documentId, String currentDescription, String currentJobType, int currentIntake) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateVacancyPage(
          documentId: documentId,
          currentDescription: currentDescription,
          currentJobType: currentJobType,
          currentIntake: currentIntake,
        ),
      ),
    ).then((_) {
      // This will be called when returning from UpdateVacancyPage
      _fetchVacancies(); // Refresh the vacancies list
    });
  }


  void _deleteVacancy(BuildContext context, String documentId) {
    print("Attempting to delete vacancy with ID: $documentId"); // Debugging line

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Vacancy'),
          content: Text('Are you sure you want to delete this vacancy?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog without deleting
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await VacancyService().deleteVacancy(documentId);
                  await _fetchVacancies();

                  // Show success message after deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vacancy deleted successfully')),
                  );

                  Navigator.pop(context); // Close dialog after deleting
                } catch (e) {
                  // Handle any errors during deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete vacancy: $e')),
                  );
                }
              },
              child: Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _showVacancies(BuildContext context, List<Map<String, dynamic>> vacancies) {
    return ListView.builder(
      itemCount: vacancies.length,
      itemBuilder: (context, index) {
        final vacancy = vacancies[index];
        final role = vacancy['role'];
        final intake = vacancy['numberOfIntakes'];
        final documentId = vacancy['id'];
        final description = vacancy['description'];
        final jobType = vacancy['jobType'];

        return Card(
          elevation: 5,
          margin: EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role: $role',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 5),
                Text('No of intakes: $intake'),
                SizedBox(height: 5),
                Text('Work: $jobType'),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateVacancy(context, documentId, description, jobType, intake),
                      child: Text('Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _deleteVacancy(context, documentId),
                      child: Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApplicantsPage(vacancyId: documentId), // Navigate to ApplicantsPage
                        ),
                      ),
                      child: Text('View Applicants'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),

                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JobVerse'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _navigateToAddVacancyPage(context), // Navigate to AddVacancyPage
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: vacancies.isEmpty
            ? Center(child: Text('No vacancies.'))
            : _showVacancies(context, vacancies),
      ),
    );
  }

  // Custom Drawer
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context); // Stay on the Home page
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateProfile()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () async {
              await AuthService().signOut(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}

