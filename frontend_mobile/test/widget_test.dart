// Teste de widget do app Velato.
//
// O KanbanScreen faz requisições HTTP no initState e, no ambiente de teste,
// não há servidor. Por isso o teste verifica só o primeiro frame (antes de
// qualquer resposta chegar), sem depender do back-end.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_mobile/main.dart';

void main() {
  testWidgets('VelatoApp monta e mostra o carregamento inicial',
      (WidgetTester tester) async {
    // Monta o app e desenha o primeiro frame.
    await tester.pumpWidget(const VelatoApp());

    // O app usa um MaterialApp na raiz.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Enquanto os pedidos carregam, o Kanban mostra o indicador de progresso.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
