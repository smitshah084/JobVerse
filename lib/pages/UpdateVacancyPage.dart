import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateVacancyPage extends StatefulWidget {
  final String vacancyId;

  const UpdateVacancyPage({Key? key, required this.vacancyId}) : super(key: key);

  @override
  _UpdateVacancyPageState createState() => _UpdateVacancyPageState();
}

class _UpdateVacancyPageState extends State<UpdateVacancyPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController intakeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String? selectedJobType;
  List<FormFieldData> dynamicFields = [];
  bool isLoading = false;

  // Controllers for adding dynamic fields
  final _labelController = TextEditingController();
  String? _selectedFieldType;
  bool _isRequired = false;

  @override
  void initState() {
    super.initState();
    _fetchVacancyData();
  }

  Future<void> _fetchVacancyData() async {
    try {
      setState(() {
        isLoading = true;
      });
      // Fetch the vacancy data from Firestore by vacancyId
      DocumentSnapshot vacancySnapshot = await FirebaseFirestore.instance.collection('vacancies').doc(widget.vacancyId).get();
      if (vacancySnapshot.exists) {
        Map<String, dynamic> data = vacancySnapshot.data() as Map<String, dynamic>;

        // Pre-fill form with fetched data
        roleController.text = data['role'];
        intakeController.text = data['numberOfIntakes'].toString();
        descriptionController.text = data['description'];
        selectedJobType = data['jobType'];

        // Load dynamic form fields
        List<dynamic> fields = data['formFields'];
        dynamicFields = fields.map((field) => FormFieldData(
            label: field['label'],
            type: field['type'],
            isRequired: field['isRequired']
        )).toList();

        setState(() {}); // Refresh UI after data is loaded
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading vacancy data: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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

  Future<void> _updateVacancy(String role, int numberOfIntakes, String description, String jobType) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Updating vacancy in Firestore
      await FirebaseFirestore.instance.collection('vacancies').doc(widget.vacancyId).set({
        'role': role,
        'numberOfIntakes': numberOfIntakes,
        'description': description,
        'jobType': jobType,
        'formFields': dynamicFields.map((field) => {
          'label': field.label,
          'type': field.type,
          'isRequired': field.isRequired,
        }).toList(),
      }, SetOptions(merge: true)); // merge: true ensures it updates instead of replacing the document.

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vacancy updated successfully!')));
      Navigator.pop(context); // Go back after successful update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update vacancy: $e')));
      print('Update error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Vacancy'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                  items: ["text", "number", "email", "dropdown", "pdf"].map((String value) {
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
                          onPressed: () => setState(() => dynamicFields.removeAt(index)),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                ],

                // Loading Spinner or Update Vacancy Button
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _updateVacancy(
                          roleController.text,
                          int.parse(intakeController.text),
                          descriptionController.text,
                          selectedJobType!,
                        );
                      }
                    },
                    child: Text('Update Vacancy'),
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


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class UpdateVacancyPage extends StatefulWidget {
//   final String documentId;
//   final String currentDescription;
//   final String currentJobType;
//   final int currentIntake;
//   final List<Map<String, String>> currentRequiredFields; // Existing required fields
//
//   UpdateVacancyPage({
//     required this.documentId,
//     required this.currentDescription,
//     required this.currentJobType,
//     required this.currentIntake,
//     required this.currentRequiredFields,
//   });
//
//   @override
//   _UpdateVacancyPageState createState() => _UpdateVacancyPageState();
// }
//
// class _UpdateVacancyPageState extends State<UpdateVacancyPage> {
//   final TextEditingController intakeController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   String? selectedJobType;
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//
//   List<Map<String, String>> requiredFields = [];
//
//   @override
//   void initState() {
//     super.initState();
//     intakeController.text = widget.currentIntake.toString();
//     descriptionController.text = widget.currentDescription;
//     selectedJobType = widget.currentJobType;
//     requiredFields = List.from(widget.currentRequiredFields); // Load current required fields
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Update Vacancy'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 controller: intakeController,
//                 decoration: InputDecoration(labelText: 'Number of Intakes'),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Number of Intakes cannot be empty';
//                   }
//                   int? numberOfIntakes = int.tryParse(value);
//                   if (numberOfIntakes == null || numberOfIntakes <= 0) {
//                     return 'Number of Intakes must be a positive integer';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 10),
//               TextFormField(
//                 controller: descriptionController,
//                 decoration: InputDecoration(labelText: 'Description'),
//                 maxLines: 5,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Description cannot be empty';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 10),
//               DropdownButtonFormField<String>(
//                 value: selectedJobType,
//                 decoration: InputDecoration(labelText: 'Job Type'),
//                 items: ['Remote', 'Office'].map((type) => DropdownMenuItem(
//                   value: type,
//                   child: Text(type),
//                 )).toList(),
//                 onChanged: (value) {
//                   setState(() {
//                     selectedJobType = value;
//                   });
//                 },
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please select a job type';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//
//               // Section to dynamically add and remove required candidate fields
//               DynamicCandidateFieldsForm(requiredFields: requiredFields),
//
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     try {
//                       await FirebaseFirestore.instance
//                           .collection('vacancies')
//                           .doc(widget.documentId) // Document ID to update
//                           .update({
//                         'numberOfIntakes': int.parse(intakeController.text),
//                         'description': descriptionController.text,
//                         'jobType': selectedJobType,
//                         'requiredFields': requiredFields, // Update candidate required fields
//                       });
//
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Vacancy updated successfully')),
//                       );
//                       Navigator.pop(context); // Close after updating
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to update vacancy: $e')),
//                       );
//                     }
//                   }
//                 },
//                 child: Text('Update'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.orange,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Dynamic form for adding and removing required fields for candidates
// class DynamicCandidateFieldsForm extends StatefulWidget {
//   final List<Map<String, String>> requiredFields;
//
//   DynamicCandidateFieldsForm({required this.requiredFields});
//
//   @override
//   _DynamicCandidateFieldsFormState createState() => _DynamicCandidateFieldsFormState();
// }
//
// class _DynamicCandidateFieldsFormState extends State<DynamicCandidateFieldsForm> {
//   final TextEditingController fieldController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         TextFormField(
//           controller: fieldController,
//           decoration: InputDecoration(labelText: 'Required Candidate Field'),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             if (fieldController.text.isNotEmpty) {
//               setState(() {
//                 widget.requiredFields.add({'field': fieldController.text, 'type': 'String'});
//               });
//               fieldController.clear();
//             }
//           },
//           child: Text('Add Field'),
//         ),
//         // Display the added fields with the ability to remove
//         ListView.builder(
//           shrinkWrap: true,
//           itemCount: widget.requiredFields.length,
//           itemBuilder: (context, index) {
//             return ListTile(
//               title: Text(widget.requiredFields[index]['field']!),
//               trailing: IconButton(
//                 icon: Icon(Icons.remove_circle_outline),
//                 onPressed: () {
//                   setState(() {
//                     widget.requiredFields.removeAt(index); // Remove the field
//                   });
//                 },
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }
// }
