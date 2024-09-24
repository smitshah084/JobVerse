import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VacancyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteVacancy(String documentId) async {
    try {
      // Fetch and delete applications associated with the vacancy
      QuerySnapshot applicationsSnapshot = await _firestore
          .collection('applications')
          .where('vacancyId', isEqualTo: documentId)
          .get();

      for (var application in applicationsSnapshot.docs) {
        await _firestore.collection('applications').doc(application.id).delete();
      }

      // Delete the vacancy
      await _firestore.collection('vacancies').doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete vacancy: $e');
    }
  }
}
