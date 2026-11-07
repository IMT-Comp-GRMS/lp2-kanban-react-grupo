import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Contrato para publicar eventos no barramento.
///
/// O serviço depende desta interface, e não de HTTP diretamente. Nos testes
/// ela é trocada por uma versão falsa, que só guarda os eventos em uma lista.
abstract interface class PublicadorEventos {
  Future<void> publicar(String tipo, Map<String, dynamic> dados);
}

/// Implementação real: envia o evento ao barramento por HTTP.
class BarramentoHttp implements PublicadorEventos {
  BarramentoHttp(this._url);

  final String _url;

  @override
  Future<void> publicar(String tipo, Map<String, dynamic> dados) async {
    try {
      await http.post(
        Uri.parse(_url),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'tipo': tipo, 'dados': dados}),
      );
    } catch (erro) {
      // Comunicação assíncrona: se o barramento estiver fora do ar,
      // o produto continua salvo e o serviço continua respondendo.
      stderr.writeln('Barramento fora do ar: $erro');
    }
  }
}
