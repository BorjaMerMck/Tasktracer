import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String id;
  String name;
  String status;
  String category;
  int clickCount;

  Product({
    required this.id,
    required this.name,
    required this.status,
    required this.category,
    this.clickCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'status': status,
      'category': category,
      'clickCount': clickCount,
    };
  }

  factory Product.fromDocument(DocumentSnapshot doc) {
    return Product(
      id: doc.id,
      name: doc['name'] ?? '',
      status: doc['status'] ?? '',
      category: doc['category'] ?? '',
      clickCount: doc['clickCount'] ?? 0,
    );
  }
}
