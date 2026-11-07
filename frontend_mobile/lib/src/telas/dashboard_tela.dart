import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/kpis_model.dart';
import '../models/produto_ranking_model.dart';
import '../models/volume_diario_model.dart';
import '../widgets/grafico_produtos.dart';
import '../widgets/grafico_volume.dart';
import '../widgets/kpi_card.dart';
import '../widgets/painel.dart';
import '../widgets/paleta.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Microsserviço Dashboard (NodePort do dashboard-service)
  static const String dashboardUrl = 'http://localhost:30004';

  KpisModel? kpis;
  List<VolumeDiarioModel> volumeDiario = [];
  List<ProdutoRankingModel> produtosMaisPedidos = [];
  bool carregando = true;
  String? mensagemErro;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<dynamic> _buscar(String rota) async {
    final resposta = await http.get(Uri.parse('$dashboardUrl$rota'));
    if (resposta.statusCode != 200) {
      throw Exception('Erro ${resposta.statusCode} em $rota');
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes));
  }

  // Todas as chamadas em paralelo, como no App.jsx
  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
      mensagemErro = null;
    });

    try {
      final resultados = await Future.wait([
        _buscar('/dashboard/kpis'),
        _buscar('/dashboard/volume-diario'),
        _buscar('/dashboard/produtos-mais-pedidos'),
      ]);
      if (!mounted) return;
      setState(() {
        // cada JSON vira objeto(s) da classe modelo correspondente
        kpis = KpisModel.fromJSON(resultados[0]);
        volumeDiario = (resultados[1] as List<dynamic>)
            .map((json) => VolumeDiarioModel.fromJSON(json))
            .toList();
        produtosMaisPedidos = (resultados[2] as List<dynamic>)
            .map((json) => ProdutoRankingModel.fromJSON(json))
            .toList();
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        mensagemErro = 'Não foi possível conectar ao serviço de dashboard ($dashboardUrl).';
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        backgroundColor: Paleta.fundo,
        body: Center(
          child: Text(
            'Carregando dashboard...',
            style: TextStyle(fontSize: 18, color: Paleta.azul, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final larguraTela = MediaQuery.of(context).size.width;
    final margemTopo = larguraTela >= 900 ? 40.0 : 16.0;
    final telaEstreita = larguraTela < 500;

    return Scaffold(
      backgroundColor: Paleta.fundo,
      appBar: AppBar(
        backgroundColor: Paleta.fundo,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        titleSpacing: margemTopo,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: Paleta.azul, height: 2.0),
        ),
        title: Row(
          children: [
            // Diminui sozinho se faltar espaço (celulares pequenos)
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'VELATO',
                  style: TextStyle(
                    color: Paleta.preto,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: telaEstreita ? 22 : 28,
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: telaEstreita ? 10 : 15, right: 10),
              height: 24,
              width: 1,
              color: Paleta.azul,
            ),
            Flexible(
              child: Text(
                'Dashboard',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Paleta.dourado, fontSize: telaEstreita ? 16 : 18),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 16),
            style: OutlinedButton.styleFrom(
              foregroundColor: Paleta.azul,
              side: const BorderSide(color: Paleta.azul),
              padding: EdgeInsets.symmetric(horizontal: telaEstreita ? 12 : 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            label: const Text(
              'Ver Kanban',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          SizedBox(width: margemTopo),
        ],
      ),
      body: mensagemErro != null ? _erro() : _conteudo(),
    );
  }

  Widget _erro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensagemErro!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Paleta.vermelho, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: carregarDados,
              style: ElevatedButton.styleFrom(backgroundColor: Paleta.azul),
              child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conteudo() {
    final cards = [
      // Ícones no lugar dos emojis do React (📦 ✅ 🔴 🛍️), que nem sempre carregam no Flutter Web
      KpiCard(icone: Icons.inventory_2, corIcone: const Color(0xFFC68A4E), titulo: 'Total de Pedidos', valor: kpis?.totalPedidos ?? 0, cor: Paleta.azul),
      KpiCard(icone: Icons.check_box, corIcone: const Color(0xFF43A047), titulo: 'Entregues Hoje', valor: kpis?.entreguesHoje ?? 0, cor: Paleta.dourado),
      KpiCard(icone: Icons.circle, corIcone: const Color(0xFFE53935), titulo: 'Urgentes em Aberto', valor: kpis?.urgentesAberto ?? 0, cor: Paleta.vermelho),
      KpiCard(icone: Icons.shopping_bag, corIcone: const Color(0xFFD81B60), titulo: 'Produtos no Catálogo', valor: kpis?.totalProdutos ?? 0, cor: Paleta.roxo),
    ];

    final graficoVolume = Painel(
      icone: Icons.show_chart,
      titulo: 'Volume Diário de Pedidos',
      child: GraficoVolumeDiario(dados: volumeDiario),
    );
    final graficoProdutos = Painel(
      icone: Icons.shopping_bag,
      titulo: 'Produtos Mais Pedidos',
      child: GraficoProdutos(dados: produtosMaisPedidos),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final largo = constraints.maxWidth >= 900;
        final margem = largo ? 40.0 : 16.0;

        // Cards: lado a lado ocupando a largura toda (flex: 1 no React)
        final Widget linhaKpis = largo
            ? Row(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(child: cards[i]),
                  ],
                ],
              )
            : Wrap(
                spacing: 16,
                runSpacing: 16,
                children: cards
                    .map((c) => SizedBox(
                          width: constraints.maxWidth >= 500
                              ? (constraints.maxWidth - margem * 2 - 16) / 2
                              : constraints.maxWidth - margem * 2,
                          child: c,
                        ))
                    .toList(),
              );

        // Gráficos: 55% | 40% lado a lado, ou empilhados em tela estreita
        final Widget linhaGraficos = largo
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 55, child: graficoVolume),
                  const SizedBox(width: 16),
                  Expanded(flex: 40, child: graficoProdutos),
                ],
              )
            : Column(
                children: [graficoVolume, const SizedBox(height: 16), graficoProdutos],
              );

        return ListView(
          padding: EdgeInsets.fromLTRB(margem, 30, margem, 40),
          children: [linhaKpis, const SizedBox(height: 24), linhaGraficos],
        );
      },
    );
  }
}
