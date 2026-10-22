import 'dart:js' as js;

void speakText(String text, String lang) {
  try {
    js.context.callMethod('travaSpeak', [text, lang]);
  } catch (_) {}
}

void speakBilingual(String enText, String taText) {
  try {
    js.context.callMethod('travaSpeakBilingual', [enText, taText]);
  } catch (_) {}
}

void stopSpeaking() {
  try {
    js.context.callMethod('travaStopSpeech');
  } catch (_) {}
}
