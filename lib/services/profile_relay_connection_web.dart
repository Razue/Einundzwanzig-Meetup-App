import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Browser-Socket direkt schließen, auch während eines laufenden Upgrades.
({WebSocketChannel channel, void Function() abort}) openProfileRelay(Uri uri) {
  final channel = HtmlWebSocketChannel.connect(uri);
  return (channel: channel, abort: () => channel.innerWebSocket.close());
}
