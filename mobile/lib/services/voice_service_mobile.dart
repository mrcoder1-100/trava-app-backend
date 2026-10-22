import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.trava.trava/voice');

void speakText(String text, String lang) async {
  try {
    await _channel.invokeMethod('speakText', {
      'text': text,
      'lang': lang,
    });
  } catch (_) {}
}

void speakBilingual(String enText, String taText) async {
  try {
    await _channel.invokeMethod('speakBilingual', {
      'enText': enText,
      'taText': taText,
    });
  } catch (_) {}
}

void stopSpeaking() async {
  try {
    await _channel.invokeMethod('stopSpeaking');
  } catch (_) {}
}
