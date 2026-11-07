import 'package:flutter/material.dart';

import 'paleta.dart';

// Caixa branca com título, usada pelos dois gráficos
class Painel extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final Widget child;

  const Painel({super.key, required this.icone, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Paleta.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: Paleta.azul, size: 16),
              const SizedBox(width: 6),
              Text(
                titulo.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Paleta.azul,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}
