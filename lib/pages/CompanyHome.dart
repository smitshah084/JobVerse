import 'package:flutter/material.dart';
import 'package:job_verse/services/auth.dart';
import 'package:job_verse/pages/Profile.dart'; // Import the profile page

class Home extends StatelessWidget {
  // Sample static data
  final List<Map<String, dynamic>> vacancies = [
    {'role': 'Software Engineer', 'numberOfIntakes': 5},
    {'role': 'Product Manager', 'numberOfIntakes': 2},
    {'role': 'UX Designer', 'numberOfIntakes': 3},
  ];

  // Dummy function for update action
  void _updateVacancy(BuildContext context, String role) {
    // Implement your update logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Update functionality for $role')),
    );
  }

  // Dummy function for delete action
  void _deleteVacancy(BuildContext context, String role) {
    // Implement your delete logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete functionality for $role')),
    );
  }

  // Build the Drawer for sidebar navigation
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
              // Close the drawer and stay on the Home page
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
              // Add status page navigation logic here
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
        title: Text('Home'),
      ),
      drawer: buildDrawer(context), // Add the drawer here
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: vacancies.length,
          itemBuilder: (context, index) {
            final vacancy = vacancies[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(vacancy['role']),
                subtitle: Text('Number of Intakes: ${vacancy['numberOfIntakes']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _updateVacancy(context, vacancy['role']),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteVacancy(context, vacancy['role']),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
