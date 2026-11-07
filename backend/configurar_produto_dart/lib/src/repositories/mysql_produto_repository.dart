import 'package:mysql_dart/mysql_dart.dart';

import '../models/produto.dart';
import 'produto_repository.dart';

/// Implementação do repositório de produtos em MySQL.
class MySqlProdutoRepository implements ProdutoRepository {
  MySqlProdutoRepository(this._pool);

  final MySQLConnectionPool _pool;

  /// Colunas listadas explicitamente em vez de SELECT *.
  static const String _colunas = 'id, nome, preco';

  /// Converte uma linha do resultado em um Produto.
  ///
  /// O driver devolve as colunas como texto (o DECIMAL do preço inclusive,
  /// para preservar a precisão). A conversão fica aqui, no único ponto do
  /// sistema que conhece o formato do banco.
  Produto _mapear(ResultSetRow linha) {
    final dados = linha.assoc().cast<String, String?>();
    return Produto(
      id: int.parse(dados['id']!),
      nome: dados['nome']!,
      preco: double.parse(dados['preco']!),
    );
  }

  @override
  Future<List<Produto>> listar() async {
    final resultado = await _pool.execute('SELECT $_colunas FROM produtos ORDER BY id');
    return resultado.rows.map(_mapear).toList();
  }

  @override
  Future<Produto?> buscarPorId(int id) async {
    final resultado = await _pool.execute(
      'SELECT $_colunas FROM produtos WHERE id = :id',
      {'id': id},
    );
    if (resultado.rows.isEmpty) return null;
    return _mapear(resultado.rows.first);
  }

  @override
  Future<Produto> inserir(Produto produto) async {
    // Parâmetros nomeados: o valor nunca é concatenado no texto do comando,
    // o que elimina a possibilidade de injeção de SQL.
    final resultado = await _pool.execute(
      'INSERT INTO produtos (nome, preco) VALUES (:nome, :preco)',
      {'nome': produto.nome, 'preco': produto.preco},
    );
    return produto.copyWith(id: resultado.lastInsertID.toInt());
  }
}
