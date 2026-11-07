import 'package:mysql_dart/mysql_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config/app_config.dart';
import 'controllers/health_controller.dart';
import 'controllers/produto_controller.dart';
import 'repositories/mysql_produto_repository.dart';
import 'services/produto_service.dart';
import 'services/publicador_eventos.dart';
import 'web/middlewares.dart';
import 'web/problem.dart';

/// Constrói o handler completo da aplicação: rotas + pilha de middlewares.
///
/// Este é o ponto de montagem (composition root): as dependências são
/// criadas de fora para dentro e injetadas por construtor, à mão.
Handler construirApi(AppConfig config, MySQLConnectionPool pool) {
  final repository = MySqlProdutoRepository(pool);
  final eventos = BarramentoHttp(config.barramentoUrl);
  final service = ProdutoService(repository, eventos);
  final produtos = ProdutoController(service);
  final health = HealthController(pool);

  final raiz = Router();

  // Mesmo endereço de sempre, para não quebrar as telas: /produtos
  raiz.mount('/produtos', produtos.router.call);
  raiz.mount('/health', health.router.call);

  // Rota curinga: qualquer outro caminho, com qualquer verbo, vira 404.
  raiz.all('/<ignorado|.*>', (Request requisicao) {
    return problema(
      status: 404,
      tipo: 'rota-inexistente',
      titulo: 'Rota nao encontrada',
      detalhe: 'Nao existe ${requisicao.method} /${requisicao.url.path}.',
    );
  });

  // A ordem importa: o log é o mais externo para medir o tempo total,
  // e o tratamento de erros precisa envolver o roteador.
  return const Pipeline()
      .addMiddleware(registrarAcessos())
      .addMiddleware(liberarCors())
      .addMiddleware(tratarErros(detalharFalhas: !config.producao))
      .addHandler(raiz.call);
}
