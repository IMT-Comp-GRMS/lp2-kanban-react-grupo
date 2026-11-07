// Testes do PedidoFormBloc (formulário "Novo Pedido" com padrão Bloc).

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_mobile/src/blocs/pedido_form_bloc.dart';

void main() {
  late PedidoFormBloc bloc;

  setUp(() => bloc = PedidoFormBloc());
  tearDown(() => bloc.dispose());

  test('responsável com menos de 2 letras gera erro', () {
    expect(bloc.responsavel, emitsError('Informe o responsável (pelo menos 2 letras).'));
    bloc.changeResponsavel(' a ');
  });

  test('lista de produtos começa vazia e gera erro', () {
    expect(bloc.produtosIds, emitsError('Selecione pelo menos um produto.'));
  });

  test('alternarProduto marca e desmarca', () {
    expect(
      bloc.produtosSelecionados,
      emitsInOrder([<int>[], [1], [1, 2], [2]]),
    );
    bloc.alternarProduto(1);
    bloc.alternarProduto(2);
    bloc.alternarProduto(1);
  });

  test('prioridade começa em 3 e pode mudar', () {
    expect(bloc.prioridade, emitsInOrder([3, 1]));
    bloc.changePrioridade(1);
  });

  test('podeSalvar só emite com responsável válido e algum produto', () async {
    final valores = <bool>[];
    final assinatura = bloc.podeSalvar.listen(valores.add, onError: (_) {});

    bloc.changeResponsavel('Rafa');
    await Future<void>.delayed(Duration.zero);
    expect(valores, isEmpty); // nenhum produto marcado

    bloc.alternarProduto(3);
    await Future<void>.delayed(Duration.zero);
    expect(valores, [true]);

    bloc.alternarProduto(3); // desmarcou o único produto
    await Future<void>.delayed(Duration.zero);
    expect(valores, [true]); // não emitiu de novo (agora é erro)

    await assinatura.cancel();
  });

  test('dadosParaSalvar devolve os valores prontos', () {
    bloc.changeResponsavel('  Rafa  ');
    bloc.changeDescricao(' urgente ');
    bloc.changePrioridade(2);
    bloc.alternarProduto(1);
    bloc.alternarProduto(3);
    final dados = bloc.dadosParaSalvar();
    expect(dados.responsavel, 'Rafa');
    expect(dados.descricao, 'urgente');
    expect(dados.prioridade, 2);
    expect(dados.produtosIds, [1, 3]);
  });
}
