// Testes do PedidosBloc (lista do Kanban). Usam um servidor falso (MockClient
// do pacote http), então não precisam do Criar_Pedido no ar.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend_mobile/src/blocs/pedidos_bloc.dart';
import 'package:frontend_mobile/src/models/pedido_model.dart';

// Simula o Criar_Pedido guardando os pedidos em memória.
MockClient servidorFalso(List<Map<String, dynamic>> banco, {List<String>? log}) {
  return MockClient((req) async {
    log?.add('${req.method} ${req.url.path}');
    final json = {'content-type': 'application/json; charset=utf-8'};
    if (req.method == 'GET' && req.url.path == '/tarefas') {
      return http.Response.bytes(utf8.encode(jsonEncode(banco)), 200, headers: json);
    }
    if (req.method == 'POST' && req.url.path == '/tarefas') {
      final corpo = jsonDecode(req.body) as Map<String, dynamic>;
      banco.add({'id': banco.length + 1, 'titulo': 'Novo', 'status': 'Pedidos', ...corpo});
      return http.Response('{}', 201);
    }
    final id = int.tryParse(req.url.pathSegments.last);
    final pedido = banco.where((p) => p['id'] == id).firstOrNull;
    if (pedido == null) return http.Response('{}', 404);
    if (req.method == 'PUT') {
      pedido['status'] = (jsonDecode(req.body) as Map<String, dynamic>)['status'];
      return http.Response('{}', 200);
    }
    if (req.method == 'DELETE') {
      banco.remove(pedido);
      return http.Response('{}', 200);
    }
    return http.Response('{}', 405);
  });
}

void main() {
  late List<Map<String, dynamic>> banco;

  setUp(() {
    banco = [
      {'id': 1, 'titulo': 'Calça Cargo', 'responsavel': 'Ana', 'status': 'Pedidos', 'prioridade': 1},
    ];
  });

  test('carregar emite a lista de pedidos', () async {
    final bloc = PedidosBloc(cliente: servidorFalso(banco));
    await bloc.carregar();
    final lista = await bloc.pedidos.first;
    expect(lista.single.titulo, 'Calça Cargo');
    bloc.dispose();
  });

  test('mover faz o PUT e recarrega a lista com o status novo', () async {
    final log = <String>[];
    final bloc = PedidosBloc(cliente: servidorFalso(banco, log: log));
    await bloc.carregar();
    final pedido = (await bloc.pedidos.first).single;

    final erro = await bloc.mover(pedido, 'Pagamento Confirmado');

    expect(erro, isNull);
    expect(log, ['GET /tarefas', 'PUT /tarefas/1', 'GET /tarefas']);
    expect((await bloc.pedidos.first).single.status, 'Pagamento Confirmado');
    bloc.dispose();
  });

  test('criar e excluir atualizam a lista', () async {
    final bloc = PedidosBloc(cliente: servidorFalso(banco));
    await bloc.criar(descricao: '', responsavel: 'Rafa', prioridade: 2, produtosIds: [1]);
    expect(await bloc.pedidos.first, hasLength(2));

    final erro = await bloc.excluir((await bloc.pedidos.first).first);
    expect(erro, isNull);
    expect((await bloc.pedidos.first).single.responsavel, 'Rafa');
    bloc.dispose();
  });

  test('status inesperado devolve a mensagem e não recarrega', () async {
    final log = <String>[];
    final bloc = PedidosBloc(cliente: servidorFalso(banco, log: log));
    final erro = await bloc.mover(PedidoModel(99, 'x', '', '', 'Pedidos', 3), 'Pedido Enviado');
    expect(erro, 'Falha ao mover pedido: 404');
    expect(log, ['PUT /tarefas/99']);
    bloc.dispose();
  });

  test('sem conexão: carregar emite erro no stream', () async {
    final bloc = PedidosBloc(
      cliente: MockClient((_) => throw http.ClientException('sem rede')),
    );
    final erro = expectLater(bloc.pedidos, emitsError(contains('Não foi possível conectar')));
    await bloc.carregar();
    await erro;
    bloc.dispose();
  });
}
