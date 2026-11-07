// Um dia do gráfico de volume (GET /dashboard/volume-diario)
// JSON: {"data": "07/11", "pedidos": 3}
class VolumeDiarioModel {
  late String data;
  late int pedidos;

  // construtor
  VolumeDiarioModel(this.data, this.pedidos);

  // construtor nomeado: monta o objeto a partir do JSON decodificado
  VolumeDiarioModel.fromJSON(Map<String, dynamic> decodedJSON) {
    data = decodedJSON['data']?.toString() ?? '';
    pedidos = (decodedJSON['pedidos'] as num?)?.toInt() ?? 0;
  }
}
