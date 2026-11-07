import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/produto_ranking_model.dart';
import 'grafico_util.dart';
import 'paleta.dart';

// Equivalente ao GraficoProdutos.jsx (barras horizontais)
class GraficoProdutos extends StatelessWidget {
  final List<ProdutoRankingModel> dados;

  const GraficoProdutos({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    final valores = dados.map((d) => d.pedidos).toList();
    final escala = escalaGrafico(valores);

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
          getDrawingHorizontalLine: (_) => const FlLine(color: Paleta.grade, strokeWidth: 1, dashArray: [3, 3]),
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
                child: Text(valor.toInt().toString(), style: estiloEixo),
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
                      dados[i].nome,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Paleta.preto),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Paleta.preto,
            tooltipBorderRadius: BorderRadius.circular(4),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            getTooltipItem: (grupo, indiceGrupo, barra, indiceBarra) => BarTooltipItem(
              '${dados[grupo.x].nome}\n',
              const TextStyle(color: Paleta.fundo, fontWeight: FontWeight.w700, fontSize: 13),
              children: [
                TextSpan(
                  text: pluralPedidos(barra.toY),
                  style: const TextStyle(color: Paleta.fundo, fontWeight: FontWeight.normal, fontSize: 13),
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
                  color: Paleta.cores[i % Paleta.cores.length],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
