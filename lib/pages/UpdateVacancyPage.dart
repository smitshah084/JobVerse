import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateVacancyPage extends StatelessWidget {
  final String documentId;
  final String currentDescription;
  final String currentJobType;
  final int currentIntake;

  UpdateVacancyPage({
    required this.documentId,
    required this.currentDescription,
    required this.currentJobType,
    required this.currentIntake,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController intakeController = TextEditingController(text: currentIntake.toString());
    final TextEditingController descriptionController = TextEditingController(text: currentDescription);
    String? selectedJobType = currentJobType;

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Vacancy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: intakeController,
                decoration: InputDecoration(labelText: 'Number of Intakes'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Number of Intakes cannot be empty';
                  }
                  int? numberOfIntakes = int.tryParse(value);
                  if (numberOfIntakes == null || numberOfIntakes <= 0) {
                    return 'Number of Intakes must be a positive integer';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description cannot be empty';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedJobType,
                decoration: InputDecoration(labelText: 'Job Type'),
                items: ['Remote', 'Office'].map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                )).toList(),
                onChanged: (value) {
                  selectedJobType = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a job type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('vacancies')
                          .doc(documentId) // Document ID to update
                          .update({
                        'numberOfIntakes': int.parse(intakeController.text),
                        'description': descriptionController.text,
                        'jobType': selectedJobType,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Vacancy updated successfully')),
                      );
                      Navigator.pop(context); // Close after updating
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update vacancy: $e')),
                      );
                    }
                  }
                },
                child: Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
