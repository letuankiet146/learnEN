package com.learnen.learn_en

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "showSentenceReminder" -> {
                    val id = call.argument<Int>("id")
                    val text = call.argument<String>("text")
                    if (id == null || text.isNullOrBlank()) {
                        result.error("invalid_args", "Missing notification args", null)
                        return@setMethodCallHandler
                    }
                    LearnEnNotificationHelper.show(this, id, text)
                    result.success(null)
                }
                "setTtsGender" -> {
                    val gender = call.argument<String>("gender")
                    TtsHelper.setGender(this, gender)
                    result.success(null)
                }
                "resolveVoiceForGender" -> {
                    val gender = call.argument<String>("gender")
                    TtsHelper.ensureEngineForFlutter(this) {
                        val resolved = TtsHelper.resolveVoiceForGenderSync(gender)
                        result.success(resolved)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleSpeakIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSpeakIntent(intent)
    }

    private fun handleSpeakIntent(intent: Intent?) {
        val text = intent?.getStringExtra(TtsSpeakReceiver.EXTRA_TEXT) ?: return
        TtsHelper.speak(this, text)
    }

    companion object {
        const val NOTIFICATION_CHANNEL = "com.learnen.learn_en/notifications"
    }
}
