// Um produto do ranking "mais pedidos" (GET /dashboard/produtos-mais-pedidos)
// JSON: {"nome": "Calça Cargo", "pedidos": 7}
class ProdutoRankingModel {
  late String nome;
  late int pedidos;

  // construtor
  ProdutoRankingModel(this.nome, this.pedidos);

  // construtor nomeado: monta o objeto a partir do JSON decodificado
  ProdutoRankingModel.fromJSON(Map<String, dynamic> decodedJSON) {
    nome = decodedJSON['nome']?.toString() ?? '';
    pedidos = (decodedJSON['pedidos'] as num?)?.toInt() ?? 0;
  }
}
