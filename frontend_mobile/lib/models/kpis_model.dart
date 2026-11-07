// Indicadores do topo do Dashboard (GET /dashboard/kpis)
// JSON: {"totalPedidos": 5, "entreguesHoje": 1, "urgentesAberto": 2, "totalProdutos": 4}
class KpisModel {
  late int totalPedidos;
  late int entreguesHoje;
  late int urgentesAberto;
  late int totalProdutos;

  // construtor
  KpisModel(this.totalPedidos, this.entreguesHoje, this.urgentesAberto, this.totalProdutos);

  // construtor nomeado: monta o objeto a partir do JSON decodificado
  KpisModel.fromJSON(Map<String, dynamic> decodedJSON) {
    totalPedidos = (decodedJSON['totalPedidos'] as num?)?.toInt() ?? 0;
    entreguesHoje = (decodedJSON['entreguesHoje'] as num?)?.toInt() ?? 0;
    urgentesAberto = (decodedJSON['urgentesAberto'] as num?)?.toInt() ?? 0;
    totalProdutos = (decodedJSON['totalProdutos'] as num?)?.toInt() ?? 0;
  }
}
