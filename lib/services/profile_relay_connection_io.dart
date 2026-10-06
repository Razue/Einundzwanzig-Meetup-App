import 'dart:async';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Own the HTTP client so an expired deadline also cancels a pending upgrade.
({WebSocketChannel channel, void Function() abort}) openProfileRelay(Uri uri) {
  final client = HttpClient();
  var aborted = false;
  final connecting = WebSocket.connect(uri.toString(), customClient: client);
  // A connection completing during cancellation must not leave a live socket.
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
