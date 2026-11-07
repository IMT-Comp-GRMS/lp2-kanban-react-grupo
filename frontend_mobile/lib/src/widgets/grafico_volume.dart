import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/volume_diario_model.dart';
import 'grafico_util.dart';
import 'paleta.dart';

// Equivalente ao GraficoVolumeDiario.jsx (gráfico de área)
class GraficoVolumeDiario extends StatelessWidget {
  final List<VolumeDiarioModel> dados;

  const GraficoVolumeDiario({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    final valores = dados.map((d) => d.pedidos).toList();
    final escala = escalaGrafico(valores);

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
          getDrawingHorizontalLine: (_) => const FlLine(color: Paleta.grade, strokeWidth: 1, dashArray: [3, 3]),
          getDrawingVerticalLine: (_) => const FlLine(color: Paleta.grade, strokeWidth: 1, dashArray: [3, 3]),
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
                child: Text(valor.toInt().toString(), style: estiloEixo),
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
                  child: Text(dados[i].data, style: estiloEixo),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Paleta.preto,
            tooltipBorderRadius: BorderRadius.circular(4),
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            getTooltipItems: (pontos) => pontos
                .map((p) => LineTooltipItem(
                      '${dados[p.x.toInt()].data}\n',
                      const TextStyle(color: Paleta.fundo, fontWeight: FontWeight.w700, fontSize: 13),
                      children: [
                        TextSpan(
                          text: pluralPedidos(p.y),
                          style: const TextStyle(color: Paleta.fundo, fontWeight: FontWeight.normal, fontSize: 13),
                        ),
                      ],
                    ))
                .toList(),
          ),
          getTouchedSpotIndicator: (barra, indices) => indices
              .map((_) => TouchedSpotIndicatorData(
                    const FlLine(color: Paleta.borda, strokeWidth: 1),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(radius: 6, color: Paleta.vermelho, strokeWidth: 0),
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
            color: Paleta.azul,
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(radius: 4, color: Paleta.azul, strokeWidth: 0),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.05, 0.95],
                colors: [Paleta.azul.withValues(alpha: 0.25), Paleta.azul.withValues(alpha: 0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
