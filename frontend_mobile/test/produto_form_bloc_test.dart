// Testes do ProdutoFormBloc (padrão Bloc da apostila Gerenciamento de Estado).
// Não precisam de tela nem de servidor: só escrevem nos sinks e leem os streams.

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_mobile/src/blocs/produto_form_bloc.dart';

void main() {
  late ProdutoFormBloc bloc;

  setUp(() => bloc = ProdutoFormBloc());
  tearDown(() => bloc.dispose());

  test('nome vazio ou só com espaços gera erro', () {
    expect(bloc.nome, emitsError('Informe o nome do produto.'));
    bloc.changeNome('   ');
  });

  test('preço zero gera erro', () {
    expect(bloc.preco, emitsError('O preço precisa ser maior que zero.'));
    bloc.changePreco('0');
  });

  test('preço que não é número gera erro', () {
    expect(bloc.preco, emitsError('Informe um número (ex: 199,90).'));
    bloc.changePreco('abc');
  });

  test('preço aceita vírgula ou ponto', () {
    expect(bloc.preco, emitsInOrder(['199,90', '199.90']));
    bloc.changePreco('199,90');
    bloc.changePreco('199.90');
  });

  test('podeSalvar só emite com os dois campos válidos', () async {
    final valores = <bool>[];
    final erros = <Object>[];
    final assinatura = bloc.podeSalvar.listen(valores.add, onError: erros.add);

    bloc.changeNome('Calça Teste');
    await Future<void>.delayed(Duration.zero);
    expect(valores, isEmpty); // falta o preço: botão continua desabilitado

    bloc.changePreco('0');
    await Future<void>.delayed(Duration.zero);
    expect(valores, isEmpty);
    expect(erros, isNotEmpty); // preço inválido

    bloc.changePreco('149,90');
    await Future<void>.delayed(Duration.zero);
    expect(valores, [true]); // agora o botão habilita

    await assinatura.cancel();
  });

  test('dadosParaSalvar devolve nome sem espaços e preço como double', () {
    bloc.changeNome('  Calça Teste  ');
    bloc.changePreco('149,90');
    final dados = bloc.dadosParaSalvar();
    expect(dados.nome, 'Calça Teste');
    expect(dados.preco, 149.90);
  });
}
