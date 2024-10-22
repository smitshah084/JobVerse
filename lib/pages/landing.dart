import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/Vacancy.dart';
import 'package:job_verse/pages/VacancyCard.dart';
import 'package:job_verse/pages/VacancyDetailsPage.dart';
import 'package:job_verse/services/auth.dart';
import 'package:job_verse/pages/Profile.dart';
import 'package:job_verse/pages/status.dart';

class VacancyManager extends StatefulWidget {
  const VacancyManager({super.key});

  @override
  _VacancyManagerState createState() => _VacancyManagerState();
}

class _VacancyManagerState extends State<VacancyManager> {
  List<Vacancy> vacancies = [];// To store companyId and name pairs

  @override
  void initState() {
    super.initState();
    _fetchVacancies();
  }

  Future<void> _fetchVacancies() async {
    String userId = AuthService().currentUser?.uid ?? '';

    // Fetch all vacancies
    QuerySnapshot vacancySnapshot = await FirebaseFirestore.instance.collection('vacancies').get();

    // Fetch the user's applications to find vacancies they have applied for
    QuerySnapshot applicationSnapshot = await FirebaseFirestore.instance
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .get();

    // Collect the vacancy IDs the user has already applied for
    List<String> appliedVacancyIds = applicationSnapshot.docs.map((doc) {
      return doc['vacancyId'] as String;
    }).toList();

    // Filter vacancies where the user has not applied
    setState(() {
      vacancies = vacancySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        // Extract form fields if they exist
        List<FormFieldData> formFields = [];
        if (data.containsKey('formFields')) {
          formFields = (data['formFields'] as List).map((field) {
            return FormFieldData(
              label: field['label'] ?? 'Unknown Field',
              type: field['type'] ?? 'text',
              isRequired: field['isRequired'] ?? false,
            );
          }).toList();
        }

        return Vacancy(
          position: data['role'] ?? 'Unknown Role',
          company: data['companyName'] ?? 'Unknown Company',
          intake: data['numberOfIntakes'] ?? 0,
          description: data['description'] ?? 'No description available',
          jobType: data['jobType'] ?? 'Unknown Job Type',
          vacancyId: doc.id,
          formFields: formFields,
        );
      }).where((vacancy) {
        // Filter out vacancies where the user has already applied
        return !appliedVacancyIds.contains(vacancy.vacancyId);
      }).toList();
    });
  }





  void _navigateToDetailsPage(Vacancy vacancy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VacancyDetailsPage(
          vacancy: vacancy,
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CreateProfile()));
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Status'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StatusPage(userId: AuthService().currentUser?.uid ?? '')),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
            onTap: () {
              AuthService().signOut(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JobVerse'),
      ),
      drawer: buildDrawer(context),
      body: ListView.builder(
        itemCount: vacancies.length,
        itemBuilder: (context, index) {
          return VacancyCard(
            vacancy: vacancies[index],
            onView: () => _navigateToDetailsPage(vacancies[index]),
          );
        },
      ),
    );
  }
}
