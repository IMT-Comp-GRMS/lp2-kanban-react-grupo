import 'package:flutter/material.dart';

import 'pedido_form_bloc.dart';

// Mesmo papel do Provider (provider.dart), mas para o PedidoFormBloc: deixa o
// bloc do formulário de pedido disponível com PedidoProvider.of(context).
class PedidoProvider extends InheritedWidget {
  final PedidoFormBloc bloc;

  const PedidoProvider({super.key, required this.bloc, required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;

  static PedidoFormBloc of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PedidoProvider>()!.bloc;
  }
}
