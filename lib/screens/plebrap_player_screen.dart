// ============================================
// PLEBRAP PLAYER — Bitcoin-Rap aus der Community
// ============================================
// Streamt die frei veroeffentlichten Songs von plebrap.de (TooBitToFail,
// JustAnotherNode, Hanspanzer u.a.). Titelliste kuratiert und fest
// eingebettet — die Seite ist ein Baukasten ohne API. Neue Songs = Liste
// hier ergaenzen. Cover kommen von plebrap.de, mit Icon-Fallback.
//
// V4V: Der ⚡-Knopf oeffnet die Value-for-Value-Seite der Kuenstler.
// TODO: Sobald deren Lightning-Adresse bestaetigt ist, auf einen direkten
// lightning:-Link umstellen (bewusst NICHT geraten).
//
// Wiedergabe laeuft, solange die App lebt; echte Hintergrund-Wiedergabe
// mit Notification ist Stufe 2 (just_audio_background + Manifest).
// ============================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/app_logger.dart';

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

class PlebrapPlayerScreen extends StatefulWidget {
  const PlebrapPlayerScreen({super.key});
  @override
  State<PlebrapPlayerScreen> createState() => _PlebrapPlayerScreenState();
}

class _PlebrapPlayerScreenState extends State<PlebrapPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  int? _index;
  bool _loading = false;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _stateSub = _player.playerStateStream.listen((st) {
      if (st.processingState == ProcessingState.completed) _next();
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playIndex(int i) async {
    setState(() { _index = i; _loading = true; });
    try {
      await _player.setUrl(kPlebSongs[i].url);
      if (!mounted) return;
      setState(() => _loading = false);
      await _player.play();
    } catch (e) {
      AppLogger.diag('PlebRap', 'Song laedt nicht (${kPlebSongs[i].title}): ${e.runtimeType}');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).prLoadError),
        backgroundColor: cRed, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _next() { if (_index != null && _index! < kPlebSongs.length - 1) _playIndex(_index! + 1); }
  void _prev() { if (_index != null && _index! > 0) _playIndex(_index! - 1); }

  Future<void> _openV4V() async {
    try { await launchUrl(Uri.parse('https://plebrap.de/V4V/'), mode: LaunchMode.externalApplication); } catch (_) {}
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _coverBox(PlebSong? s, double size) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: s == null
            ? Container(width: size, height: size, color: cOrange.withValues(alpha: 0.12),
                child: const Icon(Icons.graphic_eq_rounded, color: cOrange, size: 24))
            : Image.network(s.cover, width: size, height: size, fit: BoxFit.cover,
                errorBuilder: (_, e, st) => Container(width: size, height: size,
                    color: cOrange.withValues(alpha: 0.12),
                    child: const Icon(Icons.graphic_eq_rounded, color: cOrange, size: 24))),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final song = _index != null ? kPlebSongs[_index!] : null;

    final albums = <String, List<int>>{};
    for (var i = 0; i < kPlebSongs.length; i++) {
      albums.putIfAbsent(kPlebSongs[i].album, () => []).add(i);
    }

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: const Text('PlebRap', style: TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          TextButton.icon(
            onPressed: _openV4V,
            icon: const Icon(Icons.bolt_rounded, color: cOrange, size: 18),
            label: Text(t.prV4V, style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(children: [
        // ============ NOW PLAYING (Cover als Wasserzeichen, App-Stil) ============
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(kTileRadius + 2),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kTileRadius + 2),
            child: Stack(children: [
              if (song != null)
                Positioned(right: -20, bottom: -30,
                  child: Opacity(opacity: 0.10,
                    child: Image.network(song.cover, width: 180, height: 180, fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => const SizedBox.shrink()))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    _coverBox(song, 52),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(song?.title ?? t.prPickSong,
                          style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(song?.artist ?? 'Plebs together strong',
                          style: const TextStyle(color: cTextSecondary, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                  const SizedBox(height: 10),
                  StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (_, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final total = _player.duration ?? Duration.zero;
                      final max = total.inMilliseconds.toDouble();
                      return Column(children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            activeTrackColor: cOrange, inactiveTrackColor: cSurface, thumbColor: cOrange,
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          child: Slider(
                            value: max > 0 ? pos.inMilliseconds.clamp(0, total.inMilliseconds).toDouble() : 0,
                            max: max > 0 ? max : 1,
                            onChanged: max > 0 ? (v) => _player.seek(Duration(milliseconds: v.round())) : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(_fmt(pos), style: const TextStyle(color: cTextTertiary, fontSize: 11).copyWith(fontFamily: fontMono)),
                            Text(_fmt(total), style: const TextStyle(color: cTextTertiary, fontSize: 11).copyWith(fontFamily: fontMono)),
                          ]),
                        ),
                      ]);
                    },
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, color: cText, size: 30),
                        onPressed: _index != null && _index! > 0 ? _prev : null),
                    const SizedBox(width: 8),
                    StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (_, snap) {
                        final playing = snap.data?.playing ?? false;
                        return GestureDetector(
                          onTap: () {
                            if (_index == null) { _playIndex(0); return; }
                            playing ? _player.pause() : _player.play();
                          },
                          child: Container(
                            width: 54, height: 54,
                            decoration: const BoxDecoration(color: cOrange, shape: BoxShape.circle),
                            child: _loading
                                ? const Padding(padding: EdgeInsets.all(15),
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                                : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 32),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, color: cText, size: 30),
                        onPressed: _index != null && _index! < kPlebSongs.length - 1 ? _next : null),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        // ============ TITELLISTE ============
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final entry in albums.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                child: Row(children: [
                  const Icon(Icons.album_rounded, color: cOrange, size: 15),
                  const SizedBox(width: 7),
                  Text(entry.key.toUpperCase(),
                      style: const TextStyle(color: cOrange, fontSize: 11.5, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 0.5, color: cTileBorder)),
                ]),
              ),
              for (final i in entry.value) _songRow(i),
            ],
          ],
        )),
      ]),
    );
  }

  Widget _songRow(int i) {
    final s = kPlebSongs[i];
    final active = i == _index;
    return GestureDetector(
      onTap: () => _playIndex(i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? cOrange.withValues(alpha: 0.10) : cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: active ? cOrange.withValues(alpha: 0.5) : cTileBorder, width: active ? 1 : 0.5),
        ),
        child: Row(children: [
          Icon(active ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
              color: active ? cOrange : cTextTertiary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: TextStyle(color: active ? cOrange : cText, fontSize: 13.5, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 1),
            Text(s.artist, style: const TextStyle(color: cTextTertiary, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}
