package com.learnen.learn_en

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class TtsSpeakReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: return
        TtsHelper.speak(context, text)
    }

    companion object {
        const val ACTION_SPEAK = "com.learnen.learn_en.action.SPEAK"
        const val EXTRA_TEXT = "speak_text"
    }
}
