import 'package:flutter/material.dart';

import '../blocs/pedido_form_bloc.dart';
import '../blocs/pedido_provider.dart';
import '../models/produto_model.dart';

// Assinatura do callback de salvar: os mesmos parâmetros do criarPedido da tela.
typedef SalvarPedido = void Function({
  required String descricao,
  required String responsavel,
  required int prioridade,
  required List<int> produtosIds,
});

// Diálogo "Novo Pedido" com o padrão Bloc. Antes usava StatefulBuilder +
// setStateDialog; agora cada campo é um stream do PedidoFormBloc.
//
// StatefulWidget só para ser dono do bloc: criado uma vez, fechado no dispose.
class DialogoPedido extends StatefulWidget {
  final List<ProdutoModel> produtos;
  final SalvarPedido onSalvar;

  const DialogoPedido({super.key, required this.produtos, required this.onSalvar});

  @override
  State<DialogoPedido> createState() => _DialogoPedidoState();
}

class _DialogoPedidoState extends State<DialogoPedido> {
  final bloc = PedidoFormBloc();

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PedidoProvider(
      bloc: bloc,
      child: _FormularioPedido(produtos: widget.produtos, onSalvar: widget.onSalvar),
    );
  }
}

class _FormularioPedido extends StatelessWidget {
  final List<ProdutoModel> produtos;
  final SalvarPedido onSalvar;

  const _FormularioPedido({required this.produtos, required this.onSalvar});

  static const _rotulo = TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3C5262));

  @override
  Widget build(BuildContext context) {
    final bloc = PedidoProvider.of(context);

    return AlertDialog(
      title: const Text('Novo Pedido - Velato'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SELECIONE OS PRODUTOS:', style: _rotulo),
            const SizedBox(height: 8),
            listaProdutos(bloc),
            const SizedBox(height: 16),
            TextField(
              onChanged: bloc.changeDescricao,
              decoration: const InputDecoration(labelText: 'Descrição detalhada'),
            ),
            campoResponsavel(bloc),
            const SizedBox(height: 16),
            const Text('PRIORIDADE:', style: _rotulo),
            campoPrioridade(bloc),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        botaoSalvar(context, bloc),
      ],
    );
  }

  // Checkboxes: leem a lista de ids marcados e chamam alternarProduto.
  // Embaixo, a mensagem de erro do validarProdutos (lista vazia).
  Widget listaProdutos(PedidoFormBloc bloc) {
    if (produtos.isEmpty) {
      return const Text('Nenhum produto no catálogo.', style: TextStyle(color: Colors.grey, fontSize: 13));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<int>>(
          stream: bloc.produtosSelecionados,
          builder: (context, snapshot) {
            final marcados = snapshot.data ?? const [];
            return Column(
              children: produtos.map((produto) {
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: const Color(0xFF3C5262),
                  value: marcados.contains(produto.id),
                  onChanged: (_) => bloc.alternarProduto(produto.id),
                  title: Text(
                    '${produto.nome} (R\$ ${produto.preco.toStringAsFixed(2)})',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            );
          },
        ),
        StreamBuilder<List<int>>(
          stream: bloc.produtosIds,
          builder: (context, snapshot) {
            if (!snapshot.hasError) return const SizedBox.shrink();
            return Text(
              snapshot.error.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            );
          },
        ),
      ],
    );
  }

  Widget campoResponsavel(PedidoFormBloc bloc) {
    return StreamBuilder<String>(
      stream: bloc.responsavel,
      builder: (context, snapshot) {
        return TextField(
          onChanged: bloc.changeResponsavel,
          decoration: InputDecoration(
            labelText: 'Responsável',
            errorText: snapshot.hasError ? snapshot.error.toString() : null,
          ),
        );
      },
    );
  }

  // O Dropdown lê a prioridade do stream e escreve nele ao mudar.
  Widget campoPrioridade(PedidoFormBloc bloc) {
    return StreamBuilder<int>(
      stream: bloc.prioridade,
      builder: (context, snapshot) {
        return DropdownButton<int>(
          value: snapshot.data ?? 3,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 1, child: Text('Alta (Urgente)')),
            DropdownMenuItem(value: 2, child: Text('Média (Padrão)')),
            DropdownMenuItem(value: 3, child: Text('Baixa (Opcional)')),
          ],
          onChanged: (valor) {
            if (valor != null) bloc.changePrioridade(valor);
          },
        );
      },
    );
  }

  // Salvar só fica ativo com responsável válido e pelo menos um produto.
  Widget botaoSalvar(BuildContext context, PedidoFormBloc bloc) {
    return StreamBuilder<bool>(
      stream: bloc.podeSalvar,
      builder: (context, snapshot) {
        return ElevatedButton(
          onPressed: snapshot.hasData
              ? () {
                  final dados = bloc.dadosParaSalvar();
                  Navigator.pop(context);
                  onSalvar(
                    descricao: dados.descricao,
                    responsavel: dados.responsavel,
                    prioridade: dados.prioridade,
                    produtosIds: dados.produtosIds,
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAE4F48),
            foregroundColor: Colors.white,
          ),
          child: const Text('Salvar'),
        );
      },
    );
  }
}
