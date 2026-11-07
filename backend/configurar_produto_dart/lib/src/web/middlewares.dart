import 'dart:io';

import 'package:shelf/shelf.dart';

import '../core/erros.dart';
import 'problem.dart';

/// Registra método, caminho, status e duração de cada requisição.
Middleware registrarAcessos() {
  return (Handler proximo) {
    return (Request requisicao) async {
      final inicio = DateTime.now();
      final resposta = await proximo(requisicao);
      final duracao = DateTime.now().difference(inicio).inMilliseconds;

      stdout.writeln(
        '${requisicao.method} /${requisicao.url.path} '
        '-> ${resposta.statusCode} (${duracao}ms)',
      );
      return resposta;
    };
  };
}

/// Libera o consumo da API por páginas em outra origem (Flutter Web e React).
Middleware liberarCors({String origem = '*'}) {
  final cabecalhos = {
    'access-control-allow-origin': origem,
    'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'access-control-allow-headers': 'Content-Type, Authorization',
    'access-control-max-age': '86400',
  };

  return (Handler proximo) {
    return (Request requisicao) async {
      // A requisição de sondagem (preflight) que o navegador envia antes de
      // um POST com JSON é respondida sem chegar ao roteador.
      if (requisicao.method == 'OPTIONS') {
        return Response(204, headers: cabecalhos);
      }
      final resposta = await proximo(requisicao);
      return resposta.change(headers: cabecalhos);
    };
  };
}

/// Converte exceções em respostas HTTP. É a única fronteira entre as
/// exceções do domínio e o mundo HTTP.
///
/// [detalharFalhas] deve ser falso em produção: mensagens internas podem
/// revelar nomes de tabelas, caminhos e versões de bibliotecas.
Middleware tratarErros({required bool detalharFalhas}) {
  return (Handler proximo) {
    return (Request requisicao) async {
      try {
        return await proximo(requisicao);
      } on ErroApp catch (erro) {
        return _traduzir(erro);
      } catch (erro, pilha) {
        // Falha não prevista: registra tudo internamente e devolve pouco.
        stderr.writeln('Erro nao tratado: $erro\n$pilha');
        return problema(
          status: 500,
          tipo: 'falha-interna',
          titulo: 'Erro interno',
          detalhe: detalharFalhas
              ? erro.toString()
              : 'Ocorreu uma falha inesperada. Tente novamente mais tarde.',
        );
      }
    };
  };
}

/// O switch é exaustivo: criar um novo tipo de ErroApp sem tratá-lo aqui
/// provoca erro de compilação.
Response _traduzir(ErroApp erro) {
  return switch (erro) {
    ErroValidacao() => problema(
        status: 422,
        tipo: 'validacao',
        titulo: 'Dados invalidos',
        detalhe: erro.mensagem,
        extras: {'errors': erro.campos},
      ),
    RequisicaoInvalida() => problema(
        status: 400,
        tipo: 'requisicao-invalida',
        titulo: 'Requisicao malformada',
        detalhe: erro.mensagem,
      ),
  };
}
