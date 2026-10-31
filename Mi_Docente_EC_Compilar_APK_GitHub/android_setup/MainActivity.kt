package ec.midocente.mi_docente_ec

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** Receives text shared through Android's standard share sheet (ACTION_SEND).
 * Does NOT read WhatsApp chats automatically. */
class MainActivity : FlutterActivity() {
    private var sharedText: String? = null
    private var shareChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sharedText = extractText(intent)
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ec.midocente/share")
        shareChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "takeSharedText" -> {
                    val text = sharedText
                    sharedText = null
                    result.success(text)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractText(intent)?.let { text ->
            shareChannel?.invokeMethod("sharedText", text)
                ?: run { sharedText = text }
        }
    }

    private fun extractText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { it.isNotBlank() }
    }
}
