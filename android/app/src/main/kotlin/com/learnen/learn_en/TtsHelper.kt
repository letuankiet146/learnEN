package com.learnen.learn_en

import android.content.Context
import android.os.Bundle
import android.speech.tts.TextToSpeech
import java.util.Locale
import java.util.UUID

object TtsHelper {
    private var textToSpeech: TextToSpeech? = null
    private var ready = false
    private val pendingTexts = mutableListOf<String>()

    fun speak(context: Context, text: String) {
        val appContext = context.applicationContext
        val trimmed = text.trim()
        if (trimmed.isEmpty()) return

        if (textToSpeech == null) {
            textToSpeech = TextToSpeech(appContext) { status ->
                ready = status == TextToSpeech.SUCCESS
                if (ready) {
                    textToSpeech?.language = Locale.US
                    textToSpeech?.setSpeechRate(0.45f)
                    flushPending()
                }
            }
            pendingTexts.add(trimmed)
            return
        }

        if (ready) {
            speakNow(trimmed)
        } else {
            pendingTexts.add(trimmed)
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
    }
}
