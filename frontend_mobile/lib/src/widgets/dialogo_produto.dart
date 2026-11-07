import 'package:flutter/material.dart';

import '../blocs/produto_form_bloc.dart';
import '../blocs/provider.dart';

// Diálogo "Configurar Produto" com o padrão Bloc.
//
// É um StatefulWidget só para ser dono do bloc: o bloc é criado uma vez, junto
// com o State, e fechado no dispose quando o diálogo some.
class DialogoProduto extends StatefulWidget {
  // Chamado com os dados já validados quando o usuário clica em Adicionar.
  final void Function(String nome, double preco) onSalvar;

  const DialogoProduto({super.key, required this.onSalvar});

  @override
  State<DialogoProduto> createState() => _DialogoProdutoState();
}

class _DialogoProdutoState extends State<DialogoProduto> {
  final bloc = ProdutoFormBloc();

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      bloc: bloc,
      child: _FormularioProduto(onSalvar: widget.onSalvar),
    );
  }
}

class _FormularioProduto extends StatelessWidget {
  final void Function(String nome, double preco) onSalvar;

  const _FormularioProduto({required this.onSalvar});

  @override
  Widget build(BuildContext context) {
    // Como na apostila: o bloc vem do Provider, não do construtor.
    final bloc = Provider.of(context);

    return AlertDialog(
      title: const Text('Configurar Produto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          campoNome(bloc),
          campoPreco(bloc),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        botaoSalvar(context, bloc),
      ],
    );
  }

  // Cada campo é um StreamBuilder: escreve no sink a cada tecla e mostra o
  // erro que o Validator emitiu (se houver).
  Widget campoNome(ProdutoFormBloc bloc) {
    return StreamBuilder<String>(
      stream: bloc.nome,
      builder: (context, snapshot) {
        return TextField(
          onChanged: bloc.changeNome,
          decoration: InputDecoration(
            labelText: 'Nome do produto',
            errorText: snapshot.hasError ? snapshot.error.toString() : null,
          ),
        );
      },
    );
  }

  Widget campoPreco(ProdutoFormBloc bloc) {
    return StreamBuilder<String>(
      stream: bloc.preco,
      builder: (context, snapshot) {
        return TextField(
          onChanged: bloc.changePreco,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Preço (ex: 199,90)',
            errorText: snapshot.hasError ? snapshot.error.toString() : null,
          ),
        );
      },
    );
  }

  // O botão só fica ativo quando podeSalvar tem dado, ou seja, quando os dois
  // campos estão válidos ao mesmo tempo (CombineLatestStream).
  Widget botaoSalvar(BuildContext context, ProdutoFormBloc bloc) {
    return StreamBuilder<bool>(
      stream: bloc.podeSalvar,
      builder: (context, snapshot) {
        return ElevatedButton(
          onPressed: snapshot.hasData
              ? () {
                  final dados = bloc.dadosParaSalvar();
                  Navigator.pop(context);
                  onSalvar(dados.nome, dados.preco);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E1172),
            foregroundColor: Colors.white,
          ),
          child: const Text('Adicionar'),
        );
      },
    );
  }
}
