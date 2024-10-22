import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Add Firebase Storage package
import 'package:job_verse/services/auth.dart'; // Assuming you have an Auth service for user data
import 'package:job_verse/pages/Vacancy.dart';
import 'dart:io';

class JobApplicationForm extends StatefulWidget {
  final String vacancyId;
  final String role;
  final String company;
  final List<FormFieldData> formFields;

  JobApplicationForm({
    required this.vacancyId,
    required this.role,
    required this.company,
    required this.formFields,
  });

  @override
  _JobApplicationFormState createState() => _JobApplicationFormState();
}

class _JobApplicationFormState extends State<JobApplicationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, dynamic> applicationData = {};
  bool _isSubmitting = false;
  String? _pdfDownloadUrl; // Store the PDF download URL

  Future<void> _submitApplication() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save(); // Save form field values

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Retrieve the current user ID
        String? userId = AuthService().currentUser?.uid;

        if (userId == null) {
          throw Exception("User not logged in");
        }

        // Prepare application data for Firestore
        Map<String, dynamic> applicationSubmissionData = {
          'userId': userId,
          'vacancyId': widget.vacancyId,
          'role': widget.role,
          'company': widget.company,
          'CurrentState': 'Applied',
          'applicationDate': FieldValue.serverTimestamp(),
          'answers': applicationData, // Add dynamic form answers
        };

        // Include the PDF download URL if available
        if (_pdfDownloadUrl != null) {
          applicationSubmissionData['pdfDownloadUrl'] = _pdfDownloadUrl;
          print('PDF URL: $_pdfDownloadUrl');
        }

        // Submit the application data to Firestore
        await FirebaseFirestore.instance.collection('applications').add(applicationSubmissionData);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Application submitted successfully!')));
        Navigator.pop(context); // Close the form after submission

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit application: $e')));
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      String? filePath = result.files.single.path;

      if (filePath != null) {
        // Upload the PDF to Firebase Storage and get the download URL
        String? downloadUrl = await _uploadPdfToStorage(filePath);

        if (downloadUrl != null) {
          setState(() {
            _pdfDownloadUrl = downloadUrl; // Store the PDF download URL
          });
        }
      }
    }
  }


  Future<String?> _uploadPdfToStorage(String filePath) async {
    try {
      // Create a reference to Firebase Storage
      String fileName = filePath.split('/').last;
      Reference storageRef = FirebaseStorage.instance.ref().child('job_applications/$fileName');

      // Upload the file
      UploadTask uploadTask = storageRef.putFile(File(filePath));
      TaskSnapshot taskSnapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload PDF: $e')));
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Apply for Job")),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView.builder(
            itemCount: widget.formFields.length + 1, // +1 for the submit button
            itemBuilder: (context, index) {
              if (index == widget.formFields.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: _submitApplication,
                    child: Text("Submit Application"),
                  ),
                );
              }

              final field = widget.formFields[index];
              return _buildFormField(field);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(FormFieldData field) {
    switch (field.type) {
      case "text":
        return TextFormField(
          decoration: InputDecoration(labelText: field.label),
          validator: field.isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return "This field is required";
            }
            return null;
          }
              : null,
          onSaved: (value) {
            applicationData[field.label] = value;
          },
        );
      case "pdf":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickPdf,
              child: Text("Upload PDF"),
            ),
            if (_pdfDownloadUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("PDF uploaded: ${_pdfDownloadUrl!.split('/').last}"),
              ),
          ],
        );
      default:
        return Container();
    }
  }
}
