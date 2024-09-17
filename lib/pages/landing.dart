import 'package:flutter/material.dart';
import 'package:job_verse/pages/Vacancy.dart';
import 'package:job_verse/pages/VacancyCard.dart';
import 'package:job_verse/services/auth.dart';
import 'package:job_verse/pages/Profile.dart'; // Import the Profile page

class VacancyManager extends StatefulWidget {
  const VacancyManager({super.key});

  @override
  _VacancyManagerState createState() => _VacancyManagerState();
}

class _VacancyManagerState extends State<VacancyManager> {
  List<Vacancy> vacancies = [
    Vacancy(position: 'Software Engineer', company: 'TechCorp', intake: 5),
    Vacancy(position: 'Product Manager', company: 'InnovateX', intake: 3),
  ];

  // Method to add a new vacancy
  void _addVacancy(Vacancy vacancy) {
    setState(() {
      vacancies.add(vacancy);
    });
  }

  // Method to update the intake of a vacancy
  void _updateIntake(int index, int intakeChange) {
    setState(() {
      vacancies[index].intake += intakeChange;
    });
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateProfile()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Status'),
            onTap: () {

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Status Page Coming Soon!')),
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
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // Navigate to Profile page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateProfile()), // Ensure this is the correct profile page widget
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              AuthService().signOut(context);
            },
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: ListView.builder(
        itemCount: vacancies.length,
        itemBuilder: (context, index) {
          return VacancyCard(
            vacancy: vacancies[index],
            onIncreaseIntake: () => _updateIntake(index, 1),
            onDecreaseIntake: () => _updateIntake(index, -1),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open a dialog to add a new vacancy
          _showAddVacancyDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  // Dialog to add a new vacancy
  void _showAddVacancyDialog() {
    final TextEditingController positionController = TextEditingController();
    final TextEditingController companyController = TextEditingController();
    final TextEditingController intakeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Vacancy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: positionController,
                decoration: InputDecoration(labelText: 'Position'),
              ),
              TextField(
                controller: companyController,
                decoration: InputDecoration(labelText: 'Company'),
              ),
              TextField(
                controller: intakeController,
                decoration: InputDecoration(labelText: 'Intake'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final String position = positionController.text;
                final String company = companyController.text;
                final int intake = int.parse(intakeController.text);

                _addVacancy(Vacancy(position: position, company: company, intake: intake));
                Navigator.of(context).pop();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
