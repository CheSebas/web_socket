import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketManager {
  WebSocketChannel? _webSocketChannel;
  final Function(String) onStatusChanged;

  WebSocketManager({required this.onStatusChanged}) {
    _connectToWebSocket();
  }

  Future<void> _connectToWebSocket() async {
    try {
      _webSocketChannel = WebSocketChannel.connect(Uri.parse('ws://localhost:8910'));
      onStatusChanged("Connected to WebSocket");

      _webSocketChannel!.stream.listen(
        (message) {
          // Aquí puedes manejar el mensaje recibido
        },
        onDone: () => _reconnectWebSocket(),
        onError: (error) => _reconnectWebSocket(error),
      );
    } catch (e) {
      onStatusChanged("WebSocket connection failed: $e");
    }
  }

  void _reconnectWebSocket([dynamic error]) {
    if (error != null) {
      onStatusChanged("WebSocket error: $error");
    }
    onStatusChanged("Reconnecting to WebSocket...");
    Future.delayed(const Duration(seconds: 5), _connectToWebSocket);
  }

  void sendData(String data) {
    if (_webSocketChannel != null) {
      try {
        _webSocketChannel!.sink.add(data);
        onStatusChanged("Data sent to WebSocket: $data");
      } catch (e) {
        onStatusChanged("Failed to send data: $e");
      }
    } else {
      onStatusChanged("No WebSocket connection available");
    }
  }

  void dispose() {
    _webSocketChannel?.sink.close();
  }
}