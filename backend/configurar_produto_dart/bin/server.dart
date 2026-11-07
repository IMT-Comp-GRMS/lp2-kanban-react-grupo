import 'dart:io';

import 'package:configurar_produto_dart/src/api.dart';
import 'package:configurar_produto_dart/src/config/app_config.dart';
import 'package:configurar_produto_dart/src/config/database.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Ponto de entrada: lê a configuração, espera o banco e sobe o servidor.
Future<void> main() async {
  final config = AppConfig.fromEnv();
  stdout.writeln('Iniciando com $config');

  final pool = criarPool(config);

  // O MySQL pode demorar dezenas de segundos na primeira subida,
  // enquanto executa os scripts de criação dos bancos.
  stdout.writeln('Aguardando o banco de dados...');
  await aguardarBanco(pool);
  stdout.writeln('Banco disponivel.');

  final servidor = await shelf_io.serve(
    construirApi(config, pool),
    InternetAddress.anyIPv4,
    config.serverPort,
  );

  stdout.writeln('✅ Configurar_Produto em Dart ouvindo na porta ${servidor.port}');

  // Desligamento gracioso: ao receber SIGTERM (enviado pelo Kubernetes antes
  // de remover um pod) ou SIGINT (Ctrl+C), o servidor para de aceitar novas
  // conexões, conclui as que estão em andamento e só então fecha o pool.
  Future<void> desligar(ProcessSignal sinal) async {
    stdout.writeln('Recebido $sinal, encerrando...');
    await servidor.close();
    await pool.close();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(desligar);
  // SIGTERM não existe no Windows; observá-lo lá lançaria exceção.
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(desligar);
  }
}
