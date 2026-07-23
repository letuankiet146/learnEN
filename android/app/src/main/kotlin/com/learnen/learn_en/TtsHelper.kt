package com.learnen.learn_en

import android.content.Context
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.Voice
import java.util.Locale
import java.util.UUID

object TtsHelper {
    private const val PREFS_NAME = "learn_en_prefs"
    private const val KEY_VOICE_GENDER = "tts_voice_gender"

    private var appContext: Context? = null
    private var textToSpeech: TextToSpeech? = null
    private var ready = false
    private val pendingTexts = mutableListOf<String>()
    private val pendingReadyCallbacks = mutableListOf<() -> Unit>()

    fun setGender(context: Context, gender: String?) {
        appContext = context.applicationContext
        prefs(context).edit().apply {
            if (gender.isNullOrBlank()) {
                remove(KEY_VOICE_GENDER)
            } else {
                putString(KEY_VOICE_GENDER, gender)
            }
        }.apply()
        ensureEngine(context) {
            applyStoredVoiceSettings()
        }
    }

    fun ensureEngineForFlutter(context: Context, onReady: () -> Unit) {
        ensureEngine(context, onReady)
    }

    fun resolveVoiceForGenderSync(gender: String?): Map<String, String>? {
        if (!ready || textToSpeech == null) {
            return null
        }

        val voice = pickVoiceForGender(gender) ?: return null
        return mapOf(
            "name" to voice.name,
            "locale" to voice.locale.toLanguageTag(),
        )
    }

    fun speak(context: Context, text: String) {
        appContext = context.applicationContext
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return

        ensureEngine(context) {
            if (ready) {
                speakNow(trimmed)
            } else {
                pendingTexts.add(trimmed)
            }
        }
    }

    private fun ensureEngine(context: Context, onReady: () -> Unit) {
        appContext = context.applicationContext

        if (ready && textToSpeech != null) {
            onReady()
            return
        }

        pendingReadyCallbacks.add(onReady)

        if (textToSpeech != null) {
            return
        }

        textToSpeech = TextToSpeech(appContext) { status ->
            ready = status == TextToSpeech.SUCCESS
            if (ready) {
                textToSpeech?.setSpeechRate(0.45f)
                applyStoredVoiceSettings()
                flushPending()
            }

            val callbacks = pendingReadyCallbacks.toList()
            pendingReadyCallbacks.clear()
            callbacks.forEach { it() }
        }
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private fun applyStoredVoiceSettings() {
        val context = appContext ?: return
        val engine = textToSpeech ?: return
        if (!ready) return

        val gender = prefs(context).getString(KEY_VOICE_GENDER, null)
        val selectedVoice = pickVoiceForGender(gender)
        if (selectedVoice != null) {
            engine.voice = selectedVoice
        } else {
            engine.language = Locale.US
        }
    }

    private fun pickVoiceForGender(gender: String?): Voice? {
        val voices = englishVoices()
        if (gender.isNullOrBlank()) {
            return null
        }

        return voices.firstOrNull { detectGender(it) == gender }
            ?: voices.firstOrNull()
    }

    private fun englishVoices(): List<Voice> {
        return textToSpeech?.voices
            ?.filter { it.locale.language.equals("en", ignoreCase = true) }
            ?.sortedWith(
                compareBy<Voice>(
                    { if (it.locale.toLanguageTag().startsWith("en-US")) 0 else 1 },
                    { it.name },
                ),
            )
            ?: emptyList()
    }

    private fun detectGender(voice: Voice): String? {
        val features = voice.features ?: emptySet()
        if (features.any { it.equals("female", ignoreCase = true) }) {
            return "female"
        }
        if (features.any { it.equals("male", ignoreCase = true) }) {
            return "male"
        }

        val name = voice.name.lowercase(Locale.US)
        return when {
            name.contains("female") -> "female"
            name.contains("male") -> "male"
            name.contains("-sfg") || name.contains("-gba") || name.contains("-iob") -> "female"
            name.contains("-iom") || name.contains("-iol") || name.contains("-sma") -> "male"
            else -> null
        }
    }

    private fun flushPending() {
        val texts = pendingTexts.toList()
        pendingTexts.clear()
        texts.forEach(::speakNow)
    }

    private fun speakNow(text: String) {
        val utteranceId = UUID.randomUUID().toString()
        val params = Bundle()
        textToSpeech?.speak(
            text,
            TextToSpeech.QUEUE_FLUSH,
            params,
            utteranceId,
        )
    }

    fun shutdown() {
        textToSpeech?.shutdown()
        textToSpeech = null
        ready = false
        pendingTexts.clear()
        pendingReadyCallbacks.clear()
    }
}
