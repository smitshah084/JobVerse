import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  final String vid;

  ProfilePage({required this.uid,required this.vid});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'No name provided';
  String _profession = 'No profession provided';
  String _dob = 'No date of birth provided';
  String _about = 'No details provided';
  String? _imageUrl;
  String _currentApplicationState = 'Applied'; // Default state
  String _resumeUrl = 'No details provided';

  final List<String> _applicationStates = [
    'Applied',
    'Interview Scheduled',
    'Offer Received',
    'Rejected',
  ]; // Possible states

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadApplicationState(); // Load application state
  }

  Future<void> _loadProfileData() async {
    try {
      DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
          .collection("profiles")
          .doc(widget.uid)
          .get();

      if (profileSnapshot.exists) {
        Map<String, dynamic> data = profileSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _name = data['name']?.toString() ?? 'No name provided';
          _profession = data['profession']?.toString() ?? 'No profession provided';
          _dob = data['dob']?.toString() ?? 'No date of birth provided';
          _about = data['about']?.toString() ?? 'No details provided';
          _imageUrl = data['image']?.toString()?? 'No details provided';
          _resumeUrl = data['resume'] ?? 'No Resume provided';
        });
      }
    } catch (e) {
      print("Failed to load profile data: $e");
    }
  }

  Future<void> _loadApplicationState() async {
    try {
      DocumentSnapshot applicationSnapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: widget.uid)
          .where('vacancyId',isEqualTo: widget.vid)
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.first);

      if (applicationSnapshot.exists) {
        Map<String, dynamic> data = applicationSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentApplicationState = data['CurrentState']?.toString() ?? 'Applied';
        });
      }
    } catch (e) {
      print("Failed to load application state: $e");
    }
  }

  Future<void> _updateApplicationState(String newState) async {
    try {
      QuerySnapshot applicationsSnapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: widget.uid)
          .where('vacancyId',isEqualTo: widget.vid)
          .limit(1)
          .get();

      if (applicationsSnapshot.docs.isNotEmpty) {
        DocumentSnapshot applicationDoc = applicationsSnapshot.docs.first;
        await FirebaseFirestore.instance
            .collection('applications')
            .doc(applicationDoc.id)
            .update({
          'CurrentState': newState,
        });
        setState(() {
          _currentApplicationState = newState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application state updated to $newState')),
        );
      }
    } catch (e) {
      print("Failed to update application state: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: _name.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_imageUrl != null && _imageUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(_imageUrl!),
                ),
              SizedBox(height: 16),
              Text(
                _name,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _profession,
                style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Date of Birth:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _dob,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'About:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _about,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Application State:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      DropdownButton<String>(
                        value: _currentApplicationState,
                        onChanged: (String? newState) {
                          if (newState != null) {
                            _updateApplicationState(newState);
                          }
                        },
                        items: _applicationStates.map((String state) {
                          return DropdownMenuItem<String>(
                            value: state,
                            child: Text(state),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
