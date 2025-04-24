import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String name;
  String category;
  String assignedTo;
  bool isCompleted;
  bool isDaily;
  List<String> repeatDays;
  bool isExpanded;

  Task({
    required this.id,
    required this.name,
    required this.category,
    required this.assignedTo,
    this.isCompleted = false,
    this.isDaily = false,
    this.repeatDays = const [],
    this.isExpanded = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
      'isDaily': isDaily,
      if (repeatDays.isNotEmpty) 'repeatDays': repeatDays,
    };
  }

  factory Task.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      name: data['name'],
      category: data['category'],
      assignedTo: data['assignedTo'],
      isCompleted: data['isCompleted'] ?? false,
      isDaily: data['isDaily'] ?? false,
      repeatDays: List<String>.from(data['repeatDays'] ?? []),
    );
  }
}