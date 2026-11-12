import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/components/brand_heading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Saudação do topo dos painéis: `OLÁ / Primeiro nome` de quem está logado,
/// no padrão de título do manual de marca. Sem nome, mostra só "OLÁ".
class UserGreeting extends StatefulWidget {
  final String? description;

  const UserGreeting({super.key, this.description});

  @override
  State<UserGreeting> createState() => _UserGreetingState();
}

class _UserGreetingState extends State<UserGreeting> {
  Future<UserModel?>? _user;

  @override
  void initState() {
    super.initState();
    // Sem os services no locator (testes isolados), fica só o "OLÁ".
    if (locator.isRegistered<FirebaseAuth>() &&
        locator.isRegistered<RegisterUserService>()) {
      final uid = locator<FirebaseAuth>().currentUser?.uid;
      if (uid != null) {
        _user = locator<RegisterUserService>().getUserById(uid);
      }
    }
  }

  static String? _firstName(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    return parts.first.isEmpty ? null : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _user,
      builder:
          (context, snapshot) => BrandHeading(
            'Olá',
            complement: _firstName(snapshot.data?.name),
            description: widget.description,
          ),
    );
  }
}
