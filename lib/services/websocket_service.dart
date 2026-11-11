import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class WebSocketService {
  late IO.Socket socket;
  
  void connect() {
    final String serverUrl = kIsWeb ? 'http://127.0.0.1:5000' : 'http://10.0.2.2:5000';

    socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'forceNew': true,
    });

    socket.onConnect((_) {
      debugPrint('Websocket connected to: $serverUrl');
    });

    socket.onDisconnect((_) {
      debugPrint('Websocket disconnected');
    });
  }

  // Listener untuk Warga & Admin
  void listenToQueueCreated(Function(dynamic) onEvent) {
    socket.on('queue.created', onEvent);
  }

  void listenToQueueCalled(Function(dynamic) onEvent) {
    socket.on('queue.called', onEvent);
  }

  void disconnect() {
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();
  }
}