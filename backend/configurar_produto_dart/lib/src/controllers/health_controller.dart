import 'dart:convert';

import 'package:mysql_dart/mysql_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Verificação de saúde, usada para saber se o serviço está vivo e pronto.
class HealthController {
  HealthController(this._pool);

  final MySQLConnectionPool _pool;

  Router get router {
    final router = Router();

    // Liveness: o processo está de pé? Não toca no banco de propósito.
    router.get('/live', (Request _) => _json(200, {'status': 'ok'}));

    // Readiness: o serviço consegue atender? Aqui sim o banco é consultado.
    router.get('/ready', (Request _) async {
      try {
        await _pool.execute('SELECT 1');
        return _json(200, {'status': 'ok', 'banco': 'ok'});
      } catch (_) {
        return _json(503, {'status': 'degradado', 'banco': 'indisponivel'});
      }
    });

    return router;
  }

  Response _json(int status, Map<String, dynamic> corpo) => Response(
        status,
        body: jsonEncode(corpo),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
}
