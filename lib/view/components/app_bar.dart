import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Color backgroundColor;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor = Colors.blue, // Cor padrão caso nenhuma seja enviada
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          if (showBackButton) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color.fromARGB(255, 136, 207, 193),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFD6D6D6),
            child: Icon(Icons.person, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(width: 12),
          const Text(
            'GRAZI BRAZ',
            style: TextStyle(
              color: Color(0xFF005A4F),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black87,
              size: 24,
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  // Define a altura padrão da AppBar (geralmente kToolbarHeight, que é 56.0)
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
