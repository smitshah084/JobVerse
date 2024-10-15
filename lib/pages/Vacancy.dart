class Vacancy {
  final String position;
  final String company;
  final int intake;
  final String description;
  final String jobType;
  final String vacancyId;
  final List<FormFieldData> formFields; // New field for dynamic fields

  Vacancy({
    required this.position,
    required this.company,
    required this.intake,
    required this.description,
    required this.jobType,
    required this.vacancyId,
    required this.formFields,
  });
}

class FormFieldData {
  final String label;
  final String type; // Can be "text", "number", "email", etc.
  final bool isRequired;

  FormFieldData({
    required this.label,
    required this.type,
    required this.isRequired,
  });
}
