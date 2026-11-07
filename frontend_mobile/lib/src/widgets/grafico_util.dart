import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'paleta.dart';

// Funções e estilo usados pelos dois gráficos do Dashboard.

// Eixo de valores com números inteiros (allowDecimals={false} no React)
({double maxY, double intervalo}) escalaGrafico(List<int> valores) {
  final maximo = valores.isEmpty ? 0 : valores.reduce(math.max);
  final intervalo = math.max(1, (maximo / 4).ceil()).toDouble();
  final maxY = math.max(4.0, (maximo / intervalo).ceil() * intervalo);
  return (maxY: maxY, intervalo: intervalo);
}

String pluralPedidos(num valor) => '${valor.toInt()} pedido${valor == 1 ? '' : 's'}';

const estiloEixo = TextStyle(fontSize: 12, color: Paleta.cinzaTexto);
