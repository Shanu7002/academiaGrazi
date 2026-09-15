import 'package:academiagrazi/view/user/alunoHome_view.dart';
import 'package:academiagrazi/view/user/alunoProfile.dart';
import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => MenuState();
}

class MenuState extends State<Menu> {
  int _selectedIndex = 0;

  final List<Widget> _paginas = const [
    AlunoHomeView(),
    Center(child: Text('Página de Treino')),
    Center(child: Text('Página de Evolução')),
    AlunoProfileView(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Treinos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Evolução',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
