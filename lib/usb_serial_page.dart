// usb_serial_page.dart

import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import 'usb_serial.dart'; // Importar el archivo usb_serial.dart

class USBSerialPage extends StatefulWidget {
  const USBSerialPage({super.key});

  @override
  _USBSerialPageState createState() => _USBSerialPageState();
}

class _USBSerialPageState extends State<USBSerialPage> {
  USBSerialHandler _usbSerialHandler = USBSerialHandler();
  List<Widget> _ports = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    UsbSerial.usbEventStream?.listen((UsbEvent event) {
      _getPorts();
    });

    _getPorts();
  }

  void _getPorts() async {
    List<UsbDevice> devices = await _usbSerialHandler.getPorts();
    List<Widget> portWidgets = [];

    for (var device in devices) {
      portWidgets.add(ListTile(
        leading: const Icon(Icons.usb),
        title: Text(device.productName ?? "Unknown device"),
        subtitle: Text(device.manufacturerName ?? "Unknown manufacturer"),
        trailing: ElevatedButton(
          child: Text(_usbSerialHandler.getStatus() == "Connected"
              ? "Disconnect"
              : "Connect"),
          onPressed: () {
            _usbSerialHandler
                .connectTo(
                    _usbSerialHandler.getStatus() == "Connected" ? null : device)
                .then((res) {
              setState(() {
                _getPorts();
              });
            });
          },
        ),
      ));
    }

    setState(() {
      _ports = portWidgets;
    });
  }

  @override
  void dispose() {
    _usbSerialHandler.disconnect();
    _usbSerialHandler.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USB Serial Page'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text(
              _ports.isNotEmpty
                  ? "Available Serial Ports"
                  : "No serial devices available",
              style: Theme.of(context).textTheme.headline6,
            ),
            ..._ports,
            Text('Status: ${_usbSerialHandler.getStatus()}\n'),
            ListTile(
              title: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Text To Send',
                ),
              ),
              trailing: ElevatedButton(
                onPressed: _usbSerialHandler.getStatus() == "Connected"
                    ? () async {
                        String data = "${_textController.text}\r\n";
                        await _usbSerialHandler.sendData(data);
                        _textController.clear();
                      }
                    : null,
                child: const Text("Send"),
              ),
            ),
            Text(
              "Result Data",
              style: Theme.of(context).textTheme.headline6,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _usbSerialHandler.getSerialData().length,
                itemBuilder: (context, index) {
                  return Text(_usbSerialHandler.getSerialData()[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
