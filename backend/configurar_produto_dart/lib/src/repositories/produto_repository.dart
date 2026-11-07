import '../models/produto.dart';

/// Contrato de persistência de produtos.
///
/// A camada de serviço conversa só com esta interface e nunca menciona MySQL.
/// Assim, a implementação pode ser trocada (por exemplo, por uma em memória
/// nos testes) sem tocar na regra de negócio.
abstract interface class ProdutoRepository {
  Future<List<Produto>> listar();
  Future<Produto> inserir(Produto produto);
}
