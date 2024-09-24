import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/Vacancy.dart';
import 'package:job_verse/pages/VacancyCard.dart';
import 'package:job_verse/pages/VacancyDetailsPage.dart';
import 'package:job_verse/services/auth.dart';
import 'package:job_verse/pages/Profile.dart';

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
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('vacancies').get();

    setState(() {
      vacancies = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        return Vacancy(
          position: data['role'] ?? 'Unknown Role', // Handle potential null
          company: data['companyName'] ?? 'Unknown Company', // Handle potential null
          intake: data['numberOfIntakes'] ?? 0, // Default to 0
          description: data['description'] ?? 'No description available', // Handle potential null
          jobType: data['jobType'] ?? 'Unknown Job Type', // Handle potential null
          vacancyId: doc.id,
        );
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status Page Coming Soon!')));
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
