import 'dart:io';
import 'dart:math';
import 'dart:async';

void main() async {
  final ip = await getLocalIp();

  final esp32Ports = [8080, 8081];
  final servers = <HttpServer>[];

  for (var port in esp32Ports) {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    servers.add(server);
    print('Dummy ESP32 rodando em http://$ip:$port/data');

    server.listen((HttpRequest request) {
      if (request.method == 'GET' && request.uri.path == '/data') {
        final value = Random().nextBool() ? '1' : '0';
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.text
          ..write(value)
          ..close();
        print('[$port] Enviado valor $value para ${request.connectionInfo?.remoteAddress.address}');
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    });
  }
}

Future<String> getLocalIp() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );

  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (!addr.isLoopback) return addr.address;
    }
  }
  return 'localhost';
}
