import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

class SerialManager {
  UsbPort? port;
  int? deviceId;
  List<Widget> ports = [];
  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  TextEditingController textController = TextEditingController();

  final Function(String) onDataReceived;
  final Function(String) onStatusChanged;

  SerialManager({required this.onDataReceived, required this.onStatusChanged}) {
    _getPorts();

    UsbSerial.usbEventStream?.listen((UsbEvent event) {
      _getPorts();
    });
  }

  Future<void> _getPorts() async {
    ports.clear();
    List<UsbDevice> devices = await UsbSerial.listDevices();

    for (var device in devices) {
      ports.add(ListTile(
        leading: const Icon(Icons.usb),
        title: Text(device.productName ?? 'Unknown Device'),
        subtitle: Text(device.manufacturerName ?? 'Unknown Manufacturer'),
        trailing: ElevatedButton(
          child: Text(deviceId == device.deviceId ? "Disconnect" : "Connect"),
          onPressed: () => _connectTo(deviceId == device.deviceId ? null : device),
        ),
      ));
    }
  }

  Future<bool> _connectTo(UsbDevice? device) async {
    await _disposeConnection();
    if (device == null) {
      deviceId = null;
      onStatusChanged("Disconnected");
      return true;
    }

    try {
      port = await device.create();
      if (port == null || !await port!.open()) {
        onStatusChanged("Failed to open port");
        return false;
      }

      deviceId = device.deviceId;
      await port!.setDTR(true);
      await port!.setRTS(true);
      await port!.setPortParameters(
          115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      _transaction = Transaction.stringTerminated(
          port!.inputStream!, Uint8List.fromList([13, 10]));

      _subscription = _transaction!.stream.listen(onDataReceived);

      onStatusChanged("Connected");
      return true;
    } catch (e) {
      onStatusChanged("Error: $e");
      return false;
    }
  }

  Future<void> _disposeConnection() async {
    await _subscription?.cancel();
    _subscription = null;

    _transaction?.dispose();
    _transaction = null;

    await port?.close();
    port = null;
  }

  void sendDataToSerial() async {
    try {
      String data = "${textController.text}\r\n";
      await port!.write(Uint8List.fromList(data.codeUnits));
      textController.clear();
    } catch (e) {
      onStatusChanged("Send failed: $e");
    }
  }

  void dispose() {
    _disposeConnection();
    textController.dispose();
  }
}