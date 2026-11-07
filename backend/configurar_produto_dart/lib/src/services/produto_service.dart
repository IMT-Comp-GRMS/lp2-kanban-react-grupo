import '../core/erros.dart';
import '../models/produto.dart';
import '../repositories/produto_repository.dart';
import 'publicador_eventos.dart';

/// Regras de negócio do catálogo de produtos.
///
/// Recebe dados já desserializados, valida, decide e chama o repositório.
/// Não conhece HTTP nem SQL, por isso pode ser testado com chamadas comuns.
class ProdutoService {
  ProdutoService(this._repository, this._eventos);

  final ProdutoRepository _repository;
  final PublicadorEventos _eventos;

  Future<List<Produto>> listar() => _repository.listar();

  /// Busca um produto pelo id. Se não existir, lança NaoEncontrado, que o
  /// middleware de erros transforma em 404.
  Future<Produto> buscarPorId(int id) async {
    final produto = await _repository.buscarPorId(id);
    if (produto == null) {
      throw NaoEncontrado('Nao existe produto com id $id.');
    }
    return produto;
  }

  /// Valida todos os campos de uma vez e devolve o conjunto completo de
  /// problemas, para o usuário corrigir tudo em uma só rodada.
  void _validar(Produto p) {
    final erros = <String, String>{};

    final nome = p.nome.trim();
    if (nome.isEmpty || nome.length > 100) {
      erros['nome'] = 'Deve ter entre 1 e 100 caracteres.';
    }
    if (p.preco <= 0) {
      erros['preco'] = 'Deve ser maior que zero.';
    }

    if (erros.isNotEmpty) {
      throw ErroValidacao('Os dados enviados sao invalidos.', erros);
    }
  }

  /// Cadastra o produto e avisa os outros microsserviços pelo barramento
  /// (evento ProdutoCriado), para que atualizem suas cópias do catálogo.
  Future<Produto> criar(Produto novo) async {
    _validar(novo);
    final criado = await _repository.inserir(novo.copyWith(nome: novo.nome.trim()));
    await _eventos.publicar('ProdutoCriado', criado.toJson());
    return criado;
  }
}
