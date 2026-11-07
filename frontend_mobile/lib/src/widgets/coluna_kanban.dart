import 'package:flutter/material.dart';

import '../models/pedido_model.dart';
import 'card_pedido.dart';

// Uma coluna do Kanban: cabeçalho colorido com o total e a lista de cards.
// Recebe os pedidos já filtrados e ordenados pela tela.
class ColunaKanban extends StatelessWidget {
  final String titulo;
  final Color cor;
  final List<PedidoModel> pedidos;
  // Texto mostrado quando a coluna não tem pedidos
  final String mensagemVazia;
  final void Function(PedidoModel pedido) onExcluir;
  // null na primeira coluna (não há para onde voltar) e na última (avançar)
  final void Function(PedidoModel pedido)? onVoltar;
  final void Function(PedidoModel pedido)? onAvancar;

  const ColunaKanban({
    super.key,
    required this.titulo,
    required this.cor,
    required this.pedidos,
    required this.mensagemVazia,
    required this.onExcluir,
    this.onVoltar,
    this.onAvancar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
            ),
            child: Text(
              '${titulo.toUpperCase()} (${pedidos.length})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: pedidos.isEmpty
                ? Center(
                    child: Text(
                      mensagemVazia,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: pedidos.length,
                    itemBuilder: (context, i) {
                      final pedido = pedidos[i];
                      return CardPedidoWidget(
                        key: ValueKey(pedido.id),
                        pedido: pedido,
                        onExcluir: () => onExcluir(pedido),
                        onVoltar: onVoltar == null ? null : () => onVoltar!(pedido),
                        onAvancar: onAvancar == null ? null : () => onAvancar!(pedido),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
