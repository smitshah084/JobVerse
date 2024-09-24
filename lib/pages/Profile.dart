import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:job_verse/pages/CompanyHome.dart';

class CreateProfile extends StatefulWidget {
  @override
  _CreateProfileState createState() => _CreateProfileState();
}

class _CreateProfileState extends State<CreateProfile> {
  bool _isLoading = false;
  XFile? _imageFile;
  String? _imageUrl;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
            .collection("profiles")
            .doc(user.uid)
            .get();

        if (profileSnapshot.exists) {
          Map<String, dynamic> data = profileSnapshot.data() as Map<String, dynamic>;
          _nameController.text = data['name'] ?? '';
          _professionController.text = data['profession'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _aboutController.text = data['about'] ?? '';
          _imageUrl = data['image'];
          setState(() {});
        }
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          children: <Widget>[
            _buildProfileImage(),
            SizedBox(height: 20),
            _buildTextField(controller: _nameController, label: 'Name', hint: 'John Doe'),
            SizedBox(height: 20),
            _buildDateOfBirthField(),
            SizedBox(height: 20),
            _buildTextField(
              controller: _aboutController,
              label: 'About',
              hint: 'Write about yourself',
              maxLines: 4,
            ),
            SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: <Widget>[
          CircleAvatar(
            radius: 80.0,
            backgroundImage: _imageFile != null
                ? FileImage(File(_imageFile!.path)) as ImageProvider
                : _imageUrl != null
                ? NetworkImage(_imageUrl!) as ImageProvider
                : AssetImage("assets/profile.jpeg") as ImageProvider,
          ),
          Positioned(
            bottom: 20.0,
            right: 20.0,
            child: InkWell(
              onTap: () => _showImagePicker(),
              child: Icon(
                Icons.camera_alt,
                color: Colors.teal,
                size: 28.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) return "$label can't be empty";
        return null;
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: label,
        hintText: hint,
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    return TextFormField(
      controller: _dobController,
      validator: (value) {
        if (value == null || value.isEmpty) return "Date of Birth can't be empty";
        return null;
      },
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Date of Birth",
        hintText: "01/01/2000",
      ),
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != DateTime.now())
          setState(() {
            _dobController.text = "${picked.toLocal()}".split(' ')[0];
          });
      },
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: InkWell(
        onTap: () async {
          if (_formKey.currentState?.validate() ?? false) {
            setState(() {
              _isLoading = true;
            });
            await _saveProfileDataToFirebase();
          }
        },
        child: Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: _isLoading
                ? CircularProgressIndicator()
                : Text(
              "Submit",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfileDataToFirebase() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _uploadImageToFirebase(_imageFile!);
      } else if (_imageUrl != null) {
        imageUrl = _imageUrl!;
      }

      Map<String, dynamic> profileData = {
        "name": _nameController.text,
        "dob": _dobController.text,
        "about": _aboutController.text,
        "image": imageUrl,
        "uid": user.uid,
      };

      await FirebaseFirestore.instance
          .collection("profiles")
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => Home()));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save profile: $e")));
    }
  }

  Future<String> _uploadImageToFirebase(XFile imageFile) async {
    try {
      Reference storageReference = FirebaseStorage.instance.ref().child("profileImages/${_auth.currentUser?.uid}");
      UploadTask uploadTask = storageReference.putFile(File(imageFile.path));
      TaskSnapshot snapshot = await uploadTask;
      print('Upload complete, URL: ${await snapshot.ref.getDownloadURL()}');
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Image upload failed: $e");
      throw Exception("Image upload failed: $e");
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Pick from gallery"),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                setState(() {
                  _imageFile = image;
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Take a photo"),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                setState(() {
                  _imageFile = image;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}



