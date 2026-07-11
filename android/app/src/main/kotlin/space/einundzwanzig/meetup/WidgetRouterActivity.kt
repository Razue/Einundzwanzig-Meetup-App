package space.einundzwanzig.meetup

import android.app.Activity
import android.content.Intent
import android.os.Bundle

// ============================================
// Widget-Klick-Router
// ============================================
//
// Unsichtbare Mini-Activity, die bei JEDEM Widget-Tap FRISCH erzeugt
// wird. Dadurch ist ihr Intent garantiert der des angetippten Bereichs:
// - kein Task-Recycling (noHistory + excludeFromRecents im Manifest),
// - kein Intent-Replay durch MIUI (die Haupt-Activity bekommt beim
//   Wiederöffnen aus dem Task-Speicher sonst den ALTEN Intent erneut —
//   das war die Ursache, warum die Widget-Bereiche nicht routeten).
//
// Ablauf: Ziel aus dem eigenen (frischen) Intent lesen -> in
// SharedPreferences schreiben -> App starten -> sich selbst beenden.
// Die Dart-Seite fragt das Ziel bei jedem Aufwachen ab.
// ============================================

class WidgetRouterActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val target = intent?.data?.host ?: intent?.getStringExtra("open")
            if (!target.isNullOrEmpty() && target != "home") {
                // commit() statt apply(): synchron geschrieben, bevor die
                // App startet — deterministisch.
                getSharedPreferences("e21_widget", MODE_PRIVATE)
                    .edit().putString("pending_target", target).commit()
            }
        } catch (_: Exception) { /* im Zweifel App einfach öffnen */ }

        startActivity(Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        })
        finish()
    }
}
