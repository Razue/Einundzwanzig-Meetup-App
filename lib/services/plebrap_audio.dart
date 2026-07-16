// ============================================
// PLEBRAP AUDIO — app-weiter Player-Zustand
// ============================================
// EIN AudioPlayer fuer die ganze App: Dashboard-Mini-Player und der volle
// Player-Screen steuern DENSELBEN Zustand. Der Player wird nie disposed —
// die Musik laeuft weiter, wenn der Screen geschlossen wird (genau das
// macht den Mini-Player auf dem Dashboard erst sinnvoll).
// Auto-Weiter (Song fertig -> naechster) lebt ebenfalls HIER, nicht im
// Screen — sonst endet die Wiedergabe, sobald der Screen zu ist.
// ============================================

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'app_logger.dart';

class PlebSong {
  final String album;
  final String title;
  final String artist;
  final String url;
  const PlebSong({required this.album, required this.title, required this.artist, required this.url});

  /// Album-Cover von plebrap.de — bei Ladefehler faellt die UI aufs Icon zurueck.
  String get cover {
    switch (album) {
      case 'Money Fest':
        return 'https://plebrap.de/.cm4all/uproc.php/0/.video_2024-11-01_13-33-06.mp4/poster?_=192f3022949';
      case 'Pleb2Pleb EP':
        return 'https://plebrap.de/.cm4all/uproc.php/0/.Pleb2Pleb_1.jpg/picture-200?_=18df683959a';
      default: // Proof of Word EP + Singles: Crewfoto der Seite
        return 'https://plebrap.de/.cm4all/uproc.php/0/photo_2022-08-08_13-08-28.jpg';
    }
  }
}

