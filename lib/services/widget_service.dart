// ============================================
//  Widget-Service — füllt das Android-Homescreen-Widget
// ============================================
//  Schreibt die aktuellen Bitcoin-/Mempool-Daten und das nächste Meetup
//  in den geteilten Speicher, den das native Widget ausliest, und stößt
//  ein Widget-Update an. Wird beim App-Start und beim Aktualisieren der
//  Startseite aufgerufen.
// ============================================

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mempool.dart';
import 'news_service.dart';
import 'app_logger.dart';

class WidgetService {
  static const _tag = 'WidgetService';
  // Muss zum nativen Provider passen:
  static const _androidProvider = 'MeetupWidgetProvider';

  static String _fmtInt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Aktualisiert die Bitcoin-/Mempool-Kennzahlen im Widget.
  static Future<void> updateBitcoin(BitcoinDashboardData d) async {
    try {
      await HomeWidget.saveWidgetData<String>(
          'block', d.blockHeight > 0 ? _fmtInt(d.blockHeight) : '––');
      await HomeWidget.saveWidgetData<String>(
          'priceEur', d.priceEur > 0 ? _fmtInt(d.priceEur.round()) : '––');
      await HomeWidget.saveWidgetData<String>('moscow', d.moscowTime);
      await HomeWidget.saveWidgetData<String>(
          'fees', '${d.feeLow}·${d.feeMedium}·${d.feeHigh}');
      await HomeWidget.updateWidget(name: _androidProvider, androidName: _androidProvider);
    } catch (e) {
      AppLogger.debug(_tag, 'Bitcoin-Widget-Update fehlgeschlagen: $e');
    }
  }

  /// Aktualisiert das nächste Meetup im Widget.
  /// [city] leer -> Widget zeigt "Kein Home-Meetup".
  static Future<void> updateMeetup({required String city, required String countdown}) async {
    try {
      await HomeWidget.saveWidgetData<String>('meetupCity', city);
      await HomeWidget.saveWidgetData<String>('meetupCountdown', countdown);
      await HomeWidget.updateWidget(name: _androidProvider, androidName: _androidProvider);
    } catch (e) {
      AppLogger.debug(_tag, 'Meetup-Widget-Update fehlgeschlagen: $e');
    }
  }

  /// Bequemer Sammel-Aufruf: holt frische Bitcoin-Daten und schreibt sie.
  static Future<void> refreshBitcoin() async {
    try {
      final d = await MempoolService.getDashboardData();
      await updateBitcoin(d);
    } catch (e) {
      AppLogger.debug(_tag, 'refreshBitcoin fehlgeschlagen: $e');
    }
  }

  static const _kLastSeenNewsId = 'widget_last_seen_news_id';
  static const _kLatestNewsId = 'widget_latest_news_id';
  static const _kLatestNewsTitle = 'widget_latest_news_title';

  /// Prüft den neuesten Artikel und markiert das Widget mit "NEU", wenn er
  /// noch nicht gesehen wurde. Schreibt Titel + Neu-Status ins Widget.
  static Future<void> refreshNews() async {
    try {
      final articles = await NewsService.fetchArticles(limit: 1);
      if (articles.isEmpty) return;
      final latest = articles.first;
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(_kLastSeenNewsId) ?? '';
      final isNew = latest.id.isNotEmpty && latest.id != lastSeen;

      await prefs.setString(_kLatestNewsId, latest.id);
      await prefs.setString(_kLatestNewsTitle, latest.title);

      await HomeWidget.saveWidgetData<String>('newsTitle',
          latest.title.isNotEmpty ? latest.title : 'News');
      await HomeWidget.saveWidgetData<bool>('newsIsNew', isNew);
      await HomeWidget.updateWidget(name: _androidProvider, androidName: _androidProvider);
    } catch (e) {
      AppLogger.debug(_tag, 'refreshNews fehlgeschlagen: $e');
    }
  }

  /// Markiert den neuesten Artikel als gesehen -> "NEU"-Markierung im Widget
  /// verschwindet. Beim Öffnen der News-Sektion aufrufen.
  static Future<void> markNewsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latest = prefs.getString(_kLatestNewsId) ?? '';
      if (latest.isNotEmpty) {
        await prefs.setString(_kLastSeenNewsId, latest);
      }
      await HomeWidget.saveWidgetData<bool>('newsIsNew', false);
      await HomeWidget.updateWidget(name: _androidProvider, androidName: _androidProvider);
    } catch (e) {
      AppLogger.debug(_tag, 'markNewsSeen fehlgeschlagen: $e');
    }
  }
}
