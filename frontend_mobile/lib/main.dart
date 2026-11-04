import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  static const String baseUrl = 'http://localhost:3001';

  List<dynamic> produtos = [];
  bool carregando = true;
  String? mensagemErro;

  final List < Map < String , dynamic > > colunas = [
   {'titulo': 'Pedidos', 'cor': const Color(0xFF3C5262)},
    {'titulo': 'Pagamento Confirmado', 'cor': const Color(0xFFA79261)},
    {'titulo': 'Pedido separado', 'cor': const Color(0xFFAE4F48)},
    {'titulo': 'Pedido Enviado', 'cor': const Color(0xFF252623)},
    {'titulo': 'Pedido Entregue', 'cor': const Color(0xFF3C5262)},
  ];

  @override
  void initState() {
    super.initState();
    buscarProdutos();
  }

  // Interação 1: GET /produtos
  Future<void> buscarProdutos() async {
    setState(() {
      carregando = true;
      mensagemErro = null;
    });

    try {
      final resposta = await http.get(Uri.parse('$baseUrl/produtos'));
      if (resposta.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(utf8.decode(resposta.bodyBytes));
        setState(() {
          produtos = dados;
          carregando = false;
        });
      } else {
        setState(() {
          mensagemErro = 'Erro ao buscar produtos (${resposta.statusCode})';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        mensagemErro = 'Não foi possível conectar ao backend.';
        carregando = false;
      });
    }
  }

  // Interação 2: POST /produtos
  Future<void> criarProduto(String nome, double preco) async {
    try {
      final resposta = await http.post(
        Uri.parse('$baseUrl/produtos'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'nome': nome, 'preco': preco}),
      );

      if (resposta.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto cadastrado com sucesso!'),
            backgroundColor: Color(0xFF3C5262),
          ),
        );
        buscarProdutos();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao cadastrar: ${resposta.statusCode}'),
            backgroundColor: const Color(0xFFAE4F48),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão ao salvar produto.'),
          backgroundColor: Color(0xFFAE4F48),
        ),
      );
    }
  }

  void exibirDialogoNovoProduto() {
    final nomeController = TextEditingController();
    final precoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF6F0E7),
          title: const Text(
            'Novo Produto',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF252623)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Produto',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3C5262)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: precoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF3C5262)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final preco = double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0.0;

                if (nome.isNotEmpty && preco > 0) {
                  Navigator.of(ctx).pop();
                  criarProduto(nome, preco);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFAE4F48),
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Configurar Produto',
              style: TextStyle(
                color: Color(0xFFA79261),
                fontSize: 16,
              ),
            ),
          ],
        ),
       actions: [
    TextButton.icon(
      onPressed: () => _mostrarDialogo(context),
      icon: const Icon(Icons.add, color: Colors.white, size: 18),
      label: const Text('Configurar Produto', style: TextStyle(color: Colors.white)),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF2E1172),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    const SizedBox(width: 12),
    TextButton.icon(
      onPressed: () => _mostrarModalPedido(context),
      icon: const Icon(Icons.add, color: Colors.white, size: 18),
      label: const Text('Novo Pedido', style: TextStyle(color: Colors.white)),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFAE4F48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    const SizedBox(width: 40),
  ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3C5262)))
          : mensagemErro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mensagemErro!,
                        style: const TextStyle(color: Color(0xFFAE4F48), fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: buscarProdutos,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3C5262)),
                        child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 20.0, left: 16.0),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: colunas.length,
                    itemBuilder: (context, index) {
                      final coluna = colunas[index];
                      final itensDaColuna = index == 0 ? produtos : [];

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
                                color: coluna['cor'] as Color,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              ),
                              child: Text(
                                '${coluna['titulo'].toString().toUpperCase()} (${itensDaColuna.length})',
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
                              child: itensDaColuna.isEmpty
                                  ? Center(
                                      child: Text(
                                        index == 0
                                            ? 'Nenhum produto cadastrado'
                                            : 'Sem itens nesta etapa',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: itensDaColuna.length,
                                      itemBuilder: (context, i) {
                                        return CardProdutoWidget(produto: itensDaColuna[i]);
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

class CardProdutoWidget extends StatelessWidget {
  final dynamic produto;

  const CardProdutoWidget({super.key, required this.produto});
void _mostrarDialogo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configurar Produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Nome do produto')),
              TextField(decoration: InputDecoration(labelText: 'Preço (ex: 199.90)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E1172), foregroundColor: Colors.white),
              child: const Text('Adicionar')
            ),
          ],
        );
      },
    );
  }

  void _mostrarModalPedido(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Novo Pedido - Velato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('SELECIONE OS PRODUTOS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3C5262))),
              SizedBox(height: 8),
              Text('Carregando catálogo do banco...', style: TextStyle(color: Colors.grey, fontSize: 13)),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'Descrição detalhada')),
              TextField(decoration: InputDecoration(labelText: 'Responsável')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAE4F48), foregroundColor: Colors.white),
              child: const Text('Salvar')
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final double preco = (produto['preco'] is num)
        ? (produto['preco'] as num).toDouble()
        : double.tryParse(produto['preco'].toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        
        border: Border(
          left: const BorderSide(color: Color(0xFF3C5262), width: 6),
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
              Text(
                'ID: ${produto['id']}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF071227),
                ),
              ),
              const Icon(Icons.check_circle_outline, color: Color(0xFFA79261), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            produto['nome']?.toString() ?? 'Sem nome',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'R\$ ${preco.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFAE4F48),
            ),
          ),
        ],
      ),
    );
  }
}