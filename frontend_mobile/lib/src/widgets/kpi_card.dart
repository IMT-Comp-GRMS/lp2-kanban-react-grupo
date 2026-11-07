import 'package:flutter/material.dart';

import 'paleta.dart';

// Equivalente ao KpiCard.jsx
class KpiCard extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String titulo;
  final int valor;
  final Color cor;

  const KpiCard({
    super.key,
    required this.icone,
    required this.corIcone,
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Paleta.borda),
      ),
      child: Row(
        children: [
          Icon(icone, color: corIcone, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Paleta.cinzaTexto,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$valor',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: cor, height: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
