import 'package:flutter/material.dart';
import '../tasks/todo_screen.dart';
import '../fridge/nevera_screen.dart';
import '../settings/ajustes_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ToDoScreen(),
    NeveraScreen(),
    AjustesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check_outlined, color: Theme.of(context).primaryColor),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.production_quantity_limits_rounded),
            activeIcon: Icon(Icons.production_quantity_limits_rounded, color: Theme.of(context).primaryColor),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            activeIcon: Icon(Icons.settings, color: Theme.of(context).primaryColor),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
