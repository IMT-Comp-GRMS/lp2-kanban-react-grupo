import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pedido_model.dart';
import '../models/produto_model.dart';
import '../widgets/coluna_kanban.dart';
import '../widgets/dialogo_pedido.dart';
import '../widgets/dialogo_produto.dart';
import 'dashboard_tela.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  static const String baseUrl = 'http://localhost:30001'; // NodePort do configurar-produto-service
  // Serviço Criar_Pedido (pedidos do kanban)
  static const String pedidosUrl = 'http://localhost:30000'; // NodePort do criar-pedido-service

  List<ProdutoModel> produtos = [];
  List<PedidoModel> pedidos = [];
  bool carregando = true;
  String? mensagemErro;

  // Filtros (iguais ao Kanban web): busca por produto/responsável e prioridade
  final TextEditingController buscaController = TextEditingController();
  String termoBusca = '';
  int? filtroPrioridade; // null = todas as prioridades

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

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  bool get filtrosAtivos => termoBusca.isNotEmpty || filtroPrioridade != null;

  void limparFiltros() {
    buscaController.clear();
    setState(() {
      termoBusca = '';
      filtroPrioridade = null;
    });
  }

  // Mesmo critério do App.jsx: o termo aparece no título (produtos) ou no responsável
  bool passaNosFiltros(PedidoModel pedido) {
    if (termoBusca.isNotEmpty) {
      final termo = termoBusca.toLowerCase();
      if (!pedido.titulo.toLowerCase().contains(termo) &&
          !pedido.responsavel.toLowerCase().contains(termo)) {
        return false;
      }
    }
    if (filtroPrioridade != null && pedido.prioridade != filtroPrioridade) return false;
    return true;
  }

  Widget _barraDeFiltros() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Filtrar Pedidos:',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3C5262), fontSize: 14),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: buscaController,
              onChanged: (texto) => setState(() => termoBusca = texto.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar por produto ou responsável...',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade500),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: filtroPrioridade,
                style: const TextStyle(fontSize: 14, color: Color(0xFF252623)),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todas as Prioridades')),
                  DropdownMenuItem(value: 1, child: Text('Alta (Urgente)')),
                  DropdownMenuItem(value: 2, child: Text('Média (Padrão)')),
                  DropdownMenuItem(value: 3, child: Text('Baixa')),
                ],
                onChanged: (valor) => setState(() => filtroPrioridade = valor),
              ),
            ),
          ),
          if (filtrosAtivos)
            TextButton(
              onPressed: limparFiltros,
              child: const Text(
                'Limpar Filtros',
                style: TextStyle(
                  color: Color(0xFFAE4F48),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFAE4F48),
                ),
              ),
            ),
        ],
      ),
    );
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
          // cada item do JSON vira um objeto da classe modelo
          produtos = dados.map((json) => ProdutoModel.fromJSON(json)).toList();
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
          // cada item do JSON vira um objeto da classe modelo
          pedidos = dados.map((json) => PedidoModel.fromJSON(json)).toList();
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

  // DELETE /tarefas/:id (excluir pedido, com confirmação igual ao window.confirm do React)
  Future<void> excluirPedido(PedidoModel pedido) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF6F0E7),
        title: const Text(
          'Excluir pedido',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF252623)),
        ),
        content: Text('Tem certeza que deseja excluir o pedido "${pedido.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFAE4F48),
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      final resposta = await http.delete(Uri.parse('$pedidosUrl/tarefas/${pedido.id}'));

      if (!mounted) return;
      if (resposta.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido excluído com sucesso!'),
            backgroundColor: Color(0xFF3C5262),
          ),
        );
        buscarPedidos();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao excluir pedido: ${resposta.statusCode}'),
            backgroundColor: const Color(0xFFAE4F48),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão ao excluir pedido.'),
          backgroundColor: Color(0xFFAE4F48),
        ),
      );
    }
  }

  // PUT /tarefas/:id (mover pedido de coluna)
  Future<void> moverPedido(PedidoModel pedido, String novoStatus) async {
    try {
      final resposta = await http.put(
        Uri.parse('$pedidosUrl/tarefas/${pedido.id}'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'status': novoStatus,
          'status_anterior': pedido.status,
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

  // Diálogo "Configurar Produto": o formulário usa o padrão Bloc
  // (lib/src/blocs e lib/src/widgets/dialogo_produto.dart).
  void _mostrarDialogo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => DialogoProduto(onSalvar: criarProduto),
    );
  }

  // Diálogo "Novo Pedido": o formulário usa o padrão Bloc
  // (lib/src/blocs/pedido_form_bloc.dart e lib/src/widgets/dialogo_pedido.dart).
  void _mostrarModalPedido(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => DialogoPedido(produtos: produtos, onSalvar: criarPedido),
    );
  }

  // Celular: os 3 botões do topo ficam só com ícone (o nome aparece ao segurar)
  List<Widget> _botoesCompactos(BuildContext context) {
    Widget botao({
      required String dica,
      required IconData icone,
      required VoidCallback onPressed,
      Color? fundo,
      Color corIcone = Colors.white,
      BorderSide? borda,
    }) {
      return Tooltip(
        message: dica,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: fundo,
            side: borda,
            minimumSize: const Size(40, 40),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: Icon(icone, color: corIcone, size: 20),
        ),
      );
    }

    return [
      botao(
        dica: 'Dashboard',
        icone: Icons.bar_chart,
        corIcone: const Color(0xFF3C5262),
        borda: const BorderSide(color: Color(0xFF3C5262), width: 2),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        ),
      ),
      const SizedBox(width: 8),
      botao(
        dica: 'Configurar Produto',
        icone: Icons.inventory_2_outlined,
        fundo: const Color(0xFF2E1172),
        onPressed: () => _mostrarDialogo(context),
      ),
      const SizedBox(width: 8),
      botao(
        dica: 'Novo Pedido',
        icone: Icons.add,
        fundo: const Color(0xFFAE4F48),
        onPressed: () => _mostrarModalPedido(context),
      ),
      const SizedBox(width: 12),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.of(context).size.width;
    final telaEstreita = larguraTela < 800;

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
            // Diminui sozinho se faltar espaço (celulares pequenos)
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'VELATO',
                  style: TextStyle(
                    color: Color(0xFF252623),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            if (larguraTela >= 500) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 20,
                width: 1,
                color: const Color(0xFF3C5262),
              ),
              const Flexible(
                child: Text(
                  'Orders',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFA79261),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
       actions: telaEstreita ? _botoesCompactos(context) : [
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _barraDeFiltros(),
                  Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: colunas.length,
                    itemBuilder: (context, index) {
                      final coluna = colunas[index];
                      final itensDaColuna = pedidos
                          .where((p) => p.status == coluna['titulo'])
                          .where(passaNosFiltros)
                          .toList()
                        ..sort((a, b) => a.prioridade.compareTo(b.prioridade));

                      return ColunaKanban(
                        titulo: coluna['titulo'].toString(),
                        cor: coluna['cor'] as Color,
                        pedidos: itensDaColuna,
                        mensagemVazia: filtrosAtivos
                            ? 'Nenhum pedido encontrado'
                            : index == 0
                                ? 'Nenhum pedido cadastrado'
                                : 'Sem itens nesta etapa',
                        onExcluir: excluirPedido,
                        onVoltar: index > 0
                            ? (pedido) => moverPedido(pedido, colunas[index - 1]['titulo'])
                            : null,
                        onAvancar: index < colunas.length - 1
                            ? (pedido) => moverPedido(pedido, colunas[index + 1]['titulo'])
                            : null,
                      );
                    },
                  ),
                  ),
                    ],
                  ),
                ),
    );
  }
}
