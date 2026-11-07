// Uma movimentação do pedido (GET /historico/:pedido_id do Historico)
// JSON: {"status_anterior": "Pedidos", "status_novo": "Pagamento Confirmado",
//        "data_hora": "07/11/2026 14:30:00"}
class HistoricoModel {
  late String statusAnterior;
  late String statusNovo;
  late String dataHora;

  // construtor
  HistoricoModel(this.statusAnterior, this.statusNovo, this.dataHora);

  // construtor nomeado: monta o objeto a partir do JSON decodificado
  HistoricoModel.fromJSON(Map<String, dynamic> decodedJSON) {
    statusAnterior = decodedJSON['status_anterior']?.toString() ?? '—';
    statusNovo = decodedJSON['status_novo']?.toString() ?? '';
    dataHora = decodedJSON['data_hora']?.toString() ?? '';
  }
}
