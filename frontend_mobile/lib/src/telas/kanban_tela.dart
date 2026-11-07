import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_tela.dart';
import '../models/historico_model.dart';
import '../models/pedido_model.dart';
import '../models/produto_model.dart';

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
                        final int id = produto.id;
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
                            '${produto.nome} (R\$ ${produto.preco.toStringAsFixed(2)})',
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
                                        filtrosAtivos
                                            ? 'Nenhum pedido encontrado'
                                            : index == 0
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
                                          key: ValueKey(pedido.id),
                                          pedido: pedido,
                                          onExcluir: () => excluirPedido(pedido),
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
                    ],
                  ),
                ),
    );
  }
}

class CardProdutoWidget extends StatelessWidget {
  final ProdutoModel produto;

  const CardProdutoWidget({super.key, required this.produto});
  @override
  Widget build(BuildContext context) {
    final double preco = produto.preco;

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
                'ID: ${produto.id}',
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
            produto.nome,
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
