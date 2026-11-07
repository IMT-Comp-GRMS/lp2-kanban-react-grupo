/// Um produto do catálogo da Velato.
///
/// Classe imutável: todos os campos são final, e alterar algo produz um novo
/// objeto via [copyWith]. O modelo não importa shelf nem mysql_dart, ou seja,
/// não sabe nada de HTTP nem de SQL.
class Produto {
  const Produto({this.id, required this.nome, required this.preco});

  /// Nulo enquanto o produto ainda não foi gravado no banco.
  final int? id;
  final String nome;
  final double preco;

  Produto copyWith({int? id, String? nome, double? preco}) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      preco: preco ?? this.preco,
    );
  }

  /// Representação enviada ao cliente e ao barramento de eventos.
  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'preco': preco,
      };
}
