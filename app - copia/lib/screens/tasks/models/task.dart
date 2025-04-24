import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String name;
  String category;
  String assignedTo;
  bool isCompleted;

  Task({
    required this.id,
    required this.name,
    required this.category,
    required this.assignedTo,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'assignedTo': assignedTo,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromDocument(DocumentSnapshot doc) {
    return Task(
      id: doc.id,
      name: doc['name'],
      category: doc['category'],
      assignedTo: doc['assignedTo'],
      isCompleted: doc['isCompleted'],
    );
  }
}
