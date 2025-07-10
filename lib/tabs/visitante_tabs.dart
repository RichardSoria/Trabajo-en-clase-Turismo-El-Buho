import 'package:flutter/material.dart';
import 'package:mi_supabase_flutter/visitor_page.dart';
import 'package:mi_supabase_flutter/visitor_profile_page.dart';

class VisitanteTabs extends StatefulWidget {
  const VisitanteTabs({super.key});

  @override
  State<StatefulWidget> createState() => _visitanteTabsState();
}

class _visitanteTabsState extends State<VisitanteTabs> {
  int _selectedIndex = 0;

  final List<Widget> _pages = 
  [
    LugaresVisitantePage(),
    VisitorProfilePage()
  ];

  void _onItemTapped(int index)
  {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil")
        ]
      ),
    );
  }
}