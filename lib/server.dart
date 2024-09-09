// import 'dart:async';
// import 'dart:io';

// void main() async {
//   // Crear servidor WebSocket escuchando en el puerto 8910
//   var server = await HttpServer.bind(InternetAddress.anyIPv4, 8910);
//   print('Servidor WebSocket está corriendo en ws://localhost:8910');

//   // Lista para almacenar los sockets de los clientes conectados
//   List<WebSocket> clients = [];

//   // Temporizador para enviar mensajes cada 5 segundos si no se reciben mensajes desde main.dart
//   Timer? periodicTimer;

//   // Función para enviar mensajes a todos los clientes conectados
//   void sendMessageToClients(String message) {
//     for (var client in clients) {
//       if (client.readyState == WebSocket.open) {
//         client.add(message);
//       }
//     }
//   }

//   // Escuchar conexiones entrantes
//   await for (HttpRequest request in server) {
//     if (WebSocketTransformer.isUpgradeRequest(request)) {
//       WebSocket socket = await WebSocketTransformer.upgrade(request);
//       clients.add(socket);
//       print('Cliente conectado');

//       // Reiniciar el temporizador cada vez que se conecta un nuevo cliente
//       periodicTimer?.cancel();
//       periodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
//         sendMessageToClients('Mensaje predeterminado cada 5 segundos');
//       });

//       // Escuchar mensajes desde main.dart y reenviarlos a los clientes
//       socket.listen((message) {
//         print('Mensaje recibido de main.dart: $message');

//         // Enviar el mensaje recibido a todos los clientes
//         sendMessageToClients(message);

//         // Reiniciar el temporizador al recibir un mensaje
//         periodicTimer?.cancel();
//         periodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
//           sendMessageToClients('Mensaje predeterminado cada 5 segundos');
//         });
//       }, onDone: () {
//         clients.remove(socket);
//         print('Cliente desconectado');

//         // Si no hay más clientes conectados, detener el temporizador
//         if (clients.isEmpty) {
//           periodicTimer?.cancel();
//         }
//       });
//     } else {
//       request.response.statusCode = HttpStatus.forbidden;
//       request.response.close();
//     }
//   }
// }


// import 'dart:async';
// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as io;
// import 'package:shelf_router/shelf_router.dart';
// import 'package:shelf_web_socket/shelf_web_socket.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// void main() async {
//   final router = Router();

//   // Lista para almacenar todos los clientes conectados
//   final List<WebSocketChannel> clients = [];

//   // Ruta para manejar conexiones WebSocket
//   router.get('/ws', webSocketHandler((WebSocketChannel webSocket) {
//     print('New WebSocket connection');

//     // Agregar cliente a la lista de clientes conectados
//     clients.add(webSocket);

//     // Escuchar mensajes desde el cliente
//     webSocket.stream.listen((message) {
//       print('Received message: $message');
//       // Enviar un mensaje de vuelta al cliente
//       webSocket.sink.add('Echo: $message');
//     }, onDone: () {
//       print('Client disconnected');
//       // Eliminar cliente de la lista cuando se desconecta
//       clients.remove(webSocket);
//     });
//   }));

//   // Ruta HTTP tradicional
//   router.get('/', (Request request) {
//     return Response.ok('Hello, world!');
//   });

//   final handler = const Pipeline().addHandler(router);

//   final server = await io.serve(handler, 'localhost', 8910);
//   print('Server listening on port ${server.port}');

//   // Enviar mensajes periódicamente a todos los clientes conectados
//   Timer.periodic(Duration(seconds: 5), (Timer timer) {
//     final message = 'Server message at ${DateTime.now()}';
//     print('Sending to all clients: $message');
//     for (var client in clients) {
//       client.sink.add(message);
//     }
//   });
// }
