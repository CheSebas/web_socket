import 'package:flutter/material.dart';
import 'usb_serial_page.dart'; // Importa la nueva página

void main() {
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: USBSerialPage(),
    );
  }
}



// import 'dart:async';
// import 'dart:typed_data';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:usb_serial/transaction.dart';
// import 'package:usb_serial/usb_serial.dart';

// final StreamController<String> _serialStreamController = StreamController<String>();

// void main() {
//   runApp(const MyApp());
//   startWebSocketServer();  // Iniciar el servidor WebSocket junto con la aplicación
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   UsbPort? _port;
//   String _status = "Idle";
//   List<Widget> _ports = [];
//   final List<String> _serialData = [];
//   StreamSubscription<String>? _subscription;
//   Transaction<String>? _transaction;
//   int? _deviceId;
//   final TextEditingController _textController = TextEditingController();

//   Future<bool> _connectTo(UsbDevice? device) async {
//     if (_subscription != null) {
//       await _subscription!.cancel();
//       _subscription = null;
//     }

//     if (_transaction != null) {
//       _transaction!.dispose();
//       _transaction = null;
//     }

//     if (_port != null) {
//       await _port!.close();
//       _port = null;
//     }

//     if (device == null) {
//       _deviceId = null;
//       setState(() {
//         _status = "Disconnected";
//       });
//       return true;
//     }

//     _port = await device.create();
//     if (!await _port!.open()) {
//       setState(() {
//         _status = "Failed to open port";
//       });
//       return false;
//     }

//     _deviceId = device.deviceId;
//     await _port!.setDTR(true);
//     await _port!.setRTS(true);
//     await _port!.setPortParameters(
//         115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

//     if (_port!.inputStream != null) {
//       _transaction = Transaction.stringTerminated(
//           _port!.inputStream!, Uint8List.fromList([13, 10]));

//       _subscription = _transaction!.stream.listen((String line) {
//         setState(() {
//           _serialData.add(line);
//           if (_serialData.length > 20) {
//             _serialData.removeAt(0);
//           }
//         });
//         // Enviar datos al servidor WebSocket
//         _serialStreamController.add(line);
//       });
//     } else {
//       setState(() {
//         _status = "Failed to listen to port";
//       });
//       return false;
//     }

//     setState(() {
//       _status = "Connected";
//     });
//     return true;
//   }

//   void _getPorts() async {
//     _ports = [];
//     List<UsbDevice> devices = await UsbSerial.listDevices();
//     print(devices);

//     for (var device in devices) {
//       _ports.add(ListTile(
//         leading: const Icon(Icons.usb),
//         title: Text(device.productName ?? "Unknown device"),
//         subtitle: Text(device.manufacturerName ?? "Unknown manufacturer"),
//         trailing: ElevatedButton(
//           child: Text(_deviceId == device.deviceId ? "Disconnect" : "Connect"),
//           onPressed: () {
//             _connectTo(_deviceId == device.deviceId ? null : device)
//                 .then((res) {
//               _getPorts();
//             });
//           },
//         ),
//       ));
//     }

//     setState(() {});
//   }

//   @override
//   void initState() {
//     super.initState();

//     UsbSerial.usbEventStream?.listen((UsbEvent event) {
//       _getPorts();
//     });

//     _getPorts();
//   }

//   @override
//   void dispose() {
//     _connectTo(null);
//     _serialStreamController.close();  // Cerrar el StreamController al finalizar
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('USB Serial app'),
//         ),
//         body: Center(
//           child: Column(
//             children: <Widget>[
//               Text(
//                 _ports.isNotEmpty
//                     ? "Available Serial Ports"
//                     : "No serial devices available",
//                 style: Theme.of(context).textTheme.headline6,
//               ),
//               ..._ports,
//               Text('Status: $_status\n'),
//               ListTile(
//                 title: TextField(
//                   controller: _textController,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(),
//                     labelText: 'Text To Send',
//                   ),
//                 ),
//                 trailing: ElevatedButton(
//                   onPressed: _port == null
//                       ? null
//                       : () async {
//                           if (_port == null) return;
//                           String data = "${_textController.text}\r\n";
//                           await _port!.write(Uint8List.fromList(data.codeUnits));
//                           _textController.clear();
//                         },
//                   child: const Text("Send"),
//                 ),
//               ),
//               Text(
//                 "Result Data",
//                 style: Theme.of(context).textTheme.headline6,
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: _serialData.length,
//                   itemBuilder: (context, index) {
//                     return Text(_serialData[index]);
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



// void startWebSocketServer() async {
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
