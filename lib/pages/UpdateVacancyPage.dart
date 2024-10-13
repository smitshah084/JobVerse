import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateVacancyPage extends StatefulWidget {
  final String documentId;
  final String currentDescription;
  final String currentJobType;
  final int currentIntake;
  final List<Map<String, String>> currentRequiredFields; // Existing required fields

  UpdateVacancyPage({
    required this.documentId,
    required this.currentDescription,
    required this.currentJobType,
    required this.currentIntake,
    required this.currentRequiredFields,
  });

  @override
  _UpdateVacancyPageState createState() => _UpdateVacancyPageState();
}

class _UpdateVacancyPageState extends State<UpdateVacancyPage> {
  final TextEditingController intakeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedJobType;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Map<String, String>> requiredFields = [];

  @override
  void initState() {
    super.initState();
    intakeController.text = widget.currentIntake.toString();
    descriptionController.text = widget.currentDescription;
    selectedJobType = widget.currentJobType;
    requiredFields = List.from(widget.currentRequiredFields); // Load current required fields
  }

  @override
  Widget build(BuildContext context) {
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
                  setState(() {
                    selectedJobType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a job type';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Section to dynamically add and remove required candidate fields
              DynamicCandidateFieldsForm(requiredFields: requiredFields),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('vacancies')
                          .doc(widget.documentId) // Document ID to update
                          .update({
                        'numberOfIntakes': int.parse(intakeController.text),
                        'description': descriptionController.text,
                        'jobType': selectedJobType,
                        'requiredFields': requiredFields, // Update candidate required fields
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

// Dynamic form for adding and removing required fields for candidates
class DynamicCandidateFieldsForm extends StatefulWidget {
  final List<Map<String, String>> requiredFields;

  DynamicCandidateFieldsForm({required this.requiredFields});

  @override
  _DynamicCandidateFieldsFormState createState() => _DynamicCandidateFieldsFormState();
}

class _DynamicCandidateFieldsFormState extends State<DynamicCandidateFieldsForm> {
  final TextEditingController fieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: fieldController,
          decoration: InputDecoration(labelText: 'Required Candidate Field'),
        ),
        ElevatedButton(
          onPressed: () {
            if (fieldController.text.isNotEmpty) {
              setState(() {
                widget.requiredFields.add({'field': fieldController.text, 'type': 'String'});
              });
              fieldController.clear();
            }
          },
          child: Text('Add Field'),
        ),
        // Display the added fields with the ability to remove
        ListView.builder(
          shrinkWrap: true,
          itemCount: widget.requiredFields.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(widget.requiredFields[index]['field']!),
              trailing: IconButton(
                icon: Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    widget.requiredFields.removeAt(index); // Remove the field
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
