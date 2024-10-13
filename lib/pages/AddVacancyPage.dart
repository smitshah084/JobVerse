import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/services/auth.dart';

class AddVacancyPage extends StatefulWidget {
  final Function onVacancyAdded; // Callback to refresh the vacancies after adding

  const AddVacancyPage({Key? key, required this.onVacancyAdded}) : super(key: key);

  @override
  _AddVacancyPageState createState() => _AddVacancyPageState();
}

class _AddVacancyPageState extends State<AddVacancyPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController intakeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedJobType;

  List<Map<String, String>> requiredFields = []; // List to hold candidate required fields

  Future<void> _addVacancy(String role, int numberOfIntakes, String description, String jobType) async {
    String? companyId = AuthService().currentUser?.uid;

    if (companyId != null) {
      // Fetch the company name from the profiles collection
      DocumentSnapshot companySnapshot = await FirebaseFirestore.instance.collection('profiles').doc(companyId).get();

      // Cast the data to Map<String, dynamic>
      String companyName = (companySnapshot.data() as Map<String, dynamic>)['name'] ?? 'Unknown Company';

      // Add the vacancy with company name and required fields
      await FirebaseFirestore.instance.collection('vacancies').add({
        'role': role,
        'numberOfIntakes': numberOfIntakes,
        'description': description,
        'jobType': jobType,
        'companyId': companyId,
        'companyName': companyName, // Store company name
        'createdAt': FieldValue.serverTimestamp(),
        'requiredFields': requiredFields, // Store dynamic candidate fields
      });

      widget.onVacancyAdded(); // Call the callback function to refresh the vacancy list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Vacancy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey, // Form key for validation
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: roleController,
                  decoration: InputDecoration(
                    labelText: 'Vacancy Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vacancy Name cannot be empty';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: intakeController,
                  decoration: InputDecoration(
                    labelText: 'Number of Intakes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                DropdownButtonFormField<String>(
                  value: selectedJobType,
                  decoration: InputDecoration(
                    labelText: 'Job Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: ['Remote', 'Office']
                      .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                      .toList(),
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
                SizedBox(height: 10),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description cannot be empty';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Section to dynamically add required candidate fields
                DynamicCandidateFieldsForm(requiredFields: requiredFields),

                SizedBox(height: 20),
                ElevatedButton(
                  child: Text('Add Vacancy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _addVacancy(
                        roleController.text.trim(),
                        int.parse(intakeController.text.trim()),
                        descriptionController.text.trim(),
                        selectedJobType!,
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
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
