import 'dart:convert';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Paleta Velato (mesma do frontend-dashboard em React)
const Color _azul = Color(0xFF3C5262);
const Color _dourado = Color(0xFFA79261);
const Color _vermelho = Color(0xFFAE4F48);
const Color _roxo = Color(0xFF2E1172);
const Color _preto = Color(0xFF252623);
const Color _fundo = Color(0xFFF6F0E7);
const Color _cinzaTexto = Color(0xFF6B7280);
const Color _borda = Color(0xFFE5E7EB);
const Color _grade = Color(0xFFF0F0F0);
const List<Color> _coresVelato = [_azul, _dourado, _vermelho, _roxo, _preto];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Microsserviço Dashboard (kubectl port-forward svc/dashboard-service 4000:4000)
  static const String dashboardUrl = 'http://localhost:4000';

  Map<String, dynamic>? kpis;
  List<dynamic> volumeDiario = [];
  List<dynamic> produtosMaisPedidos = [];
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
        kpis = resultados[0] as Map<String, dynamic>;
        volumeDiario = resultados[1] as List<dynamic>;
        produtosMaisPedidos = resultados[2] as List<dynamic>;
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
        backgroundColor: _fundo,
        body: Center(
          child: Text(
            'Carregando dashboard...',
            style: TextStyle(fontSize: 18, color: _azul, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    final margemTopo = MediaQuery.of(context).size.width >= 900 ? 40.0 : 16.0;

    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        backgroundColor: _fundo,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        titleSpacing: margemTopo,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(color: _azul, height: 2.0),
        ),
        title: Row(
          children: [
            const Text(
              'VELATO',
              style: TextStyle(
                color: _preto,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                fontSize: 28,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 15, right: 10),
              height: 24,
              width: 1,
              color: _azul,
            ),
            const Text('Dashboard', style: TextStyle(color: _dourado, fontSize: 18)),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, size: 16),
            style: OutlinedButton.styleFrom(
              foregroundColor: _azul,
              side: const BorderSide(color: _azul),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              style: const TextStyle(color: _vermelho, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: carregarDados,
              style: ElevatedButton.styleFrom(backgroundColor: _azul),
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
      _KpiCard(icone: Icons.inventory_2, corIcone: const Color(0xFFC68A4E), titulo: 'Total de Pedidos', valor: kpis?['totalPedidos'] ?? 0, cor: _azul),
      _KpiCard(icone: Icons.check_box, corIcone: const Color(0xFF43A047), titulo: 'Entregues Hoje', valor: kpis?['entreguesHoje'] ?? 0, cor: _dourado),
      _KpiCard(icone: Icons.circle, corIcone: const Color(0xFFE53935), titulo: 'Urgentes em Aberto', valor: kpis?['urgentesAberto'] ?? 0, cor: _vermelho),
      _KpiCard(icone: Icons.shopping_bag, corIcone: const Color(0xFFD81B60), titulo: 'Produtos no Catálogo', valor: kpis?['totalProdutos'] ?? 0, cor: _roxo),
    ];

    final graficoVolume = _Painel(
      icone: Icons.show_chart,
      titulo: 'Volume Diário de Pedidos',
      child: _GraficoVolumeDiario(dados: volumeDiario),
    );
    final graficoProdutos = _Painel(
      icone: Icons.shopping_bag,
      titulo: 'Produtos Mais Pedidos',
      child: _GraficoProdutos(dados: produtosMaisPedidos),
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

// Equivalente ao KpiCard.jsx
class _KpiCard extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String titulo;
  final dynamic valor;
  final Color cor;

  const _KpiCard({
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
        border: Border.all(color: _borda),
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
                    color: _cinzaTexto,
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

// Caixa branca com título, usada pelos dois gráficos
class _Painel extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final Widget child;

  const _Painel({required this.icone, required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: _azul, size: 16),
              const SizedBox(width: 6),
              Text(
                titulo.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _azul,
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

// Eixo de valores com números inteiros (allowDecimals={false} no React)
({double maxY, double intervalo}) _escala(List<int> valores) {
  final maximo = valores.isEmpty ? 0 : valores.reduce(math.max);
  final intervalo = math.max(1, (maximo / 4).ceil()).toDouble();
  final maxY = math.max(4.0, (maximo / intervalo).ceil() * intervalo);
  return (maxY: maxY, intervalo: intervalo);
}

String _pluralPedidos(num valor) => '${valor.toInt()} pedido${valor == 1 ? '' : 's'}';

const _estiloEixo = TextStyle(fontSize: 12, color: _cinzaTexto);

// Equivalente ao GraficoVolumeDiario.jsx (gráfico de área)
class _GraficoVolumeDiario extends StatelessWidget {
  final List<dynamic> dados;

  const _GraficoVolumeDiario({required this.dados});

  @override
  Widget build(BuildContext context) {
    final valores = dados.map((d) => (d['pedidos'] as num?)?.toInt() ?? 0).toList();
    final escala = _escala(valores);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(0, dados.length - 1).toDouble(),
        minY: 0,
        maxY: escala.maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: escala.intervalo,
          verticalInterval: 1,
          getDrawingHorizontalLine: (_) => const FlLine(color: _grade, strokeWidth: 1, dashArray: [3, 3]),
          getDrawingVerticalLine: (_) => const FlLine(color: _grade, strokeWidth: 1, dashArray: [3, 3]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: escala.intervalo,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                child: Text(valor.toInt().toString(), style: _estiloEixo),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (valor, meta) {
                final i = valor.toInt();
                if (i < 0 || i >= dados.length || valor != i) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(dados[i]['data']?.toString() ?? '', style: _estiloEixo),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => _preto,
            tooltipBorderRadius: BorderRadius.circular(4),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            getTooltipItems: (pontos) => pontos
                .map((p) => LineTooltipItem(
                      '${dados[p.x.toInt()]['data']}\n',
                      const TextStyle(color: _fundo, fontWeight: FontWeight.w700, fontSize: 13),
                      children: [
                        TextSpan(
                          text: _pluralPedidos(p.y),
                          style: const TextStyle(color: _fundo, fontWeight: FontWeight.normal, fontSize: 13),
                        ),
                      ],
                    ))
                .toList(),
          ),
          getTouchedSpotIndicator: (barra, indices) => indices
              .map((_) => TouchedSpotIndicatorData(
                    const FlLine(color: _borda, strokeWidth: 1),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(radius: 6, color: _vermelho, strokeWidth: 0),
                    ),
                  ))
              .toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < valores.length; i++) FlSpot(i.toDouble(), valores[i].toDouble()),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: _azul,
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 4, color: _azul, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.05, 0.95],
                colors: [_azul.withValues(alpha: 0.25), _azul.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Equivalente ao GraficoProdutos.jsx (barras horizontais)
class _GraficoProdutos extends StatelessWidget {
  final List<dynamic> dados;

  const _GraficoProdutos({required this.dados});

  @override
  Widget build(BuildContext context) {
    final valores = dados.map((d) => (d['pedidos'] as num?)?.toInt() ?? 0).toList();
    final escala = _escala(valores);

    // O gráfico é desenhado na vertical e girado 90°: os nomes (eixo de baixo)
    // vão para a esquerda e os números (eixo da direita) vão para baixo.
    return BarChart(
      BarChartData(
        rotationQuarterTurns: 1,
        alignment: BarChartAlignment.spaceAround,
        minY: 0,
        maxY: escala.maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: escala.intervalo,
          getDrawingHorizontalLine: (_) => const FlLine(color: _grade, strokeWidth: 1, dashArray: [3, 3]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: escala.intervalo,
              getTitlesWidget: (valor, meta) => SideTitleWidget(
                meta: meta,
                child: Text(valor.toInt().toString(), style: _estiloEixo),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 150,
              getTitlesWidget: (valor, meta) {
                final i = valor.toInt();
                if (i < 0 || i >= dados.length) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: SizedBox(
                    width: 145,
                    child: Text(
                      dados[i]['nome']?.toString() ?? '',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _preto),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => _preto,
            tooltipBorderRadius: BorderRadius.circular(4),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            getTooltipItem: (grupo, indiceGrupo, barra, indiceBarra) => BarTooltipItem(
              '${dados[grupo.x]['nome']}\n',
              const TextStyle(color: _fundo, fontWeight: FontWeight.w700, fontSize: 13),
              children: [
                TextSpan(
                  text: _pluralPedidos(barra.toY),
                  style: const TextStyle(color: _fundo, fontWeight: FontWeight.normal, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < valores.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: valores[i].toDouble(),
                  width: 28,
                  color: _coresVelato[i % _coresVelato.length],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
