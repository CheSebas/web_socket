import 'dart:async';
import 'dart:io';

void main() async {

  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8910);
  print('WebSocket server is running on ws://localhost:8910');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocket socket = await WebSocketTransformer.upgrade(request);
      print('Client connected');

      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (socket.closeCode == null) {
          socket.add('Message from server every 5 seconds');
        } else {
          timer.cancel();
        }
      });

      socket.listen((message) {
        print('Received message from client: $message');

        socket.add('Server received: $message');
      });

      socket.done.then((_) {
        print('Client disconnected');
      });
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.close();
    }
  }
}