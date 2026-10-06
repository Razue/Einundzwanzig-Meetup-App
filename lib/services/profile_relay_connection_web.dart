import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Close the browser socket directly, including while its upgrade is pending.
({WebSocketChannel channel, void Function() abort}) openProfileRelay(Uri uri) {
  final channel = HtmlWebSocketChannel.connect(uri);
  return (channel: channel, abort: () => channel.innerWebSocket.close());
}
