import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/user.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';
import 'package:einundzwanzig_meetup_app/widgets/nostr_avatar.dart';

// Keep image downloads pending: these tests exercise metadata/UI ordering, not
// Flutter's image decoder, and never contact a real image host.
class _ImageClient extends Fake implements HttpClient {
  final downloads = <Completer<HttpClientResponse>>[];
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final download = Completer<HttpClientResponse>();
    downloads.add(download);
    return _ImageRequest(download.future);
  }
}

class _ImageRequest extends Fake implements HttpClientRequest {
  _ImageRequest(this.response);
  final Future<HttpClientResponse> response;
  @override
  Future<HttpClientResponse> close() => response;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _ImageClient client;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = _ImageClient();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  tearDown(() {
    debugNetworkImageHttpClientProvider = null;
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  void avatarTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      debugNetworkImageHttpClientProvider = () => client;
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox());
        debugNetworkImageHttpClientProvider = null;
      }
    });
  }

  Widget avatar(String? author, Future<String?> Function(String) loader) =>
      MaterialApp(
        home: NostrAvatar(
          fallbackText: 'Alice',
          pubkeyHex: author,
          pictureLoader: loader,
        ),
      );
  String? url(WidgetTester tester) =>
      (tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundImage
              as NetworkImage?)
          ?.url;

  avatarTest(
    'late result from previous identity cannot replace current picture',
    (tester) async {
      final a = Completer<String?>();
      final b = Completer<String?>();
      Future<String?> loader(String author) =>
          author == 'alice' ? a.future : b.future;
      await tester.pumpWidget(avatar('alice', loader));
      await tester.pumpWidget(avatar('bob', loader));
      b.complete('https://images.example/bob.png');
      await tester.pumpAndSettle();
      expect(url(tester), 'https://images.example/bob.png');
      a.complete('https://images.example/alice.png');
      await tester.pumpAndSettle();
      expect(url(tester), 'https://images.example/bob.png');
    },
  );

  avatarTest(
    'identity switch immediately clears old picture, absent metadata uses letter',
    (tester) async {
      final b = Completer<String?>();
      Future<String?> loader(String author) async =>
          author == 'alice' ? 'https://images.example/alice.png' : b.future;
      await tester.pumpWidget(avatar('alice', loader));
      await tester.pumpAndSettle();
      expect(url(tester), isNotNull);
      await tester.pumpWidget(avatar('bob', loader));
      expect(url(tester), isNull);
      expect(find.text('A'), findsOneWidget);
      b.complete(null);
      await tester.pumpAndSettle();
      expect(url(tester), isNull);
    },
  );

  avatarTest('failed image download restores letter fallback', (tester) async {
    await tester.pumpWidget(
      avatar('alice', (_) async => 'https://images.example/fails.png'),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(url(tester), isNotNull);
    client.downloads.single.completeError(StateError('image unavailable'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    expect(url(tester), isNull);
    expect(find.text('A'), findsOneWidget);
  });

  avatarTest(
    'signer without local private key resolves public identity and loads avatar',
    (tester) async {
      const author =
          'fa5e3477d2d6b92d667dcab66c8bbb1527014599c5eecddd545e3a39d7870268';
      await SigningService.restoreNip07(Nip19.encodePubkey(author));
      final profile = await UserProfile.load();
      expect(profile.hasNostrKey, isFalse);
      expect(profile.nostrNpub, Nip19.encodePubkey(author));
      String? queried;
      await tester.pumpWidget(
        avatar(null, (hex) async {
          queried = hex;
          return 'https://images.example/external.png';
        }),
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(queried, author);
      expect(url(tester), 'https://images.example/external.png');
    },
  );

  avatarTest('completion after avatar disposal is harmless', (tester) async {
    final pending = Completer<String?>();
    await tester.pumpWidget(avatar('alice', (_) => pending.future));
    await tester.pumpWidget(const SizedBox());
    pending.complete('https://images.example/a.png');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
