class JobOpening {
  final String id;
  final String title;
  final String description;
  final List<FormFieldData> formFields;

  JobOpening({
    required this.id,
    required this.title,
    required this.description,
    required this.formFields,
  });
}

class FormFieldData {
  final String label;
  final String type; // Field type (text, number, email, etc.)
  final bool isRequired;

  FormFieldData({
    required this.label,
    required this.type,
    required this.isRequired,
  });
}