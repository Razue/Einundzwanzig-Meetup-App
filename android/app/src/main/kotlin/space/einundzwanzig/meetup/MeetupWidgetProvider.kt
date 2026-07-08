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

                if (meetupCity.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_meetup_city, meetupCity)
                    views.setTextViewText(R.id.widget_meetup_countdown, meetupCountdown)
                } else {
                    views.setTextViewText(R.id.widget_meetup_city, "Kein Home-Meetup")
                    views.setTextViewText(R.id.widget_meetup_countdown, "In der App wählen")
                }

                // Tap aufs Widget -> App öffnen. Intent selbst bauen (NICHT
                // HomeWidgetLaunchIntent), da dessen Flags auf Android 14+/MIUI
                // crashen. FLAG_IMMUTABLE ist ab Android 12 Pflicht.
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, piFlags)
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                // Niemals das Widget komplett scheitern lassen.
                android.util.Log.e("MeetupWidget", "onUpdate failed: ${e.message}", e)
            }
        }
    }
}
