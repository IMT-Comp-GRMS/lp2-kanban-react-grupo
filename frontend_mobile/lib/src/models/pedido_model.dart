// Pedido do Kanban (GET /tarefas do Criar_Pedido)
// JSON: {"id": 1, "titulo": "Calça Cargo + Calça Slim", "descricao": "...",
//        "responsavel": "Ana", "status": "Pedidos", "prioridade": 1}
class PedidoModel {
  late int id;
  late String titulo;
  late String descricao;
  late String responsavel;
  late String status;
  late int prioridade; // 1 = Alta, 2 = Média, 3 = Baixa

  // construtor
  PedidoModel(this.id, this.titulo, this.descricao, this.responsavel, this.status, this.prioridade);

  // construtor nomeado: monta o objeto a partir do JSON decodificado
  PedidoModel.fromJSON(Map<String, dynamic> decodedJSON) {
    id = (decodedJSON['id'] as num).toInt();
    titulo = decodedJSON['titulo']?.toString() ?? 'Pedido';
    descricao = decodedJSON['descricao']?.toString() ?? '';
    responsavel = decodedJSON['responsavel']?.toString() ?? '';
    status = decodedJSON['status']?.toString() ?? 'Pedidos';
    prioridade = (decodedJSON['prioridade'] as num?)?.toInt() ?? 3;
  }
}
