import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final String uid;

  ProfilePage({required this.uid});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'No name provided';
  String _profession = 'No profession provided';
  String _dob = 'No date of birth provided';
  String _about = 'No details provided';
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
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
          _imageUrl = data['image']?.toString();
        });
      }
    } catch (e) {
      print("Failed to load profile data: $e");
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
