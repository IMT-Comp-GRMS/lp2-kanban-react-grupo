import 'package:flutter/material.dart';

import 'telas/kanban_tela.dart';

// Widget raiz do app. Como na apostila Flutter App de Fotos, o MaterialApp
// fica em lib/src/app.dart e o main.dart só chama runApp.
class VelatoApp extends StatelessWidget {
  const VelatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velato Kanban',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F0E7),
        fontFamily: 'Inter',
      ),
      home: const KanbanScreen(),
    );
  }
}
