import 'package:rxdart/rxdart.dart';

import 'validators.dart';

// Bloc do formulário "Novo Pedido", no mesmo estilo do ProdutoFormBloc
// (apostila Flutter Gerenciamento de Estado). Cada campo é um BehaviorSubject;
// a tela escreve com os métodos change/alternar e lê os streams.
class PedidoFormBloc with Validators {
  final _responsavel = BehaviorSubject<String>();
  // A descrição é opcional, por isso começa com texto vazio.
  final _descricao = BehaviorSubject<String>.seeded('');
  // Prioridade começa em 3 (Baixa), como no formulário antigo.
  final _prioridade = BehaviorSubject<int>.seeded(3);
  final _produtosIds = BehaviorSubject<List<int>>.seeded(const []);

  // Saídas
  Stream<String> get responsavel => _responsavel.stream.transform(validarResponsavel);
  Stream<int> get prioridade => _prioridade.stream;
  // Lista sem validação: é a que as checkboxes leem para saber o que está marcado.
  Stream<List<int>> get produtosSelecionados => _produtosIds.stream;
  // Lista validada: emite erro quando está vazia (mensagem embaixo da lista).
  Stream<List<int>> get produtosIds => _produtosIds.stream.transform(validarProdutos);

  // Entradas
  Function(String) get changeResponsavel => _responsavel.sink.add;
  Function(String) get changeDescricao => _descricao.sink.add;
  Function(int) get changePrioridade => _prioridade.sink.add;

  // Marca ou desmarca um produto. Cria uma lista nova a cada vez para que o
  // stream emita o valor atualizado.
  void alternarProduto(int id) {
    final atual = List<int>.from(_produtosIds.value);
    if (atual.contains(id)) {
      atual.remove(id);
    } else {
      atual.add(id);
    }
    _produtosIds.sink.add(atual);
  }

  // Só emite quando o responsável é válido e há pelo menos um produto.
  Stream<bool> get podeSalvar =>
      CombineLatestStream.combine2(responsavel, produtosIds, (r, p) => true);

  // Lê os últimos valores e devolve prontos para o POST /tarefas.
  ({String descricao, String responsavel, int prioridade, List<int> produtosIds}) dadosParaSalvar() {
    return (
      descricao: _descricao.value.trim(),
      responsavel: _responsavel.value.trim(),
      prioridade: _prioridade.value,
      produtosIds: List<int>.from(_produtosIds.value),
    );
  }

  void dispose() {
    _responsavel.close();
    _descricao.close();
    _prioridade.close();
    _produtosIds.close();
  }
}
