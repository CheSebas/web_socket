import 'package:flutter/material.dart';
import 'usb_serial.dart';
import 'web_socket.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          headline6: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
          bodyText2: TextStyle(fontSize: 16.0),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SerialManager? _serialManager;
  WebSocketManager? _webSocketManager;
  String _status = "Idle";
  List<Widget> _serialData = [];

  @override
  void initState() {
    super.initState();
    _webSocketManager = WebSocketManager(onStatusChanged: (status) {
      setState(() {
        _status = status;
      });
    });

    _serialManager = SerialManager(
      onDataReceived: (data) {
        setState(() {
          _serialData.add(Text(data));
          if (_serialData.length > 20) {
            _serialData.removeAt(0);
          }
        });
        _webSocketManager?.sendData(data);
      },
      onStatusChanged: (status) {
        setState(() {
          _status = status;
        });
      },
    );
  }

  @override
  void dispose() {
    _serialManager?.dispose();
    _webSocketManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Serial Plugin'),
        actions: [
          Icon(_status.contains("Connected") ? Icons.check_circle : Icons.error, color: Colors.white),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              _serialManager!.ports.isNotEmpty
                  ? "Available Serial Ports"
                  : "No serial devices available",
              style: Theme.of(context).textTheme.headline6,
            ),
            ..._serialManager!.ports,
            const SizedBox(height: 20),
            _buildStatusBar(),
            const SizedBox(height: 20),
            _buildSendTextField(),
            const SizedBox(height: 20),
            Text("Received Data", style: Theme.of(context).textTheme.headline6),
            Expanded(
              child: ListView(
                children: _serialData,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Status: $_status', style: Theme.of(context).textTheme.bodyText2),
        if (_status.contains("Connected")) 
          const Icon(Icons.check_circle, color: Colors.green)
        else if (_status.contains("Failed"))
          const Icon(Icons.error, color: Colors.red)
        else
          const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildSendTextField() {
    return ListTile(
      title: TextField(
        controller: _serialManager!.textController,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Text To Send',
          suffixIcon: Icon(Icons.send),
        ),
      ),
      trailing: ElevatedButton.icon(
        icon: const Icon(Icons.send),
        label: const Text("Send"),
        onPressed: _serialManager!.port == null
            ? null
            : () => _serialManager!.sendDataToSerial(),
      ),
    );
  }
}