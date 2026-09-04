import 'package:academiagrazi/login_view.dart';
import 'package:academiagrazi/register_view.dart';
import 'package:flutter/material.dart';

class menu extends StatefulWidget {
  const menu({super.key});

  @override
  State<menu> createState() => _menuState();
}

class _menuState extends State<menu> {
  int _selectedIndex = 0;

  final List<Widget> _paginas = const [
    LoginView(),
    RegisterView(),
    Center(child: Text('Página de Evolução')),
    Center(child: Text('Página de Perfil')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _paginas[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Treinos'),
          BottomNavigationBarItem(icon: Icon(Icons.insights), label: 'Evolução'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
