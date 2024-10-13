import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/pages/Vacancy.dart'; // Import your Vacancy model if necessary
import 'package:job_verse/services/auth.dart'; // Assuming you have an AuthService to handle auth

class VacancyDetailsPage extends StatefulWidget {
  final Vacancy vacancy;

  VacancyDetailsPage({required this.vacancy});

  @override
  _VacancyDetailsPageState createState() => _VacancyDetailsPageState();
}

class _VacancyDetailsPageState extends State<VacancyDetailsPage> {
  bool _hasApplied = false;
  bool _isLoading = true;
  String _currentState = '';
  List<dynamic> _requiredFields = []; // Can be either List<String> or List<Map<String, dynamic>>

  @override
  void initState() {
    super.initState();
    _checkIfApplied(); // Call the method to check if the user has already applied
    _fetchRequiredFields(); // Fetch required fields when the page loads
  }

  // Fetch required fields for the vacancy
  Future<void> _fetchRequiredFields() async {
    try {
      DocumentSnapshot vacancySnapshot = await FirebaseFirestore.instance
          .collection('vacancies')
          .doc(widget.vacancy.vacancyId)
          .get();

      if (vacancySnapshot.exists && vacancySnapshot['requiredFields'] != null) {
        setState(() {
          _requiredFields = vacancySnapshot['requiredFields'];
        });

        print('Required Fields fetched: $_requiredFields');
      } else {
        print('No required fields found');
      }
    } catch (e) {
      print('Error fetching required fields: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check if the user has already applied for the job
  Future<void> _checkIfApplied() async {
    try {
      String? userId = AuthService().currentUser?.uid;
      if (userId == null) {
        throw 'User not logged in';
      }

      var applicationSnapshot = await FirebaseFirestore.instance
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .where('vacancyId', isEqualTo: widget.vacancy.vacancyId)
          .get();

      if (applicationSnapshot.docs.isNotEmpty) {
        setState(() {
          _hasApplied = true;
          _currentState = applicationSnapshot.docs.first['CurrentState'];
        });
      }
    } catch (e) {
      print('Error checking application status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show the application form and submit the user's application
  Future<void> _applyForJob(BuildContext context) async {
    if (_requiredFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Required fields are not loaded yet!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ApplicationFormDialog(
          vacancy: widget.vacancy,
          requiredFields: _requiredFields,
          onSubmit: (Map<String, dynamic> applicationData) async {
            String? userId = AuthService().currentUser?.uid;
            if (userId == null) {
              throw 'User not logged in';
            }

            await FirebaseFirestore.instance.collection('applications').add({
              'userId': userId,
              'vacancyId': widget.vacancy.vacancyId,
              'role': widget.vacancy.position,
              'company': widget.vacancy.company,
              'CurrentState': 'Applied',
              'applicationDate': FieldValue.serverTimestamp(),
              'answers': applicationData, // Add user answers
            });

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Applied successfully!')),
            );

            setState(() {
              _hasApplied = true;
              _currentState = 'Applied';
            });
          },
        );
      },
    );
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.vacancy.company,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Divider(thickness: 1, color: Colors.grey[300]),
              SizedBox(height: 16),
              _buildDetailRow('Role:', widget.vacancy.position),
              _buildDetailRow('Job Type:', widget.vacancy.jobType),
              _buildDetailRow('Intake:', widget.vacancy.intake.toString()),
              SizedBox(height: 16),
              Text(
                'Description:',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                widget.vacancy.description,
                style: TextStyle(fontSize: 19),
              ),
              SizedBox(height: 30),
              Center(
                child: _hasApplied
                    ? Column(
                  children: [
                    Text(
                      'Current Status: $_currentState',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                    : ElevatedButton(
                  onPressed: () => _applyForJob(context),
                  child: Text('Apply Now'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
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

class ApplicationFormDialog extends StatefulWidget {
  final Vacancy vacancy;
  final List<dynamic> requiredFields;
  final Function(Map<String, dynamic>) onSubmit;

  ApplicationFormDialog({
    required this.vacancy,
    required this.requiredFields,
    required this.onSubmit,
  });

  @override
  _ApplicationFormDialogState createState() => _ApplicationFormDialogState();
}

class _ApplicationFormDialogState extends State<ApplicationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();

    // Initialize controllers based on the type of requiredFields
    widget.requiredFields.forEach((field) {
      if (field is String) {
        controllers[field] = TextEditingController();
      } else if (field is Map<String, dynamic>) {
        controllers[field['field']] = TextEditingController();
      }
    });
  }

  @override
  void dispose() {
    controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.only(top: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: Offset(0.0, 10.0),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Application Form',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    'Please fill in the required details below:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 20),
                  ...widget.requiredFields.map((field) {
                    String fieldName;
                    if (field is String) {
                      fieldName = field;
                    } else if (field is Map<String, dynamic>) {
                      fieldName = field['field'];
                    } else {
                      return Container();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextFormField(
                        controller: controllers[fieldName],
                        decoration: InputDecoration(
                          labelText: fieldName,
                          labelStyle: TextStyle(fontSize: 16),
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '$fieldName cannot be empty';
                          }
                          return null;
                        },
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Map<String, dynamic> formData = {};
                            widget.requiredFields.forEach((field) {
                              String fieldName;

                              if (field is String) {
                                fieldName = field;
                              } else if (field is Map<String, dynamic>) {
                                fieldName = field['field'];
                              } else {
                                return;
                              }

                              formData[fieldName] = controllers[fieldName]!.text.trim();
                            });

                            widget.onSubmit(formData);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

      ],
    );
  }
}