const List<PlebSong> kPlebSongs = [
  PlebSong(album: 'Money Fest', title: 'Money Fest', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/01-Money%20Fest-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e4484b03'),
  PlebSong(album: 'Money Fest', title: 'Mouse Click Money', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/02-Mouse%20Click%20Money-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e44943e3'),
  PlebSong(album: 'Money Fest', title: 'Modern Märchen Token', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/03-Modern%20Ma%CC%88rchen%20Token-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e44a4c54'),
  PlebSong(album: 'Money Fest', title: 'SHA \'o\' lin', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/04-SHA%20%27o%27%20lin-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e456e3fe'),
  PlebSong(album: 'Money Fest', title: 'Collective Behavior Data Coin', artist: 'TooBitToFail feat. JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/05-Collective%20Behavior%20Data%20Coin-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e44b21da'),
  PlebSong(album: 'Money Fest', title: 'Was Bitcoin nicht bringt', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/06-Was%20Bitcoin%20nicht%20bringt-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e44d40ad'),
  PlebSong(album: 'Money Fest', title: 'B-Ware', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/07-B-Ware-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e44f74c7'),
  PlebSong(album: 'Money Fest', title: 'Bar-rierefrei', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/08-Bar-rierefrei-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e4504186'),
  PlebSong(album: 'Money Fest', title: 'Don\'t trust, verify', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/09-Don%60t%20trust%2C%20verify-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e45110b1'),
  PlebSong(album: 'Money Fest', title: 'Miss Stackchelorette', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/10-Miss%20Stackchelorette-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e451de99'),
  PlebSong(album: 'Money Fest', title: 'Moon Ätherisierung', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/11-Moon%20A%CC%88therisierung-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e454c72e'),
  PlebSong(album: 'Money Fest', title: 'Signale', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/12-Signale-Too%20Bit%20To%20Fail.mp3?cdp=a&_=192e4561d25'),
  PlebSong(album: 'Proof of Word EP', title: 'Proof of Word', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/Proof-of-Word-Too-Bit-To-Fail.mp3?cdp=a&_=18e04c99f1d'),
  PlebSong(album: 'Proof of Word EP', title: 'Cancel Bank Direct Control', artist: 'TooBitToFail feat. JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Cancel-Bank-Direct-Control-Too-Bit-To-Fail-feat.-JustAnotherNode.mp3?cdp=a&_=18e0e85aa60'),
  PlebSong(album: 'Proof of Word EP', title: 'Orange Pill \'o\' Sophie', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/Orange-Pill-o-Sophie-Too-Bit-To-Fail.mp3?cdp=a&_=18e0e873495'),
  PlebSong(album: 'Proof of Word EP', title: 'BitSkit (I don\'t give a FUD)', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/BitSkit-I-dontt-give-a-FUD-Too-Bit-To-Fail.mp3?cdp=a&_=18e0e8879c6'),
  PlebSong(album: 'Proof of Word EP', title: 'Bubble Trouble', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/Bubble-Trouble-Too-Bit-To-Fail.mp3?cdp=a&_=18e0e89afdb'),
  PlebSong(album: 'Proof of Word EP', title: 'Das Geldsystem ist krank', artist: 'TooBitToFail, Beat: Meidi', url: 'https://plebrap.de/.cm4all/uproc.php/0/Das-Geldsystem-ist-krank-Too-Bit-To-Fail-Beat-by-Meidi_BTC-Beatz.mp3?cdp=a&_=18e0e8a8e11'),
  PlebSong(album: 'Proof of Word EP', title: 'Diamond Hands', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/Diamond-Hands-Too-Bit-To-Fail.mp3?cdp=a&_=18e0e8b7c7b'),
  PlebSong(album: 'Proof of Word EP', title: 'Hit the Road FED', artist: 'TooBitToFail feat. Fr. LeBlanc', url: 'https://plebrap.de/.cm4all/uproc.php/0/Hit-the-Road-FED-Too-Bit-To-Fail-feat.-Fr.-Le-Blanc.mp3?cdp=a&_=18e0e8ccafd'),
  PlebSong(album: 'Pleb2Pleb EP', title: 'Was ist Bitcoin eigentlich', artist: 'JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Was-ist-Bitcoin-eigentlich-JustAnotherNode.mp3?cdp=a&_=18e04ba6ec1'),
  PlebSong(album: 'Pleb2Pleb EP', title: 'Was ist Geld für dich', artist: 'JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Was%20ist%20Geld%20fu%CC%88r%20dich%20-%20JustAnotherNode.mp3?cdp=a&_=191148ce0f4'),
  PlebSong(album: 'Pleb2Pleb EP', title: 'Stack Sats', artist: 'JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/StackSats-JustAnotherNode.mp3?cdp=a&_=18e04c86c51'),
  PlebSong(album: 'Pleb2Pleb EP', title: 'Is Ok', artist: 'JustAnotherNode feat. KidfromtheBlock', url: 'https://plebrap.de/.cm4all/uproc.php/0/Is-Ok-JustAnotherNode-feat.-Kid.mp3?cdp=a&_=18e04dc1c95'),
  PlebSong(album: 'Pleb2Pleb EP', title: 'Dezentral', artist: 'JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Dezentral-JustAnotherNode.mp3?cdp=a&_=18e04dd36a3'),
  PlebSong(album: 'Pleb2Pleb EP', title: 'Inflation', artist: 'JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Inflation-JustAnotherNode_1.mp3?cdp=a&_=18e0e8e87dc'),
  PlebSong(album: 'Pleb2Pleb EP', title: 'Sound Money', artist: 'JustAnotherNode feat. KidfromtheBlock', url: 'https://plebrap.de/.cm4all/uproc.php/0/Sound-Money-JustAnotherNode-Lyrics-by-Kid-from-the-Block.mp3?cdp=a&_=18e0e903402'),
  PlebSong(album: 'Singles', title: 'Plebs together strong', artist: 'TooBitToFail, JustAnotherNode, MoGries', url: 'https://plebrap.de/.cm4all/uproc.php/0/Plebs-together-strong-TooBitToFail-feat.-JustAnotherNode-mixed-by-MoGries.mp3?cdp=a&_=18e0e9c5178'),
  PlebSong(album: 'Singles', title: 'FOMO', artist: 'TooBitToFail, Hanspanzer', url: 'https://plebrap.de/.cm4all/uproc.php/0/FOMO-TooBitToFail-Hanspanzer.mp3?cdp=a&_=18e0ea15b2b'),
  PlebSong(album: 'Singles', title: 'Nutzen Sats', artist: 'JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Nutzen%20Sats.mp3?cdp=a&_=18e0eaf1e63'),
  PlebSong(album: 'Singles', title: 'Fiat unter Feuer', artist: 'TooBitToFail, Hanspanzer', url: 'https://plebrap.de/.cm4all/uproc.php/0/Fiat%20unter%20%20Feuer%20-%20TooBitToFail%20-%20Hanspanzer.mp3?cdp=a&_=18f97d95bb6'),
  PlebSong(album: 'Singles', title: 'Bank gegen Node', artist: 'TooBitToFail, Hanspanzer feat. JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Bank-gegen-Node-TooBitToFail-Hanspanzer-feat.-JustAnotherNode.mp3?cdp=a&_=18e0e996966'),
  PlebSong(album: 'Singles', title: 'Feuer über Fiat', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/Feuer-ueber-Fiat-TooBitToFail.mp3?cdp=a&_=18e0e9e4736'),
  PlebSong(album: 'Singles', title: 'One Bit Wonder', artist: 'TooBitToFail, Hanspanzer', url: 'https://plebrap.de/.cm4all/uproc.php/0/One-Bit-Wonder-TooBitToFail-Hanspanzer.mp3?cdp=a&_=18e0ea0437b'),
  PlebSong(album: 'Singles', title: 'El Presidente', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/El-Presidente-TooBitToFail.mp3?cdp=a&_=18e0eab9876'),
  PlebSong(album: 'Singles', title: 'Moinsen', artist: 'TooBitToFail, JustAnotherNode, Hanspanzer', url: 'https://plebrap.de/.cm4all/uproc.php/0/Moinsen-TooBitToFail-JustAnotherNode-Hanspanzer.mp3?cdp=a&_=18e0ea284b5'),
  PlebSong(album: 'Singles', title: 'Money Printer Go', artist: 'TooBitToFail', url: 'https://plebrap.de/.cm4all/uproc.php/0/Money-Printer-Go-TooBitToFail.mp3?cdp=a&_=18e0eaad93c'),
  PlebSong(album: 'Singles', title: 'Shitstorm', artist: 'TooBitToFail, Hanspanzer feat. Dr.Block', url: 'https://plebrap.de/.cm4all/uproc.php/0/Shitstorm-TooBitToFail-Hanspanzer-feat.-Dr.-Block.mp3?cdp=a&_=18e0e9f42f3'),
  PlebSong(album: 'Singles', title: 'Bitcoin braucht dich nicht', artist: 'SatStacker, MoGries', url: 'https://plebrap.de/.cm4all/uproc.php/0/Bitcoin-braucht-dich-nicht-SatStacker-Mo.mp3?cdp=a&_=18e0eb03831'),
  PlebSong(album: 'Singles', title: 'Hier im Münzweg', artist: 'TooBitToFail, JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Hier-im-Muenzweg-TooBitToFail-JustAnotherNode.mp3?cdp=a&_=18e0e7651b8'),
  PlebSong(album: 'Singles', title: 'Papa hodlt', artist: 'TooBitToFail feat. JustAnotherNode', url: 'https://plebrap.de/.cm4all/uproc.php/0/Papa-Hodlt-TooBitToFail-JustAnotherNode.mp3?cdp=a&_=18e0e9b0261'),
];

class PlebrapAudio {
  PlebrapAudio._();

  static final AudioPlayer player = AudioPlayer();

  /// Index des aktuellen Songs (null = noch nichts gewaehlt).
  static final ValueNotifier<int?> index = ValueNotifier<int?>(null);

  /// true, waehrend ein Song geladen wird.
  static final ValueNotifier<bool> loading = ValueNotifier<bool>(false);

  /// true nach einem Ladefehler des letzten Versuchs (UI zeigt Snackbar).
  static final ValueNotifier<int> loadErrors = ValueNotifier<int>(0);

  static bool _wired = false;

  /// Einmalige Verdrahtung des Auto-Weiter. Idempotent — jeder Einstieg
  /// (Kachel oder Screen) darf das gefahrlos aufrufen.
  static void ensureWired() {
    if (_wired) return;
    _wired = true;
    player.playerStateStream.listen((st) {
      if (st.processingState == ProcessingState.completed) next();
    });
  }

  static PlebSong? get current =>
      index.value != null ? kPlebSongs[index.value!] : null;

  static Future<void> playIndex(int i) async {
    ensureWired();
    index.value = i;
    loading.value = true;
    try {
      await player.setUrl(kPlebSongs[i].url);
      loading.value = false;
      await player.play();
    } catch (e) {
      AppLogger.diag('PlebRap', 'Song laedt nicht (${kPlebSongs[i].title}): ${e.runtimeType}');
      loading.value = false;
      loadErrors.value++; // UI-seitig beobachtbar
    }
  }

  /// Play/Pause — startet Song 0, wenn noch nichts gewaehlt war.
  static Future<void> toggle() async {
    ensureWired();
    if (index.value == null) { await playIndex(0); return; }
    player.playing ? await player.pause() : await player.play();
  }

  static Future<void> next() async {
    final i = index.value;
    if (i != null && i < kPlebSongs.length - 1) await playIndex(i + 1);
  }

  static Future<void> prev() async {
    final i = index.value;
    if (i != null && i > 0) await playIndex(i - 1);
  }
}
