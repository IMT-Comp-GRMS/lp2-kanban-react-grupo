import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Prefixo usado para identificar os tipos de problema desta API.
const String _baseTipos = 'https://velato.local/problemas';

/// Monta uma resposta de erro no formato padronizado pela RFC 9457
/// (problem details): type, title, status e detail.
Response problema({
  required int status,
  required String titulo,
  required String detalhe,
  String? tipo,
  Map<String, dynamic> extras = const {},
}) {
  final corpo = <String, dynamic>{
    'type': tipo == null ? 'about:blank' : '$_baseTipos/$tipo',
    'title': titulo,
    'status': status,
    'detail': detalhe,
    ...extras,
  };

  return Response(
    status,
    body: jsonEncode(corpo),
    headers: {'content-type': 'application/problem+json; charset=utf-8'},
  );
}
