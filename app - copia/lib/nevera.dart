import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


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
      clickCount: doc['clickCount'] ?? 0, // Asegura 0 si no está definido en Firestore.
    );
  }
}


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
    _fetchUserHomeProducts(); // Fetch products from Firebase on start
  }




  Future<void> _fetchUserHomeProducts() async {
    final user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot snapshot = await _firestore.collection('homes').where('members', arrayContains: {
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
  try {
    final productsSnapshot = await _firestore
        .collection('homes')
        .doc(homeId)
        .collection('products')
        .get();

    setState(() {
      products = productsSnapshot.docs.map((doc) {
        final product = Product.fromDocument(doc);

        // Actualiza el mapa de clics con los valores desde Firestore.
        productClicks[product.id] = product.clickCount;

        return product;
      }).toList();
    });
  } catch (e) {
    print("Error loading products: $e");
  }
}

Future<void> _addNewProduct(String productName, String category) async {
  final newProduct = Product(
    id: '',
    name: productName,
    status: 'Por Comprar',
    category: category,
    clickCount: 0, // Inicializa en 0.

  );
  final productDoc = await _firestore
      .collection('homes')
      .doc(homeId)
      .collection('products')
      .add({...newProduct.toMap(), 'clickCount': 0});

  setState(() {
    products.add(Product(
      id: productDoc.id,
      name: productName,
      status: 'Por Comprar',
      category: category,
      clickCount: 0,

    ));
        productClicks[productDoc.id] = 0; // Inicializa en el mapa.

  });
}


  Future<void> _moveProduct(Product product, String newStatus) async {
    setState(() {
      product.status = newStatus;
    });
    await _firestore.collection('homes').doc(homeId).collection('products').doc(product.id).update({
      'status': newStatus,
    });
    _animationController.forward(from: 0); // Restart the animation
  }

  Future<void> _deleteProduct(String productId) async {
  try {
    // Eliminar de Firebase
    await _firestore.collection('homes').doc(homeId).collection('products').doc(productId).delete();
    // Eliminar de la lista local
    setState(() {
      products.removeWhere((product) => product.id == productId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Producto eliminado exitosamente')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al eliminar el producto: $e')),
    );
  }
}


void _handleProductClick(Product product, String status) {
  setState(() {
    if (status == 'En Nevera') {
      // Decrementar si está en "En Nevera"
      productClicks[product.id] = (productClicks[product.id] ?? 0) - 1;
      if (productClicks[product.id]! < 0) {
        productClicks[product.id] = 0; // Evitar valores negativos
      }
    } else {
      // Incrementar normalmente en otros estados
      productClicks[product.id] = (productClicks[product.id] ?? 0) + 1;
    }
  });

  // Guardar el nuevo conteo en Firestore
  _updateProductClickCount(product.id, productClicks[product.id]!);
}


void _updateProductClickCount(String productId, int clickCount) async {
  try {
    await _firestore
        .collection('homes')
        .doc(homeId)
        .collection('products')
        .doc(productId)
        .update({'clickCount': clickCount});
  } catch (e) {
    print('Error al actualizar el conteo de clics: $e');
  }
}


  void _showAddProductDialog() {
    String newProduct = '';
    String selectedCategory = categories[0];

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo actual
                _showMercadonaProductsDialog(); // Muestra los productos de Mercadona
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'O añade un producto manualmente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) {
                newProduct = value;
              },
              decoration: InputDecoration(
                hintText: "Nombre del producto",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              onChanged: (value) {
                setState(() {
                  selectedCategory = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Categoría",
                border: OutlineInputBorder(),
              ),
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (newProduct.isNotEmpty) {
                _addNewProduct(newProduct, selectedCategory);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _showMercadonaProductsDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse('https://tienda.mercadona.es/api/categories/'),
      );

      Navigator.of(context).pop(); // Cerramos el indicador de carga

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes)); // Decodificación UTF-8
        final List<dynamic> categories = jsonData['results'] ?? [];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Categorías de Mercadona'),
            content: categories.isEmpty
                ? const Text('No se encontraron categorías en la API.')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final categoryName = category['name'] ?? 'Sin nombre';
                        final subcategories = category['categories'] ?? [];

                        return ListTile(
                          title: Text(categoryName),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.of(context).pop(); // Cierra el diálogo actual
                            _showSubcategoriesDialog(categoryName, subcategories);
                          },
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                },
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error al obtener categorías: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                },
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el indicador de carga

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error al obtener categorías: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  void _showSubcategoriesDialog(String categoryName, List<dynamic> subcategories) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subcategorías de $categoryName'),
        content: subcategories.isEmpty
            ? const Text('No se encontraron subcategorías.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    final subcategoryName = subcategory['name'] ?? 'Sin nombre';

                    return ListTile(
                      title: Text(subcategoryName),
                      onTap: () {
                        _addNewProduct(subcategoryName, 'Otros'); // Por defecto categoría "Otros"
                        Navigator.of(context).pop(); // Cierra el diálogo
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nevera - Kanban'),
        backgroundColor: Colors.blue,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((status) {
          return Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.grey[200],
                    child: DragTarget<Product>(
                      onAccept: (product) {
                        _moveProduct(product, status);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return ListView(
                          children: products
                              .where((product) => product.status == status)
                              .map((product) => ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Draggable<Product>(
                                      data: product,
                                      feedback: Material(
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          color: Colors.blueAccent,
                                          child: Text(
                                            '${product.name} (${product.category})',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.5,
                                        child: GestureDetector(
                                          onTap: () => _handleProductClick(product, status),
                                          onLongPress: () => _deleteProduct(product.id),
                                          child: Stack(
                                            children: [
                                              ProductCard(
                                                name: product.name,
                                                category: product.category,
                                              ),
                                              if ((productClicks[product.id] ?? 0) > 0)
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: CircleAvatar(
                                                    radius: 12,
                                                    backgroundColor: Colors.red,
                                                    child: Text(
                                                      '${productClicks[product.id]}',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _handleProductClick(product, status),
                                        onLongPress: () => _deleteProduct(product.id),
                                        child: Stack(
                                          children: [
                                            ProductCard(
                                              name: product.name,
                                              category: product.category,
                                            ),
                                            if ((productClicks[product.id] ?? 0) > 0)
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: Colors.red,
                                                  child: Text(
                                                    '${productClicks[product.id]}',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        );
                      },
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
        tooltip: 'Añadir nuevo producto',
      ),
    );
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
class ProductCard extends StatelessWidget {
  final String name;
  final String category;
  final VoidCallback? onDelete; // Ahora es opcional

  ProductCard({required this.name, required this.category, this.onDelete});

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
            : null, // Si onDelete es nulo, no mostramos el botón
      ),
    );
  }
}
