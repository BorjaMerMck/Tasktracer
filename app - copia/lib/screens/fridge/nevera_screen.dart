import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'models/product.dart';
import 'widgets/product_card.dart';

class NeveraScreen extends StatefulWidget {
  @override
  _NeveraScreenState createState() => _NeveraScreenState();
}

class _NeveraScreenState extends State<NeveraScreen> with SingleTickerProviderStateMixin {
  final List<String> columns = ['En Nevera', 'Por Comprar'];
  final List<String> categories = ['Lácteos', 'Frutas', 'Verduras', 'Granos', 'Otros'];

  Map<String, int> productClicks = {};
  List<Product> products = [];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String homeId = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fetchUserHomeProducts();
  }

  Future<void> _fetchUserHomeProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore.collection('homes').where('members', arrayContains: {
        'uid': user.uid,
        'email': user.email,
      }).get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          homeId = snapshot.docs.first.id;
        });
        await _loadProducts();
      }
    }
  }

  Future<void> _loadProducts() async {
    final snapshot = await _firestore.collection('homes').doc(homeId).collection('products').get();
    setState(() {
      products = snapshot.docs.map((doc) {
        final product = Product.fromDocument(doc);
        productClicks[product.id] = product.clickCount;
        return product;
      }).toList();
    });
  }

  Future<void> _addNewProduct(String name, String category) async {
    final newProduct = Product(
      id: '',
      name: name,
      status: 'Por Comprar',
      category: category,
    );

    final doc = await _firestore.collection('homes').doc(homeId).collection('products').add({
      ...newProduct.toMap(),
      'clickCount': 0,
    });

    setState(() {
      products.add(Product(
        id: doc.id,
        name: name,
        status: 'Por Comprar',
        category: category,
      ));
      productClicks[doc.id] = 0;
    });
  }

  Future<void> _moveProduct(Product product, String newStatus) async {
    setState(() => product.status = newStatus);
    await _firestore.collection('homes').doc(homeId).collection('products').doc(product.id).update({
      'status': newStatus,
    });
    _animationController.forward(from: 0);
  }

  Future<void> _deleteProduct(String id) async {
    await _firestore.collection('homes').doc(homeId).collection('products').doc(id).delete();
    setState(() {
      products.removeWhere((p) => p.id == id);
    });
  }

  void _handleProductClick(Product product, String status) {
    setState(() {
      if (status == 'En Nevera') {
        productClicks[product.id] = (productClicks[product.id] ?? 0) - 1;
        if (productClicks[product.id]! < 0) productClicks[product.id] = 0;
      } else {
        productClicks[product.id] = (productClicks[product.id] ?? 0) + 1;
      }
    });
    _updateProductClickCount(product.id, productClicks[product.id]!);
  }

  void _updateProductClickCount(String id, int count) {
    _firestore.collection('homes').doc(homeId).collection('products').doc(id).update({
      'clickCount': count,
    });
  }

  void _showAddProductDialog() {
    String name = '';
    String category = categories[0];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nuevo Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.shopping_cart),
              label: Text('Añadir productos de Mercadona'),
              onPressed: () {
                Navigator.pop(context);
                _showMercadonaProductsDialog();
              },
            ),
            const SizedBox(height: 10),
            const Text('O añade un producto manualmente:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => name = value,
              decoration: InputDecoration(
                hintText: "Nombre del producto",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              onChanged: (value) => category = value!,
              decoration: InputDecoration(labelText: "Categoría", border: OutlineInputBorder()),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) _addNewProduct(name, category);
              Navigator.pop(context);
            },
            child: Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _showMercadonaProductsDialog() async {
    showDialog(context: context, builder: (_) => Center(child: CircularProgressIndicator()));
    try {
      final res = await http.get(Uri.parse('https://tienda.mercadona.es/api/categories/'));
      Navigator.pop(context);
      if (res.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> categories = jsonData['results'] ?? [];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Categorías de Mercadona'),
            content: categories.isEmpty
                ? Text('No se encontraron categorías.')
                : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, i) {
                  final cat = categories[i];
                  return ListTile(
                    title: Text(cat['name'] ?? 'Sin nombre'),
                    onTap: () {
                      Navigator.pop(context);
                      _showSubcategoriesDialog(cat['name'], cat['categories'] ?? []);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar')),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('Error al obtener categorías: $e'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Aceptar'))],
        ),
      );
    }
  }

  void _showSubcategoriesDialog(String category, List<dynamic> subs) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Subcategorías de $category'),
        content: subs.isEmpty
            ? Text('No se encontraron subcategorías.')
            : SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: subs.length,
            itemBuilder: (context, i) {
              final sub = subs[i];
              return ListTile(
                title: Text(sub['name'] ?? 'Sin nombre'),
                onTap: () {
                  _addNewProduct(sub['name'], 'Otros');
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar'))],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nevera - Kanban'),
        backgroundColor: Colors.blue,
      ),
      body: Row(
        children: columns.map((status) {
          return Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(status, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: DragTarget<Product>(
                      onAccept: (product) => _moveProduct(product, status),
                      builder: (_, __, ___) => ListView(
                        children: products.where((p) => p.status == status).map((p) {
                          return ScaleTransition(
                            scale: _scaleAnimation,
                            child: Draggable<Product>(
                              data: p,
                              feedback: Material(
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  color: Colors.blueAccent,
                                  child: Text('${p.name} (${p.category})',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child: _buildProductStack(p, status),
                              ),
                              child: _buildProductStack(p, status),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildProductStack(Product product, String status) {
    return GestureDetector(
      onTap: () => _handleProductClick(product, status),
      onLongPress: () => _deleteProduct(product.id),
      child: Stack(
        children: [
          ProductCard(name: product.name, category: product.category),
          if ((productClicks[product.id] ?? 0) > 0)
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.red,
                child: Text('${productClicks[product.id]}',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
