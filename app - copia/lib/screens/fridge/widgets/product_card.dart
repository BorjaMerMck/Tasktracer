import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final VoidCallback? onDelete;

  const ProductCard({
    required this.name,
    required this.category,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(Icons.kitchen, color: Colors.blue),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(category),
        trailing: onDelete != null
            ? IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Eliminar producto',
        )
            : null,
      ),
    );
  }
}
