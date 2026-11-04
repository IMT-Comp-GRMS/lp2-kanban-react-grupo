import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_screen.dart';

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
  // Serviço Criar_Pedido (pedidos do kanban)
  static const String pedidosUrl = 'http://localhost:3000';

  List<dynamic> produtos = [];
  List<dynamic> pedidos = [];
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
        });
      } else {
        setState(() {
          mensagemErro = 'Erro ao buscar produtos (${resposta.statusCode})';
          carregando = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        mensagemErro = 'Não foi possível conectar ao backend.';
        carregando = false;
      });
      return;
    }

    await buscarPedidos();
  }

  // GET /tarefas (pedidos do kanban)
  Future<void> buscarPedidos() async {
    try {
      final resposta = await http.get(Uri.parse('$pedidosUrl/tarefas'));
      if (!mounted) return;
      if (resposta.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(utf8.decode(resposta.bodyBytes));
        setState(() {
          pedidos = dados;
          carregando = false;
        });
      } else {
        setState(() {
          mensagemErro = 'Erro ao buscar pedidos (${resposta.statusCode})';
          carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        mensagemErro = 'Não foi possível conectar ao serviço de pedidos ($pedidosUrl).';
        carregando = false;
      });
    }
  }

  // PUT /tarefas/:id (mover pedido de coluna)
  Future<void> moverPedido(dynamic pedido, String novoStatus) async {
    try {
      final resposta = await http.put(
        Uri.parse('$pedidosUrl/tarefas/${pedido['id']}'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'status': novoStatus,
          'status_anterior': pedido['status'],
        }),
      );

      if (!mounted) return;
      if (resposta.statusCode == 200) {
        buscarPedidos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao mover pedido: ${resposta.statusCode}'),
            backgroundColor: const Color(0xFFAE4F48),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão ao mover pedido.'),
          backgroundColor: Color(0xFFAE4F48),
        ),
      );
    }
  }

  // POST /tarefas (novo pedido)
  Future<void> criarPedido({
    required String descricao,
    required String responsavel,
    required int prioridade,
    required List<int> produtosIds,
  }) async {
    try {
      final resposta = await http.post(
        Uri.parse('$pedidosUrl/tarefas'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'descricao': descricao,
          'responsavel': responsavel,
          'prioridade': prioridade,
          'produtosIds': produtosIds,
        }),
      );

      if (!mounted) return;
      if (resposta.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido criado com sucesso!'),
            backgroundColor: Color(0xFF3C5262),
          ),
        );
        buscarPedidos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao criar pedido: ${resposta.statusCode}'),
            backgroundColor: const Color(0xFFAE4F48),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão ao salvar pedido.'),
          backgroundColor: Color(0xFFAE4F48),
        ),
      );
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

  void _mostrarDialogo(BuildContext context) {
    final nomeController = TextEditingController();
    final precoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configurar Produto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome do produto'),
              ),
              TextField(
                controller: precoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Preço (ex: 199.90)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final nome = nomeController.text.trim();
                final preco = double.tryParse(precoController.text.replaceAll(',', '.')) ?? 0.0;
                if (nome.isEmpty || preco <= 0) return;
                Navigator.pop(context);
                criarProduto(nome, preco);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E1172), foregroundColor: Colors.white),
              child: const Text('Adicionar')
            ),
          ],
        );
      },
    );
  }

  void _mostrarModalPedido(BuildContext context) {
    final descricaoController = TextEditingController();
    final responsavelController = TextEditingController();
    final List<int> selecionados = [];
    int prioridade = 3;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Novo Pedido - Velato'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELECIONE OS PRODUTOS:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3C5262))),
                    const SizedBox(height: 8),
                    if (produtos.isEmpty)
                      const Text('Nenhum produto no catálogo.', style: TextStyle(color: Colors.grey, fontSize: 13))
                    else
                      ...produtos.map((produto) {
                        final int id = (produto['id'] as num).toInt();
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: const Color(0xFF3C5262),
                          value: selecionados.contains(id),
                          onChanged: (marcado) {
                            setStateDialog(() {
                              if (marcado == true) {
                                selecionados.add(id);
                              } else {
                                selecionados.remove(id);
                              }
                            });
                          },
                          title: Text(
                            '${produto['nome']} (R\$ ${produto['preco']})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descricaoController,
                      decoration: const InputDecoration(labelText: 'Descrição detalhada'),
                    ),
                    TextField(
                      controller: responsavelController,
                      decoration: const InputDecoration(labelText: 'Responsável'),
                    ),
                    const SizedBox(height: 16),
                    const Text('PRIORIDADE:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3C5262))),
                    DropdownButton<int>(
                      value: prioridade,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Alta (Urgente)')),
                        DropdownMenuItem(value: 2, child: Text('Média (Padrão)')),
                        DropdownMenuItem(value: 3, child: Text('Baixa (Opcional)')),
                      ],
                      onChanged: (valor) {
                        if (valor != null) setStateDialog(() => prioridade = valor);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (selecionados.isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione pelo menos um produto.'),
                          backgroundColor: Color(0xFFAE4F48),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    criarPedido(
                      descricao: descricaoController.text.trim(),
                      responsavel: responsavelController.text.trim(),
                      prioridade: prioridade,
                      produtosIds: List<int>.from(selecionados),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFAE4F48), foregroundColor: Colors.white),
                  child: const Text('Salvar')
                ),
              ],
            );
          },
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
    OutlinedButton.icon(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      ),
      icon: const Icon(Icons.bar_chart, color: Color(0xFF3C5262), size: 18),
      label: const Text('Dashboard', style: TextStyle(color: Color(0xFF3C5262))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF3C5262), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    const SizedBox(width: 12),
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
                      final itensDaColuna = pedidos
                          .where((p) => p['status'] == coluna['titulo'])
                          .toList()
                        ..sort((a, b) => ((a['prioridade'] ?? 3) as num)
                            .compareTo((b['prioridade'] ?? 3) as num));

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
                                            ? 'Nenhum pedido cadastrado'
                                            : 'Sem itens nesta etapa',
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(12),
                                      itemCount: itensDaColuna.length,
                                      itemBuilder: (context, i) {
                                        final pedido = itensDaColuna[i];
                                        return CardPedidoWidget(
                                          key: ValueKey(pedido['id']),
                                          pedido: pedido,
                                          onVoltar: index > 0
                                              ? () => moverPedido(pedido, colunas[index - 1]['titulo'])
                                              : null,
                                          onAvancar: index < colunas.length - 1
                                              ? () => moverPedido(pedido, colunas[index + 1]['titulo'])
                                              : null,
                                        );
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

class CardPedidoWidget extends StatefulWidget {
  final dynamic pedido;
  // null quando o pedido já está na primeira/última coluna
  final VoidCallback? onVoltar;
  final VoidCallback? onAvancar;

  const CardPedidoWidget({
    super.key,
    required this.pedido,
    this.onVoltar,
    this.onAvancar,
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
  // Microsserviço Histórico (kubectl port-forward svc/historico-service 5001:5001)
  static const String historicoUrl = 'http://localhost:5001';

  List<dynamic> historico = [];
  bool mostrarHistorico = false;
  bool carregandoHistorico = false;

  // GET /historico/:pedido_id (igual ao handleVerHistorico do CardPedido.jsx)
  Future<void> alternarHistorico() async {
    if (mostrarHistorico) {
      setState(() => mostrarHistorico = false);
      return;
    }

    setState(() => carregandoHistorico = true);
    List<dynamic> dados = [];
    try {
      final resposta = await http.get(
        Uri.parse('$historicoUrl/historico/${widget.pedido['id']}'),
      );
      // O serviço responde 404 quando o pedido ainda não tem movimentações
      if (resposta.statusCode == 200) {
        dados = jsonDecode(utf8.decode(resposta.bodyBytes));
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
    final int prioridade = (pedido['prioridade'] as num?)?.toInt() ?? 3;
    final Color corBorda = CardPedidoWidget.coresPrioridade[prioridade] ?? const Color(0xFF3C5262);
    final String descricao = pedido['descricao']?.toString() ?? '';

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
          Text(
            'ID: ${pedido['id']}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF071227),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pedido['titulo']?.toString() ?? 'Pedido',
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
            'Responsável: ${pedido['responsavel'] ?? ''}',
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
                          linha['status_anterior']?.toString() ?? '—',
                          cor: const Color(0xFFAE4F48),
                        ),
                        _CelulaHistorico(
                          linha['status_novo']?.toString() ?? '',
                          cor: const Color(0xFF3C5262),
                        ),
                        _CelulaHistorico(
                          linha['data_hora']?.toString() ?? '',
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
