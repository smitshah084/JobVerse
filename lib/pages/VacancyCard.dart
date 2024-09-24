import 'package:flutter/material.dart';
import 'Vacancy.dart';

class VacancyCard extends StatelessWidget {
  final Vacancy vacancy;
  final VoidCallback onView;

  VacancyCard({
    required this.vacancy,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5, // Adds shadow
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Spacing around the card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vacancy.position,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.business, color: Colors.grey[700]),
                SizedBox(width: 8),
                Text(
                  vacancy.company,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.group, color: Colors.grey[700]),
                SizedBox(width: 8),
                Text(
                  'Intakes: ${vacancy.intake}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                ),
              ],
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: onView,
                icon: Icon(Icons.visibility, size: 18),
                label: Text('View Details', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
