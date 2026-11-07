import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

import '../models/pedido_model.dart';

// Bloc da lista de pedidos do Kanban (vai além do exemplo da apostila Flutter
// Gerenciamento de Estado, que aplica o padrão só em formulários).
//
// A tela não guarda mais a lista com setState: ela lê o stream `pedidos` com um
// StreamBuilder. Cada ação (criar, mover, excluir) faz a requisição ao
// Criar_Pedido e depois recarrega a lista, que é emitida de novo no stream.
class PedidosBloc {
  // NodePort do criar-pedido-service
  static const String urlPadrao = 'http://localhost:30000';

  final String baseUrl;
  // Cliente HTTP recebido de fora para que os testes possam usar um falso.
  final http.Client _cliente;

  PedidosBloc({this.baseUrl = urlPadrao, http.Client? cliente})
      : _cliente = cliente ?? http.Client();

  final _pedidos = BehaviorSubject<List<PedidoModel>>();

  // O próprio BehaviorSubject é o stream: é sempre a mesma instância, então o
  // StreamBuilder não se reinscreve a cada rebuild da tela.
  Stream<List<PedidoModel>> get pedidos => _pedidos;

  // GET /tarefas. Em caso de falha, o erro vai para o stream e a tela mostra a
  // mensagem com o botão "Tentar novamente".
  Future<void> carregar() async {
    try {
      final resposta = await _cliente.get(Uri.parse('$baseUrl/tarefas'));
      if (resposta.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(utf8.decode(resposta.bodyBytes));
        _pedidos.sink.add(dados.map((json) => PedidoModel.fromJSON(json)).toList());
      } else {
        _pedidos.sink.addError('Erro ao buscar pedidos (${resposta.statusCode})');
      }
    } catch (e) {
      _pedidos.sink.addError('Não foi possível conectar ao serviço de pedidos ($baseUrl).');
    }
  }

  // As ações abaixo devolvem null quando dão certo, ou a mensagem de erro para
  // a tela mostrar num SnackBar.

  // POST /tarefas
  Future<String?> criar({
    required String descricao,
    required String responsavel,
    required int prioridade,
    required List<int> produtosIds,
  }) {
    return _executar(
      () => _cliente.post(
        Uri.parse('$baseUrl/tarefas'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'descricao': descricao,
          'responsavel': responsavel,
          'prioridade': prioridade,
          'produtosIds': produtosIds,
        }),
      ),
      sucesso: 201,
      falha: 'Falha ao criar pedido',
      semConexao: 'Erro de conexão ao salvar pedido.',
    );
  }

  // PUT /tarefas/:id (mover de coluna)
  Future<String?> mover(PedidoModel pedido, String novoStatus) {
    return _executar(
      () => _cliente.put(
        Uri.parse('$baseUrl/tarefas/${pedido.id}'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'status': novoStatus, 'status_anterior': pedido.status}),
      ),
      sucesso: 200,
      falha: 'Falha ao mover pedido',
      semConexao: 'Erro de conexão ao mover pedido.',
    );
  }

  // DELETE /tarefas/:id
  Future<String?> excluir(PedidoModel pedido) {
    return _executar(
      () => _cliente.delete(Uri.parse('$baseUrl/tarefas/${pedido.id}')),
      sucesso: 200,
      falha: 'Falha ao excluir pedido',
      semConexao: 'Erro de conexão ao excluir pedido.',
    );
  }

  // Faz a requisição, confere o status e, se deu certo, recarrega a lista.
  Future<String?> _executar(
    Future<http.Response> Function() requisicao, {
    required int sucesso,
    required String falha,
    required String semConexao,
  }) async {
    try {
      final resposta = await requisicao();
      if (resposta.statusCode != sucesso) return '$falha: ${resposta.statusCode}';
    } catch (e) {
      return semConexao;
    }
    await carregar();
    return null;
  }

  void dispose() {
    _pedidos.close();
    _cliente.close();
  }
}
