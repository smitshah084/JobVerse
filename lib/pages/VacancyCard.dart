import 'package:flutter/material.dart';
import 'Vacancy.dart';

class VacancyCard extends StatelessWidget {
  final Vacancy vacancy;
  final VoidCallback onIncreaseIntake;
  final VoidCallback onDecreaseIntake;

  VacancyCard({
    required this.vacancy,
    required this.onIncreaseIntake,
    required this.onDecreaseIntake,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vacancy.position,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Company: ${vacancy.company}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Intake: ${vacancy.intake}',
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: onDecreaseIntake,
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: onIncreaseIntake,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
