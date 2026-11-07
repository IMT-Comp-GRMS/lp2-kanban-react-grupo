import 'dart:async';

// Validações dos formulários, no formato da apostila Flutter Gerenciamento de
// Estado: cada validação é um StreamTransformer. Se o valor é válido, ele passa
// adiante com sink.add; se não é, o transformer emite um erro com
// sink.addError, que o StreamBuilder mostra como errorText do campo.
mixin Validators {
  // Nome do produto: de 1 a 100 caracteres, sem contar os espaços das pontas
  // (mesma regra do serviço Configurar_Produto em Dart).
  final validarNome = StreamTransformer<String, String>.fromHandlers(
    handleData: (nome, sink) {
      final limpo = nome.trim();
      if (limpo.isEmpty) {
        sink.addError('Informe o nome do produto.');
      } else if (limpo.length > 100) {
        sink.addError('O nome pode ter no máximo 100 caracteres.');
      } else {
        sink.add(nome);
      }
    },
  );

  // Preço: aceita "199,90" ou "199.90" e precisa ser um número maior que zero.
  final validarPreco = StreamTransformer<String, String>.fromHandlers(
    handleData: (preco, sink) {
      final valor = double.tryParse(preco.trim().replaceAll(',', '.'));
      if (valor == null) {
        sink.addError('Informe um número (ex: 199,90).');
      } else if (valor <= 0) {
        sink.addError('O preço precisa ser maior que zero.');
      } else {
        sink.add(preco);
      }
    },
  );

  // Responsável pelo pedido: pelo menos 2 caracteres, sem contar os espaços.
  final validarResponsavel = StreamTransformer<String, String>.fromHandlers(
    handleData: (responsavel, sink) {
      if (responsavel.trim().length < 2) {
        sink.addError('Informe o responsável (pelo menos 2 letras).');
      } else {
        sink.add(responsavel);
      }
    },
  );

  // Produtos do pedido: a lista de ids marcados não pode estar vazia.
  final validarProdutos = StreamTransformer<List<int>, List<int>>.fromHandlers(
    handleData: (ids, sink) {
      if (ids.isEmpty) {
        sink.addError('Selecione pelo menos um produto.');
      } else {
        sink.add(ids);
      }
    },
  );
}
