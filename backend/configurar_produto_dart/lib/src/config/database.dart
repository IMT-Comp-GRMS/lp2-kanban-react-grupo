import 'package:mysql_dart/mysql_dart.dart';

import 'app_config.dart';

/// Cria o pool de conexões a partir da configuração da aplicação.
///
/// O pool é criado uma única vez, no boot, e compartilhado por todas as
/// requisições. Cada conexão nasce na primeira vez que é necessária e depois
/// é reaproveitada.
MySQLConnectionPool criarPool(AppConfig config) {
  return MySQLConnectionPool(
    host: config.dbHost,
    port: config.dbPort,
    userName: config.dbUser,
    password: config.dbPassword,
    databaseName: config.dbName,
    maxConnections: config.dbPoolSize,
    // O tráfego fica dentro do cluster, então TLS é dispensável aqui.
    secure: false,
    // Necessário porque o MySQL 8 autentica com caching_sha2_password e,
    // sem TLS, o cliente precisa buscar a chave pública do servidor.
    allowPublicKeyRetrieval: true,
  );
}

/// Aguarda o banco ficar disponível.
///
/// O contêiner do serviço pode iniciar antes de o MySQL terminar de subir
/// (na primeira vez ele ainda executa os scripts de criação). Em vez de
/// falhar, a aplicação tenta se conectar algumas vezes, com intervalo.
Future<void> aguardarBanco(
  MySQLConnectionPool pool, {
  int tentativas = 30,
  Duration intervalo = const Duration(seconds: 2),
}) async {
  for (var tentativa = 1; tentativa <= tentativas; tentativa++) {
    try {
      await pool.execute('SELECT 1');
      return;
    } catch (_) {
      if (tentativa == tentativas) rethrow;
      await Future<void>.delayed(intervalo);
    }
  }
}
