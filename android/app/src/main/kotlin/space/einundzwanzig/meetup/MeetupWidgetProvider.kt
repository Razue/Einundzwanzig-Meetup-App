package space.einundzwanzig.meetup

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
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
            val views = RemoteViews(context.packageName, R.layout.meetup_widget)
            val prefs = HomeWidgetPlugin.getData(context)

            // Bitcoin-/Mempool-Daten (mit Fallbacks, falls noch nichts geladen)
            val block = prefs.getString("block", "––") ?: "––"
            val priceEur = prefs.getString("priceEur", "––") ?: "––"
            val moscow = prefs.getString("moscow", "––:––") ?: "––:––"
            val fees = prefs.getString("fees", "–·–·–") ?: "–·–·–"

            views.setTextViewText(R.id.widget_block, block)
            views.setTextViewText(R.id.widget_price, "$priceEur €")
            views.setTextViewText(R.id.widget_moscow, moscow)
            views.setTextViewText(R.id.widget_fees, fees)

            // Nächstes Meetup
            val meetupCity = prefs.getString("meetupCity", "") ?: ""
            val meetupCountdown = prefs.getString("meetupCountdown", "") ?: ""
            if (meetupCity.isNotEmpty()) {
                views.setTextViewText(R.id.widget_meetup_city, meetupCity)
                views.setTextViewText(R.id.widget_meetup_countdown, meetupCountdown)
            } else {
                views.setTextViewText(R.id.widget_meetup_city, "Kein Home-Meetup")
                views.setTextViewText(R.id.widget_meetup_countdown, "In der App wählen")
            }

            // Tap aufs ganze Widget -> App öffnen
            val launchIntent: PendingIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java
            )
            views.setOnClickPendingIntent(R.id.widget_root, launchIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
