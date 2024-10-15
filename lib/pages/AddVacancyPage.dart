import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_verse/services/auth.dart';

class AddVacancyPage extends StatefulWidget {
  final Function onVacancyAdded;

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
  List<FormFieldData> dynamicFields = [];

  final _labelController = TextEditingController();
  String? _selectedFieldType;
  bool _isRequired = false;
  bool isLoading = false;

  void _addField() {
    if (_labelController.text.isEmpty || _selectedFieldType == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter field label and select field type.')));
      return;
    }

    setState(() {
      dynamicFields.add(
        FormFieldData(
          label: _labelController.text,
          type: _selectedFieldType!,
          isRequired: _isRequired,
        ),
      );
      _labelController.clear();
      _selectedFieldType = null;
      _isRequired = false;
    });
  }

  void _removeField(int index) {
    setState(() {
      dynamicFields.removeAt(index);
    });
  }

  Future<void> _addVacancy(String role, int numberOfIntakes, String description, String jobType) async {
    setState(() {
      isLoading = true;
    });

    String? companyId = AuthService().currentUser?.uid;

    if (companyId != null) {
      try {
        DocumentSnapshot companySnapshot = await FirebaseFirestore.instance.collection('profiles').doc(companyId).get();
        String companyName = (companySnapshot.data() as Map<String, dynamic>)['name'] ?? 'Unknown Company';

        await FirebaseFirestore.instance.collection('vacancies').add({
          'role': role,
          'numberOfIntakes': numberOfIntakes,
          'description': description,
          'jobType': jobType,
          'companyId': companyId,
          'companyName': companyName,
          'formFields': dynamicFields.map((field) => {
            'label': field.label,
            'type': field.type,
            'isRequired': field.isRequired,
          }).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        widget.onVacancyAdded();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vacancy added successfully!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add vacancy: $e')));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post a New Job Opening'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Job Information
                Text('Job Information', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 10),

                // Vacancy Name
                TextFormField(
                  controller: roleController,
                  decoration: InputDecoration(
                    labelText: 'Vacancy Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vacancy Name cannot be empty';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Number of Intakes
                TextFormField(
                  controller: intakeController,
                  decoration: InputDecoration(
                    labelText: 'Number of Intakes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Number of Intakes cannot be empty';
                    }
                    int? numberOfIntakes = int.tryParse(value);
                    if (numberOfIntakes == null || numberOfIntakes <= 0) {
                      return 'Intakes must be a positive integer';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Job Type Dropdown
                DropdownButtonFormField<String>(
                  value: selectedJobType,
                  decoration: InputDecoration(
                    labelText: 'Job Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Remote', 'Office'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
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
                SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description cannot be empty';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Section: Application Fields
                Text('Application Fields', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 10),

                // Dynamic Fields: Label
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: "Field Label",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 10),

                // Field Type Dropdown
                DropdownButton<String>(
                  value: _selectedFieldType,
                  hint: Text("Select Field Type"),
                  items: ["text", "number", "email", "pdf"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFieldType = value;
                    });
                  },
                ),
                SizedBox(height: 10),

                // Required Checkbox
                CheckboxListTile(
                  title: Text("Is Required"),
                  value: _isRequired,
                  onChanged: (bool? value) {
                    setState(() {
                      _isRequired = value ?? false;
                    });
                  },
                ),
                SizedBox(height: 10),

                // Add Field Button
                ElevatedButton.icon(
                  onPressed: _addField,
                  icon: Icon(Icons.add),
                  label: Text("Add Field"),
                ),
                SizedBox(height: 20),

                // List of Dynamic Fields
                if (dynamicFields.isNotEmpty) ...[
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: dynamicFields.length,
                    itemBuilder: (context, index) {
                      final field = dynamicFields[index];
                      return ListTile(
                        title: Text("${field.label} (${field.type})"),
                        subtitle: Text(field.isRequired ? "Required" : "Optional"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeField(index),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                ],

                // Loading Spinner or Add Vacancy Button
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _addVacancy(
                          roleController.text,
                          int.parse(intakeController.text),
                          descriptionController.text,
                          selectedJobType!,
                        );
                      }
                    },
                    child: Text('Add Vacancy'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FormFieldData {
  final String label;
  final String type;
  final bool isRequired;

  FormFieldData({
    required this.label,
    required this.type,
    this.isRequired = false,
  });
}
