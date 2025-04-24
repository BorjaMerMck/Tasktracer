import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';

class AjustesScreen extends StatefulWidget {
  @override
  _AjustesScreenState createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String selectedHomeGroup = 'Selecciona un grupo';
  List<String> userHomeGroups = [];
  List<String> homeMembersEmails = [];

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  Future<void> _fetchUserGroups() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore.collection('homes').get();
        List<String> groups = [];

        for (var doc in snapshot.docs) {
          final List<dynamic> members = doc['members'];
          for (var member in members) {
            if (member is Map && member['uid'] == user.uid) {
              groups.add(doc['homeName']);
              break;
            }
          }
        }

        setState(() {
          userHomeGroups = groups;
          if (userHomeGroups.isNotEmpty) selectedHomeGroup = userHomeGroups[0];
        });

        if (selectedHomeGroup != 'Selecciona un grupo') {
          _fetchHomeMembers(selectedHomeGroup);
        }
      } catch (e) {
        print('Error al obtener los grupos del usuario: $e');
      }
    }
  }

  Future<void> _fetchHomeMembers(String homeName) async {
    try {
      final homeDoc = await _firestore
          .collection('homes')
          .where('homeName', isEqualTo: homeName)
          .limit(1)
          .get();
      if (homeDoc.docs.isNotEmpty) {
        final List<dynamic> members = homeDoc.docs.first['members'];
        List<String> emails = [];

        for (var member in members) {
          if (member is Map && member.containsKey('email')) {
            emails.add(member['email']);
          }
        }

        setState(() {
          homeMembersEmails = emails;
        });
      }
    } catch (e) {
      print('Error al obtener los miembros del hogar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://cdn.icon-icons.com/icons2/294/PNG/256/Users_31113.png',
              ),
              backgroundColor: Colors.blue[100],
            ),
            SizedBox(height: 20),
            Card(
              margin: EdgeInsets.symmetric(vertical: 10),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      user?.email?.split('@')[0] ?? 'Usuario',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      user?.email ?? 'Correo no disponible',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedHomeGroup,
                      items: userHomeGroups
                          .map((group) => DropdownMenuItem<String>(
                        value: group,
                        child: Text(group),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedHomeGroup = value ?? 'Selecciona un grupo';
                          homeMembersEmails = [];
                        });
                        if (value != null) {
                          _fetchHomeMembers(value);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Grupo de Hogar',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: homeMembersEmails.isNotEmpty
                  ? ListView.builder(
                itemCount: homeMembersEmails.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.person, color: Colors.blueAccent),
                    title: Text(homeMembersEmails[index]),
                  );
                },
              )
                  : Center(
                child: Text(
                  'No hay otros miembros en el hogar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              icon: Icon(Icons.logout),
              label: Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                backgroundColor: Colors.blue,
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
