import 'package:flutter/material.dart';

void main() {
  runApp(const VelatoApp());
}

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

class KanbanScreen extends StatelessWidget {
  const KanbanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> colunas = [
      {'titulo': 'Pedidos', 'cor': const Color(0xFF3C5262)},
      {'titulo': 'Pagamento Confirmado', 'cor': const Color(0xFFA79261)},
      {'titulo': 'Pedido separado', 'cor': const Color(0xFFAE4F48)},
      {'titulo': 'Pedido Enviado', 'cor': const Color(0xFF252623)},
      {'titulo': 'Pedido Entregue', 'cor': const Color(0xFF3C5262)},
    ];

    final List<Map<String, dynamic>> pedidosMock = [
      {
        'id': 101,
        'titulo': 'Mesa Mesa 04',
        'descricao': '2x Hambúrguer, 1x Coca',
        'responsavel': 'João',
        'prioridade': 1,
        'status': 'Pedidos'
      },
      {
        'id': 102,
        'titulo': 'Delivery Ifood',
        'descricao': '1x Pizza Marguerita',
        'responsavel': 'Maria',
        'prioridade': 2,
        'status': 'Pagamento Confirmado'
      },
      {
        'id': 103,
        'titulo': 'Mesa 12',
        'descricao': 'Sobremesa',
        'responsavel': 'Carlos',
        'prioridade': 3,
        'status': 'Pedido separado'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F0E7),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: const Color(0xFF3C5262), height: 2.0),
        ),
        title: Row(
          children: [
            const Text(
              'VELATO',
              style: TextStyle(
                color: Color(0xFF252623),
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                fontSize: 22,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 20,
              width: 1,
              color: const Color(0xFF3C5262),
            ),
            const Text(
              'Orders',
              style: TextStyle(
                color: Color(0xFFA79261),
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Color(0xFFF6F0E7)),
            label: const Text('Novo Pedido', style: TextStyle(color: Color(0xFFF6F0E7))),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFAE4F48),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0, left: 16.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: colunas.length,
          itemBuilder: (context, index) {
            final coluna = colunas[index];
            final pedidosDaColuna = pedidosMock.where((p) => p['status'] == coluna['titulo']).toList();

            return Container(
              width: 280,
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
                      color: coluna['cor'],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                    child: Text(
                      coluna['titulo'].toString().toUpperCase(),
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
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: pedidosDaColuna.length,
                      itemBuilder: (context, i) {
                        return CardPedidoWidget(pedido: pedidosDaColuna[i]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class CardPedidoWidget extends StatelessWidget {
  final Map<String, dynamic> pedido;

  const CardPedidoWidget({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    Color corPrioridade = const Color(0xFF3C5262);
    if (pedido['prioridade'] == 1) corPrioridade = const Color(0xFFAE4F48);
    if (pedido['prioridade'] == 2) corPrioridade = const Color(0xFFA79261);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: corPrioridade, width: 6),
          top: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ID: ${pedido['id']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF071227))),
              const Icon(Icons.delete_outline, color: Color(0xFFAE4F48), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(pedido['titulo'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(pedido['descricao'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Responsável: ${pedido['responsavel']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFA79261))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3C5262),
                    side: const BorderSide(color: Color(0xFF3C5262)),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('⬅ Voltar', style: TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C5262),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Avançar ➡', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}