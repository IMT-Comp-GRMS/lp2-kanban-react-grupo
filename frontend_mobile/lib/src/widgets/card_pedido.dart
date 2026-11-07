import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/historico_model.dart';
import '../models/pedido_model.dart';

class CardPedidoWidget extends StatefulWidget {
  final PedidoModel pedido;
  // null quando o pedido já está na primeira/última coluna
  final VoidCallback? onVoltar;
  final VoidCallback? onAvancar;
  final VoidCallback? onExcluir;

  const CardPedidoWidget({
    super.key,
    required this.pedido,
    this.onVoltar,
    this.onAvancar,
    this.onExcluir,
  });

  static const Map<int, Color> coresPrioridade = {
    1: Color(0xFFAE4F48),
    2: Color(0xFFA79261),
    3: Color(0xFF3C5262),
  };

  @override
  State<CardPedidoWidget> createState() => _CardPedidoWidgetState();
}

class _CardPedidoWidgetState extends State<CardPedidoWidget> {
  // Microsserviço Histórico (NodePort do historico-service)
  static const String historicoUrl = 'http://localhost:30005';

  List<HistoricoModel> historico = [];
  bool mostrarHistorico = false;
  bool carregandoHistorico = false;

  // GET /historico/:pedido_id (igual ao handleVerHistorico do CardPedido.jsx)
  Future<void> alternarHistorico() async {
    if (mostrarHistorico) {
      setState(() => mostrarHistorico = false);
      return;
    }

    setState(() => carregandoHistorico = true);
    List<HistoricoModel> dados = [];
    try {
      final resposta = await http.get(
        Uri.parse('$historicoUrl/historico/${widget.pedido.id}'),
      );
      // O serviço responde 404 quando o pedido ainda não tem movimentações
      if (resposta.statusCode == 200) {
        final List<dynamic> json = jsonDecode(utf8.decode(resposta.bodyBytes));
        dados = json.map((item) => HistoricoModel.fromJSON(item)).toList();
      }
    } catch (e) {
      dados = [];
    }
    if (!mounted) return;
    setState(() {
      historico = dados;
      carregandoHistorico = false;
      mostrarHistorico = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;
    final onVoltar = widget.onVoltar;
    final onAvancar = widget.onAvancar;
    final Color corBorda = CardPedidoWidget.coresPrioridade[pedido.prioridade] ?? const Color(0xFF3C5262);
    final String descricao = pedido.descricao;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: corBorda, width: 6),
          top: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: ${pedido.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF071227),
                  ),
                ),
              ),
              // Lixeira no canto superior direito, como no CardPedido.jsx
              if (widget.onExcluir != null)
                IconButton(
                  onPressed: widget.onExcluir,
                  tooltip: 'Excluir Pedido',
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFAE4F48), size: 20),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pedido.titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (descricao.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              descricao,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Responsável: ${pedido.responsavel}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA79261),
            ),
          ),
          if (onVoltar != null || onAvancar != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onVoltar != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onVoltar,
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: const Text('Voltar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3C5262),
                        side: const BorderSide(color: Color(0xFF3C5262)),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ),
                if (onVoltar != null && onAvancar != null) const SizedBox(width: 5),
                if (onAvancar != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAvancar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C5262),
                        foregroundColor: const Color(0xFFF6F0E7),
                        elevation: 0,
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Avançar'),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 14),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: carregandoHistorico ? null : alternarHistorico,
              icon: Icon(
                mostrarHistorico ? Icons.keyboard_arrow_up : Icons.assignment_outlined,
                size: 14,
              ),
              label: Text(
                carregandoHistorico
                    ? 'Carregando...'
                    : mostrarHistorico
                        ? 'Fechar Histórico'
                        : 'Ver Histórico',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: mostrarHistorico ? const Color(0xFFF6F0E7) : const Color(0xFFA79261),
                backgroundColor: mostrarHistorico ? const Color(0xFFA79261) : Colors.transparent,
                side: const BorderSide(color: Color(0xFFA79261)),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(vertical: 6),
                minimumSize: const Size(0, 30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          if (mostrarHistorico) ...[
            const SizedBox(height: 5),
            if (historico.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Nenhuma movimentação registrada.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(3),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  const TableRow(
                    decoration: BoxDecoration(
                      color: Color(0xFFF6F0E7),
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    children: [
                      _CelulaHistorico('De', cor: Color(0xFF3C5262), negrito: true),
                      _CelulaHistorico('Para', cor: Color(0xFF3C5262), negrito: true),
                      _CelulaHistorico('Data/Hora', cor: Color(0xFF3C5262), negrito: true),
                    ],
                  ),
                  for (final linha in historico)
                    TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF6F0E7))),
                      ),
                      children: [
                        _CelulaHistorico(
                          linha.statusAnterior,
                          cor: const Color(0xFFAE4F48),
                        ),
                        _CelulaHistorico(
                          linha.statusNovo,
                          cor: const Color(0xFF3C5262),
                        ),
                        _CelulaHistorico(
                          linha.dataHora,
                          cor: const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

// Célula da tabela de histórico do card
class _CelulaHistorico extends StatelessWidget {
  final String texto;
  final Color cor;
  final bool negrito;

  const _CelulaHistorico(this.texto, {required this.cor, this.negrito = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          color: cor,
          fontWeight: negrito ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
