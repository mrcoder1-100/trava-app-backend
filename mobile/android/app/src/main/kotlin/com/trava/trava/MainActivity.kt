package com.trava.trava

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.URLEncoder
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val CHANNEL = "com.trava.trava/voice"
    private var tts: TextToSpeech? = null
    private var isTtsReady = false
    private var mediaPlayer: MediaPlayer? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            tts = TextToSpeech(applicationContext, this)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "speakText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val lang = call.argument<String>("lang") ?: "en-US"
                    speakSingle(text, lang)
                    result.success(true)
                }
                "speakBilingual" -> {
                    val enText = call.argument<String>("enText") ?: ""
                    val taText = call.argument<String>("taText") ?: ""
                    speakBilingual(enText, taText)
                    result.success(true)
                }
                "stopSpeaking" -> {
                    stopAll()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            isTtsReady = true
        }
    }

    private fun speakSingle(text: String, lang: String) {
        stopAll()
        if (text.isBlank()) return
        val langCode = if (lang.startsWith("ta", ignoreCase = true)) "ta" else "en"
        playAudioOrTts(text, langCode, null)
    }

    private fun speakBilingual(enText: String, taText: String) {
        stopAll()
        if (enText.isBlank() && taText.isBlank()) return

        if (enText.isNotBlank()) {
            playAudioOrTts(enText, "en") {
                if (taText.isNotBlank()) {
                    mainHandler.postDelayed({
                        playAudioOrTts(taText, "ta", null)
                    }, 400)
                }
            }
        } else {
            playAudioOrTts(taText, "ta", null)
        }
    }

    private fun playAudioOrTts(text: String, langCode: String, onDone: (() -> Unit)?) {
        try {
            val encoded = URLEncoder.encode(text.trim(), "UTF-8")
            val url = "https://translate.google.com/translate_tts?ie=UTF-8&tl=$langCode&client=tw-ob&q=$encoded"

            stopMediaPlayer()

            val mp = MediaPlayer()
            mediaPlayer = mp
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                    .build()
            )

            val headers = mapOf("User-Agent" to "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
            mp.setDataSource(applicationContext, Uri.parse(url), headers)

            mp.setOnPreparedListener {
                if (mediaPlayer === mp) {
                    mp.start()
                }
            }

            mp.setOnCompletionListener {
                if (mediaPlayer === mp) {
                    stopMediaPlayer()
                    onDone?.invoke()
                }
            }

            mp.setOnErrorListener { _, _, _ ->
                if (mediaPlayer === mp) {
                    stopMediaPlayer()
                    speakWithTtsFallback(text, langCode, onDone)
                }
                true
            }

            mp.prepareAsync()
        } catch (e: Exception) {
            stopMediaPlayer()
            speakWithTtsFallback(text, langCode, onDone)
        }
    }

    private fun speakWithTtsFallback(text: String, langCode: String, onDone: (() -> Unit)?) {
        val engine = tts
        if (engine != null && isTtsReady) {
            try {
                val locale = if (langCode == "ta") Locale("ta", "IN") else Locale.US
                val avail = engine.isLanguageAvailable(locale)
                if (avail >= TextToSpeech.LANG_AVAILABLE) {
                    engine.language = locale
                } else {
                    engine.language = Locale.US
                }

                val utteranceId = "utt_${System.currentTimeMillis()}"
                engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(id: String?) {}
                    override fun onDone(id: String?) {
                        if (id == utteranceId) {
                            mainHandler.post { onDone?.invoke() }
                        }
                    }
                    override fun onError(id: String?) {
                        if (id == utteranceId) {
                            mainHandler.post { onDone?.invoke() }
                        }
                    }
                })

                engine.speak(text, TextToSpeech.QUEUE_FLUSH, null, utteranceId)
            } catch (e: Exception) {
                onDone?.invoke()
            }
        } else {
            onDone?.invoke()
        }
    }

    private fun stopMediaPlayer() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.reset()
                it.release()
            }
        } catch (_: Exception) {}
        mediaPlayer = null
    }

    private fun stopAll() {
        stopMediaPlayer()
        try {
            tts?.stop()
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        stopAll()
        try {
            tts?.shutdown()
        } catch (_: Exception) {}
        tts = null
        super.onDestroy()
    }
}
