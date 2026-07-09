package space.einundzwanzig.meetup

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Homescreen-Widget "21Meetup":
 * Zeigt oben die wichtigsten Bitcoin-/Mempool-Daten (Blockhöhe, Preis,
 * Moscow Time, Fees) und darunter das nächste Meetup mit Countdown.
 * Tippen öffnet die App. Die Daten kommen aus dem geteilten Speicher,
 * den die Flutter-App über home_widget füllt.
 */
class MeetupWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.meetup_widget)

                // Daten lesen — falls das Plugin noch nie lief, mit Fallbacks.
                var block = "––"; var priceEur = "––"; var moscow = "––:––"; var fees = "–·–·–"
                var meetupCity = ""; var meetupCountdown = ""
                try {
                    val prefs = HomeWidgetPlugin.getData(context)
                    block = prefs.getString("block", "––") ?: "––"
                    priceEur = prefs.getString("priceEur", "––") ?: "––"
                    moscow = prefs.getString("moscow", "––:––") ?: "––:––"
                    fees = prefs.getString("fees", "–·–·–") ?: "–·–·–"
                    meetupCity = prefs.getString("meetupCity", "") ?: ""
                    meetupCountdown = prefs.getString("meetupCountdown", "") ?: ""
                } catch (_: Exception) { /* Fallback-Werte behalten */ }

                views.setTextViewText(R.id.widget_block, block)
                views.setTextViewText(R.id.widget_price, "$priceEur €")
                views.setTextViewText(R.id.widget_moscow, moscow)
                views.setTextViewText(R.id.widget_fees, fees)

                // Erweiterte Kennzahlen (Hashrate, Supply, Difficulty)
                try {
                    val prefs = HomeWidgetPlugin.getData(context)
                    views.setTextViewText(R.id.widget_hashrate, prefs.getString("hashrate", "––") ?: "––")
                    views.setTextViewText(R.id.widget_supply, prefs.getString("supply", "––") ?: "––")
                    views.setTextViewText(R.id.widget_difficulty, prefs.getString("difficulty", "––") ?: "––")
                    val upd = prefs.getString("updated", "") ?: ""
                    views.setTextViewText(R.id.widget_updated, if (upd.isEmpty()) "" else "Stand $upd")
                } catch (_: Exception) {}

                if (meetupCity.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_meetup_city, meetupCity)
                    views.setTextViewText(R.id.widget_meetup_countdown, meetupCountdown)
                } else {
                    views.setTextViewText(R.id.widget_meetup_city, "Kein Home-Meetup")
                    views.setTextViewText(R.id.widget_meetup_countdown, "In der App wählen")
                }

                // News: Titel + NEU-Markierung
                var newsTitle = "Aktuelle Artikel"
                var newsIsNew = false
                try {
                    val prefs = HomeWidgetPlugin.getData(context)
                    newsTitle = prefs.getString("newsTitle", "Aktuelle Artikel") ?: "Aktuelle Artikel"
                    newsIsNew = prefs.getBoolean("newsIsNew", false)
                } catch (_: Exception) {}
                views.setTextViewText(R.id.widget_news_title, newsTitle)
                views.setViewVisibility(
                    R.id.widget_news_new,
                    if (newsIsNew) android.view.View.VISIBLE else android.view.View.GONE
                )

                val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

                // WICHTIG: Die Intents MÜSSEN die home_widget-LAUNCH-Action und
                // eine data-URI tragen — nur dann liefert das Plugin auf der
                // Dart-Seite (initiallyLaunchedFromHomeWidget/widgetClicked)
                // die URI und das Routing greift. Eigene Actions/Extras werden
                // vom Plugin ignoriert (das war der Fehler bisher).
                fun openIntent(target: String, requestCode: Int): PendingIntent {
                    val i = Intent(context, MainActivity::class.java).apply {
                        action = "es.antonborri.home_widget.action.LAUNCH"
                        data = android.net.Uri.parse("homewidget://$target")
                        putExtra("open", target)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    return PendingIntent.getActivity(context, requestCode, i, piFlags)
                }

                // Drei getrennte Klickbereiche -> jeweils eigenes Ziel in der App.
                views.setOnClickPendingIntent(R.id.widget_btc_area, openIntent("bitcoin", 2))
                views.setOnClickPendingIntent(R.id.widget_meetup_area, openIntent("meetup", 3))
                views.setOnClickPendingIntent(R.id.widget_news_row, openIntent("news", 1))

                // Logo oben = "App normal öffnen".
                views.setOnClickPendingIntent(R.id.widget_logo, openIntent("home", 0))

                // Aktualisieren-Rädchen: führt Dart-Code im HINTERGRUND aus
                // (holt frische Daten, ohne die App zu öffnen).
                try {
                    val refreshPi = es.antonborri.home_widget.HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        android.net.Uri.parse("homewidget://refresh")
                    )
                    views.setOnClickPendingIntent(R.id.widget_refresh, refreshPi)
                } catch (_: Exception) { /* Refresh-Button dann ohne Funktion, Widget lebt weiter */ }

                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                // Niemals das Widget komplett scheitern lassen.
                android.util.Log.e("MeetupWidget", "onUpdate failed: ${e.message}", e)
            }
        }
    }
}
