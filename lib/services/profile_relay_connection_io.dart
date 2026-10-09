import 'dart:async';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Eigener HTTP-Client: Ein Timeout bricht auch einen laufenden Upgrade ab.
({WebSocketChannel channel, void Function() abort}) openProfileRelay(Uri uri) {
  final client = HttpClient();
  var aborted = false;
  final connecting = WebSocket.connect(uri.toString(), customClient: client);
  // Auch ein während des Abbruchs verbundener Socket muss geschlossen werden.
  unawaited(
    connecting.then((socket) {
      if (aborted) unawaited(socket.close().catchError((Object _) {}));
    }, onError: (Object _) {}),
  );
  return (
    channel: IOWebSocketChannel(connecting),
    abort: () {
      aborted = true;
      client.close(force: true);
    },
  );
}
