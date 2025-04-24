import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.lightGray,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/fotomain.png',
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
              '¡Bienvenido a Tasktraker!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: MyTheme.darkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Organiza tus tareas diarias y gestiona los productos de tu nevera con facilidad.',
              style: TextStyle(fontSize: 18, color: MyTheme.darkBlue),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text(
                'Comenzar',
                style: TextStyle(fontSize: 20, color: MyTheme.white),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: MyTheme.mintGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
