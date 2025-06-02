import 'dart:io';
import 'dart:math';
import 'dart:async';

Future<void> main() async {
  final ip = await getLocalIp();
  final server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    8080, // Porta que desejar
  );

  print('Servidor ESP32 Dummy rodando em: http://$ip:8080/data');

  final random = Random();

  await for (HttpRequest request in server) {
    if (request.method == 'GET' && request.uri.path == '/data') {
      final boolValue = random.nextBool() ? '1' : '0';

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write(boolValue);

      print('Enviado: $boolValue para ${request.connectionInfo?.remoteAddress.address}');
      await request.response.close();
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found');
      await request.response.close();
    }
  }
}

/// ✅ Função assíncrona atualizada para obter o IP local
Future<String> getLocalIp() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );

  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (!addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return 'localhost';
}
