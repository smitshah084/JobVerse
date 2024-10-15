import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart'; // Import the file_picker package
import 'package:job_verse/services/auth.dart'; // Assuming you have an Auth service for user data
import 'package:job_verse/pages/Vacancy.dart'; // Adjust the import according to your project structure

class JobApplicationForm extends StatefulWidget {
  final String vacancyId; // Vacancy ID to associate the application with a specific vacancy
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
  Map<String, dynamic> applicationData = {}; // Stores the answers to the dynamic form fields
  bool _isSubmitting = false; // Tracks the submission state
  String? _pdfFilePath; // Store the PDF file path

  Future<void> _submitApplication() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save(); // Trigger saving of form field values

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
          'answers': applicationData, // Add the user's answers to dynamic fields
        };

        // Include the PDF file path if available
        if (_pdfFilePath != null) {
          applicationSubmissionData['pdfFilePath'] = _pdfFilePath;
        }

        // Submit the application data to Firestore
        await FirebaseFirestore.instance.collection('applications').add(applicationSubmissionData);

        // Show a success message or navigate away
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
    // Use file_picker to pick a PDF file
    String? pickedFilePath = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    ).then((result) => result?.files.single.path);

    if (pickedFilePath != null) {
      setState(() {
        _pdfFilePath = pickedFilePath; // Store the picked file path
      });
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
                // Submit button
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
            applicationData[field.label] = value; // Save the user's input
          },
        );
      case "number":
        return TextFormField(
          decoration: InputDecoration(labelText: field.label),
          keyboardType: TextInputType.number,
          validator: field.isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return "This field is required";
            }
            return null;
          }
              : null,
          onSaved: (value) {
            applicationData[field.label] = value; // Save the user's input
          },
        );
      case "email":
        return TextFormField(
          decoration: InputDecoration(labelText: field.label),
          keyboardType: TextInputType.emailAddress,
          validator: field.isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return "This field is required";
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return "Enter a valid email";
            }
            return null;
          }
              : null,
          onSaved: (value) {
            applicationData[field.label] = value; // Save the user's input
          },
        );
      case "dropdown":
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(labelText: field.label),
          items: ["Option 1", "Option 2", "Option 3"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            applicationData[field.label] = value; // Save the user's selection
          },
          validator: field.isRequired
              ? (value) {
            if (value == null || value.isEmpty) {
              return "This field is required";
            }
            return null;
          }
              : null,
        );
      case "pdf": // Handle PDF upload
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.label, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickPdf,
              child: Text("Upload PDF"),
            ),
            if (_pdfFilePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Selected file: ${_pdfFilePath!.split('/').last}"),
              ),
          ],
        );
      default:
        return Container(); // Handle unknown field types if necessary
    }
  }
}
