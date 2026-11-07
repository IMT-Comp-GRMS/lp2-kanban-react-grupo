// Produto do catálogo (GET /produtos do Configurar_Produto)
// JSON: {"id": 1, "nome": "Calça Cargo", "preco": 289.0}
class ProdutoModel {
  late int id;
  late String nome;
  late double preco;

  // construtor
  ProdutoModel(this.id, this.nome, this.preco);

  // construtor nomeado: monta o objeto a partir do JSON decodificado
  ProdutoModel.fromJSON(Map<String, dynamic> decodedJSON) {
    id = (decodedJSON['id'] as num).toInt();
    nome = decodedJSON['nome']?.toString() ?? '';
    preco = (decodedJSON['preco'] as num?)?.toDouble() ?? 0.0;
  }
}
