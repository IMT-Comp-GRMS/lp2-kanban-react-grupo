import 'package:configurar_produto_dart/src/core/erros.dart';
import 'package:configurar_produto_dart/src/models/produto.dart';
import 'package:configurar_produto_dart/src/repositories/produto_repository.dart';
import 'package:configurar_produto_dart/src/services/produto_service.dart';
import 'package:configurar_produto_dart/src/services/publicador_eventos.dart';
import 'package:test/test.dart';

/// Repositório em memória, usado só nos testes.
///
/// Como o serviço depende da interface e não da classe concreta, ele não
/// percebe a diferença. Uma lista faz o papel da tabela e um contador faz o
/// papel do AUTO_INCREMENT.
class RepositorioFake implements ProdutoRepository {
  final List<Produto> _dados = [];
  int _proximoId = 1;

  @override
  Future<Produto> inserir(Produto produto) async {
    final salvo = produto.copyWith(id: _proximoId++);
    _dados.add(salvo);
    return salvo;
  }

  @override
  Future<List<Produto>> listar() async => List.of(_dados);

  @override
  Future<Produto?> buscarPorId(int id) async {
    for (final p in _dados) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Publicador falso: em vez de enviar ao barramento, guarda os eventos.
class PublicadorFake implements PublicadorEventos {
  final List<Map<String, dynamic>> enviados = [];

  @override
  Future<void> publicar(String tipo, Map<String, dynamic> dados) async {
    enviados.add({'tipo': tipo, 'dados': dados});
  }
}

void main() {
  late ProdutoService service;
  late PublicadorFake eventos;

  // setUp roda antes de cada teste: cada caso começa do zero.
  setUp(() {
    eventos = PublicadorFake();
    service = ProdutoService(RepositorioFake(), eventos);
  });

  // Fábrica de dados válidos: cada teste altera só o campo que lhe interessa.
  Produto valido({String nome = 'Calça Cargo Utilitária', double preco = 289.0}) =>
      Produto(nome: nome, preco: preco);

  test('cria um produto valido e recebe identificador', () async {
    final criado = await service.criar(valido());
    expect(criado.id, isNotNull);
    expect(criado.nome, 'Calça Cargo Utilitária');
  });

  test('publica o evento ProdutoCriado com os dados do produto', () async {
    final criado = await service.criar(valido());
    expect(eventos.enviados, hasLength(1));
    expect(eventos.enviados.first['tipo'], 'ProdutoCriado');
    expect(eventos.enviados.first['dados'], criado.toJson());
  });

  test('recusa produto sem nome', () {
    expect(
      () => service.criar(valido(nome: '   ')),
      throwsA(isA<ErroValidacao>()),
    );
  });

  test('recusa preco zero ou negativo', () {
    expect(
      () => service.criar(valido(preco: 0)),
      throwsA(isA<ErroValidacao>()),
    );
  });

  test('nao publica evento quando a validacao falha', () async {
    await expectLater(service.criar(valido(preco: -5)), throwsA(isA<ErroValidacao>()));
    expect(eventos.enviados, isEmpty);
  });

  test('lista os produtos cadastrados', () async {
    await service.criar(valido(nome: 'Calça A'));
    await service.criar(valido(nome: 'Calça B'));
    final lista = await service.listar();
    expect(lista.map((p) => p.nome), ['Calça A', 'Calça B']);
  });

  test('busca um produto existente pelo id', () async {
    final criado = await service.criar(valido(nome: 'Calça A'));
    final achado = await service.buscarPorId(criado.id!);
    expect(achado.nome, 'Calça A');
  });

  test('buscarPorId lança NaoEncontrado para id inexistente', () {
    expect(() => service.buscarPorId(999), throwsA(isA<NaoEncontrado>()));
  });
}
