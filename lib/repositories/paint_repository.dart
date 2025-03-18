import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miniature_paint_finder/models/paint.dart';

class PaintRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'paints';

  // Get all paints from Firestore
  Future<List<Paint>> getAllPaints() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return Paint.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting paints: $e');
      return [];
    }
  }

  // Get paints by brand
  Future<List<Paint>> getPaintsByBrand(String brand) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('brand', isEqualTo: brand)
              .get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return Paint.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting paints by brand: $e');
      return [];
    }
  }

  // Add a new paint to Firestore
  Future<bool> addPaint(Paint paint) async {
    try {
      await _firestore.collection(_collection).add(paint.toJson());
      return true;
    } catch (e) {
      print('Error adding paint: $e');
      return false;
    }
  }

  // Update an existing paint
  Future<bool> updatePaint(Paint paint) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(paint.id)
          .update(paint.toJson());
      return true;
    } catch (e) {
      print('Error updating paint: $e');
      return false;
    }
  }

  // Delete a paint
  Future<bool> deletePaint(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting paint: $e');
      return false;
    }
  }
}
