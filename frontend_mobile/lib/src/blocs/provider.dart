import 'package:flutter/material.dart';

import 'produto_form_bloc.dart';

// Provider da apostila Flutter Gerenciamento de Estado: um InheritedWidget que
// deixa o bloc disponível para qualquer widget abaixo dele na árvore, com
// Provider.of(context), sem precisar passar o bloc de construtor em construtor.
//
// Diferença em relação à apostila: lá o Provider cria o próprio bloc. Aqui ele
// recebe o bloc pronto, criado por um StatefulWidget (DialogoProduto), para
// que o bloc não seja recriado a cada rebuild e seja fechado no dispose.
class Provider extends InheritedWidget {
  final ProdutoFormBloc bloc;

  const Provider({super.key, required this.bloc, required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;

  static ProdutoFormBloc of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Provider>()!.bloc;
  }
}
