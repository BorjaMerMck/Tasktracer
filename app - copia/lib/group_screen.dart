import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';

class GroupScreen extends StatefulWidget {
  @override
  _GroupScreenState createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool showCreateHome = false;
  bool showJoinHome = false;
  bool isPasswordVisible = false;

  List<String> userHomeGroups = [];
  String? selectedHomeGroup;

  final TextEditingController homeNameController = TextEditingController();
  final TextEditingController homePasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  Future<void> _fetchUserGroups() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final QuerySnapshot snapshot = await _firestore.collection('homes').get();
        List<String> groups = [];

        for (var doc in snapshot.docs) {
          final List<dynamic> members = doc['members'];
          if (members.any((member) => member['uid'] == user.uid)) {
            groups.add(doc['homeName']);
          }
        }

        setState(() {
          userHomeGroups = groups;
          if (userHomeGroups.isNotEmpty) {
            selectedHomeGroup = userHomeGroups[0];
          }
        });

        if (userHomeGroups.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener los grupos del usuario: $e')),
        );
      }
    }
  }

  Future<void> _createHome() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('homes').doc(homeNameController.text).set({
          'homeName': homeNameController.text,
          'homePassword': homePasswordController.text,
          'members': [
            {
              'uid': user.uid,
              'email': user.email,
            }
          ],
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el hogar: $e')),
      );
    }
  }

  Future<void> _joinHome() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('homes').doc(homeNameController.text).get();
        if (doc.exists && doc['homePassword'] == homePasswordController.text) {
          await _firestore.collection('homes').doc(homeNameController.text).update({
            'members': FieldValue.arrayUnion([
              {
                'uid': user.uid,
                'email': user.email,
              }
            ])
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hogar o contraseña incorrectos')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al unirse al hogar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grupos de Hogar'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Administración De Hogares',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 20),
              if (userHomeGroups.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus hogares:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ...userHomeGroups.map((group) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Text(
                            '- $group',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        )),
                  ],
                )
              else
                Text(
                  'No estás asociado a ningún hogar.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              SizedBox(height: 30),
              if (showCreateHome) _buildHomeForm('Registrar Domicilio', _createHome),
              if (showJoinHome) _buildHomeForm('Unirse a Hogar', _joinHome),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showCreateHome = !showCreateHome;
                        showJoinHome = false;
                      });
                    },
                    icon: Icon(Icons.add_home),
                    label: Text(
                      'Crear Hogar',
                      style: TextStyle(color: Colors.blue), // Texto en azul
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Fondo blanco
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showJoinHome = !showJoinHome;
                        showCreateHome = false;
                      });
                    },
                    icon: Icon(Icons.home_work_outlined),
                    label: Text(
                      'Unirse a Hogar',
                      style: TextStyle(color: Colors.blue), // Texto en azul
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Fondo blanco
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeForm(String buttonText, Function onSubmit) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: homeNameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Hogar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: homePasswordController,
              decoration: InputDecoration(
                labelText: 'Contraseña del Hogar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[200],
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !isPasswordVisible,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => onSubmit(),
              child: Text(
                buttonText,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
