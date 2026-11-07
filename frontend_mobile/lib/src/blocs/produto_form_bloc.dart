import 'package:rxdart/rxdart.dart';

import 'validators.dart';

// Bloc do formulário "Configurar Produto" (apostila Flutter Gerenciamento de
// Estado). A tela não guarda o estado dos campos: ela só escreve nos sinks
// (changeNome, changePreco) e lê os streams já validados (nome, preco).
class ProdutoFormBloc with Validators {
  // BehaviorSubject guarda o último valor, que é lido com .value na hora de
  // salvar (é por isso que a apostila usa BehaviorSubject e não um
  // StreamController comum).
  final _nome = BehaviorSubject<String>();
  final _preco = BehaviorSubject<String>();

  // Saídas: os valores digitados, passando pelas validações do mixin.
  Stream<String> get nome => _nome.stream.transform(validarNome);
  Stream<String> get preco => _preco.stream.transform(validarPreco);

  // Entradas: usadas direto no onChanged dos TextField.
  Function(String) get changeNome => _nome.sink.add;
  Function(String) get changePreco => _preco.sink.add;

  // Só emite um valor quando os dois campos têm valor válido. Se algum emitir
  // erro, o StreamBuilder do botão fica sem dado e o botão é desabilitado.
  Stream<bool> get podeSalvar =>
      CombineLatestStream.combine2(nome, preco, (n, p) => true);

  // Lê os últimos valores e devolve prontos para o POST /produtos.
  ({String nome, double preco}) dadosParaSalvar() {
    return (
      nome: _nome.value.trim(),
      preco: double.parse(_preco.value.trim().replaceAll(',', '.')),
    );
  }

  void dispose() {
    _nome.close();
    _preco.close();
  }
}
