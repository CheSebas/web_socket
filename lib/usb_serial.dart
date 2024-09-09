// usb_serial.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

final StreamController<String> _serialStreamController = StreamController<String>();

class USBSerialHandler {
  UsbPort? _port;
  String _status = "Idle";
  StreamSubscription<String>? _subscription;
  Transaction<String>? _transaction;
  final List<String> _serialData = [];

  Future<bool> connectTo(UsbDevice? device) async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction!.dispose();
      _transaction = null;
    }

    if (_port != null) {
      await _port!.close();
      _port = null;
    }

    if (device == null) {
      _status = "Disconnected";
      return true;
    }

    _port = await device.create();
    if (!await _port!.open()) {
      _status = "Failed to open port";
      return false;
    }

    await _port!.setDTR(true);
    await _port!.setRTS(true);
    await _port!.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    if (_port!.inputStream != null) {
      _transaction = Transaction.stringTerminated(
          _port!.inputStream!, Uint8List.fromList([13, 10]));

      _subscription = _transaction!.stream.listen((String line) {
        _serialData.add(line);
        if (_serialData.length > 20) {
          _serialData.removeAt(0);
        }
        _serialStreamController.add(line); // Enviar datos al servidor WebSocket
      });
    } else {
      _status = "Failed to listen to port";
      return false;
    }

    _status = "Connected";
    return true;
  }

  Future<void> disconnect() async {
    await connectTo(null);
  }

  String getStatus() => _status;

  List<String> getSerialData() => _serialData;

  Future<List<UsbDevice>> getPorts() async {
    return await UsbSerial.listDevices();
  }

  Future<void> sendData(String data) async {
    if (_port != null) {
      await _port!.write(Uint8List.fromList(data.codeUnits));
    }
  }

  void close() {
    _serialStreamController.close();
  }
}
