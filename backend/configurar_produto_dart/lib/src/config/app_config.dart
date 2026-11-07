import 'env.dart';

/// Configuração da aplicação, resolvida e validada uma única vez no boot.
class AppConfig {
  const AppConfig({
    required this.appEnv,
    required this.serverPort,
    required this.dbHost,
    required this.dbPort,
    required this.dbName,
    required this.dbUser,
    required this.dbPassword,
    required this.dbPoolSize,
    required this.barramentoUrl,
  });

  final String appEnv;
  final int serverPort;

  final String dbHost;
  final int dbPort;
  final String dbName;
  final String dbUser;
  final String dbPassword;
  final int dbPoolSize;

  /// Endereço do barramento de eventos (Service do Kubernetes).
  final String barramentoUrl;

  /// Em produção, as mensagens de erro 500 não revelam detalhes internos.
  bool get producao => appEnv == 'production';

  /// Constrói a configuração a partir do ambiente e valida os limites.
  ///
  /// `factory` permite executar código (e lançar exceção) antes de devolver
  /// o objeto, o que um construtor comum não permite.
  factory AppConfig.fromEnv() {
    final config = AppConfig(
      appEnv: Env.opcional('APP_ENV', 'development'),
      serverPort: Env.inteiro('SERVER_PORT', 3001),
      dbHost: Env.obrigatoria('DB_HOST'),
      dbPort: Env.inteiro('DB_PORT', 3306),
      dbName: Env.obrigatoria('DB_NAME'),
      dbUser: Env.obrigatoria('DB_USER'),
      dbPassword: Env.obrigatoria('DB_PASSWORD'),
      dbPoolSize: Env.inteiro('DB_POOL_SIZE', 10),
      barramentoUrl: Env.opcional(
        'BARRAMENTO_URL',
        'http://barramento-service:10000/eventos',
      ),
    );

    if (config.serverPort < 1 || config.serverPort > 65535) {
      throw StateError('SERVER_PORT fora da faixa válida: ${config.serverPort}');
    }
    if (config.dbPoolSize < 1) {
      throw StateError('DB_POOL_SIZE deve ser pelo menos 1.');
    }
    return config;
  }

  /// Representação segura para log: a senha nunca é impressa.
  @override
  String toString() =>
      'AppConfig(appEnv: $appEnv, serverPort: $serverPort, '
      'db: $dbUser@$dbHost:$dbPort/$dbName, pool: $dbPoolSize, '
      'barramento: $barramentoUrl)';
}
