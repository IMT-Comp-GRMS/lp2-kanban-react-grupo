import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../core/erros.dart';
import '../models/produto.dart';
import '../services/produto_service.dart';

/// Tradução HTTP <-> domínio para os produtos.
///
/// O controlador é fino de propósito: extrai dados da requisição, chama o
/// serviço e escolhe o código de status. Nenhuma regra de negócio mora aqui.
class ProdutoController {
  ProdutoController(this._service);

  final ProdutoService _service;

  Router get router {
    final router = Router();

    // GET /produtos -> 200 com a lista do catálogo
    router.get('/', (Request _) async {
      final produtos = await _service.listar();
      return _json(200, produtos.map((p) => p.toJson()).toList());
    });

    // GET /produtos/<id> -> 200 com o produto, 404 se não existir.
    // É o recurso para onde aponta o cabeçalho Location do POST.
    router.get('/<id>', (Request _, String id) async {
      final numero = int.tryParse(id);
      if (numero == null) {
        throw RequisicaoInvalida('O id do produto deve ser um numero inteiro.');
      }
      final produto = await _service.buscarPorId(numero);
      return _json(200, produto.toJson());
    });

    // POST /produtos -> 201 com o produto criado e o cabeçalho Location
    // apontando para ele, como no _criar da seção 11.5 da apostila Back End
    // com Dart (nível 2 do modelo de maturidade de Richardson).
    router.post('/', (Request requisicao) async {
      final corpo = await _lerJson(requisicao);
      final criado = await _service.criar(_montarProduto(corpo));
      return _json(201, criado.toJson(), headers: {'location': '/produtos/${criado.id}'});
    });

    return router;
  }

  /// Serializa o corpo como JSON com o cabeçalho correto.
  Response _json(int status, Object corpo, {Map<String, String> headers = const {}}) {
    return Response(
      status,
      body: jsonEncode(corpo),
      headers: {'content-type': 'application/json; charset=utf-8', ...headers},
    );
  }

  /// Lê e decodifica o corpo, recusando cedo o que não tem chance de dar certo.
  Future<Map<String, dynamic>> _lerJson(Request requisicao) async {
    final tipo = requisicao.headers['content-type'] ?? '';
    if (!tipo.contains('application/json')) {
      throw RequisicaoInvalida('Envie o corpo com Content-Type application/json.');
    }

    final String texto;
    try {
      texto = await requisicao.readAsString();
    } on FormatException {
      throw RequisicaoInvalida('O corpo da requisicao nao esta em UTF-8.');
    }
    if (texto.trim().isEmpty) {
      throw RequisicaoInvalida('O corpo da requisicao esta vazio.');
    }

    try {
      final decodificado = jsonDecode(texto);
      if (decodificado is! Map<String, dynamic>) {
        throw RequisicaoInvalida('O corpo deve ser um objeto JSON.');
      }
      return decodificado;
    } on FormatException {
      throw RequisicaoInvalida('O corpo nao e um JSON valido.');
    }
  }

  /// Converte o mapa recebido em um Produto, acumulando problemas de tipo e
  /// de campos ausentes. As regras de valor (preço > 0 etc.) ficam no serviço.
  Produto _montarProduto(Map<String, dynamic> corpo) {
    final erros = <String, String>{};

    final nome = corpo['nome'];
    if (nome is! String) erros['nome'] = 'Campo obrigatorio do tipo texto.';

    final preco = corpo['preco'];
    if (preco is! num) erros['preco'] = 'Campo obrigatorio do tipo numero.';

    if (erros.isNotEmpty) {
      throw ErroValidacao('Os dados enviados sao invalidos.', erros);
    }
    return Produto(nome: nome as String, preco: (preco as num).toDouble());
  }
}
