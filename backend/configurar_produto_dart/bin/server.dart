import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:mysql_dart/mysql_dart.dart';
import 'package:http/http.dart' as http;

// CONEXÃO COM O BANCO DE DADOS usando mysql_dart
MySQLConnectionPool conectar() {
  return MySQLConnectionPool(
    host: Platform.environment['HOST'] ?? '127.0.0.1',
    port: int.tryParse(Platform.environment['PORT'] ?? '3306') ?? 3306,
    userName: Platform.environment['USERBD'] ?? 'root',
    password: Platform.environment['PASSWORD'] ?? '',
    databaseName: Platform.environment['DATABASE'] ?? 'BD_Produtos',
    maxConnections: 10,
    secure: false, // Fundamental para MySQL 8
    allowPublicKeyRetrieval: true, // Fundamental para MySQL 8
  );
}

void main() async {
  final pool = conectar();
  final router = Router();

  // GET /produtos
  router.get('/produtos', (Request req) async {
    try {
      final resultados = await pool.execute('SELECT * FROM produtos');
      
      final produtos = resultados.rows.map((row) {
        final dados = row.assoc().cast<String, String?>();
        return {
          'id': int.tryParse(dados['id']!) ?? 0,
          'nome': dados['nome'],
          'preco': double.tryParse(dados['preco']!) ?? 0.0,
        };
      }).toList();
      
      return Response.ok(
        jsonEncode(produtos), 
        headers: {'content-type': 'application/json; charset=utf-8'}
      );
    } catch (erro) {
      print('Erro ao buscar produtos: $erro');
      return Response.internalServerError(body: jsonEncode({'mensagem': 'Erro interno.'}));
    }
  });

  // POST /produtos
  router.post('/produtos', (Request req) async {
    final payload = await req.readAsString();
    final body = jsonDecode(payload);
    final nome = body['nome'];
    final preco = body['preco'];

    if (nome == null || preco == null) {
      return Response(400, body: jsonEncode({'mensagem': 'Nome e preço são obrigatórios.'}));
    }

    try {
      final sql = 'INSERT INTO produtos (nome, preco) VALUES (:nome, :preco)';
      final resultado = await pool.execute(sql, {'nome': nome, 'preco': preco});

      final produtoCriado = {
        'id': resultado.lastInsertID.toInt(),
        'nome': nome,
        'preco': preco
      };

      try {
        await http.post(
          Uri.parse('http://barramento-service:10000/eventos'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'tipo': 'ProdutoCriado', 'dados': produtoCriado}),
        );
      } catch (err) {
        print('Barramento fora do ar: $err');
      }

      return Response(201, 
        body: jsonEncode(produtoCriado), 
        headers: {'content-type': 'application/json; charset=utf-8'}
      );
    } catch (erro) {
      print('Erro ao inserir produto: $erro');
      return Response.internalServerError(body: jsonEncode({'mensagem': 'Erro interno.'}));
    }
  });

  final handler = const Pipeline()
      .addMiddleware(liberarCors())
      .addHandler(router.call);

  final servidor = await shelf_io.serve(handler, InternetAddress.anyIPv4, 3001);
  print('✅ Configurar_Produto em Dart rodando na porta ${servidor.port}');
}

// Middleware de CORS
Middleware liberarCors({String origem = '*'}) {
  final cabecalhos = {
    'access-control-allow-origin': origem,
    'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'access-control-allow-headers': 'Content-Type, Authorization',
    'access-control-max-age': '86400',
  };
  return (Handler proximo) {
    return (Request requisicao) async {
      if (requisicao.method == 'OPTIONS') return Response(204, headers: cabecalhos);
      return (await proximo(requisicao)).change(headers: cabecalhos);
    };
  };
}