import 'package:flutter/foundation.dart';
import 'language_service.dart';
import 'voice_service_stub.dart'
    if (dart.library.js) 'voice_service_web.dart'
    if (dart.library.io) 'voice_service_mobile.dart' as platform_voice;

enum VoiceAnnouncementLanguage {
  both,
  english,
  tamil,
}

class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  bool _isSpeaking = false;
  String _lastSpokenEnglish = '';
  String _lastSpokenTamil = '';
  VoiceAnnouncementLanguage _selectedLang = VoiceAnnouncementLanguage.both;

  bool get isSpeaking => _isSpeaking;
  String get lastSpokenEnglish => _lastSpokenEnglish;
  String get lastSpokenTamil => _lastSpokenTamil;
  VoiceAnnouncementLanguage get selectedLang => _selectedLang;

  void setLanguagePreference(VoiceAnnouncementLanguage lang) {
    _selectedLang = lang;
    notifyListeners();
  }

  /// Map of common Coimbatore destinations & stops in Tamil for speech
  static const Map<String, String> _tamilStops = {
    'Gandhipuram': 'காந்திபுரம்',
    'Singanallur': 'சிங்காநல்லூர்',
    'Ukkadam': 'உக்கடம்',
    'Peelamedu': 'பீளமேடு',
    'Fun Mall Area': 'ஃபன் மால்',
    'Fun Mall': 'ஃபன் மால்',
    'Fun Republic Mall': 'ஃபன் மால்',
    'Nava India': 'நவ இந்தியா',
    'Lakshmi Mills': 'லட்சுமி மில்ஸ்',
    'Railway Station': 'ரயில் நிலையம்',
    'Collectorate': 'கலெக்டரேட்',
    'Town Hall': 'டவுன் ஹால்',
    'Saravanampatti': 'சரவணம்பட்டி',
    'CHIL SEZ': 'சில் செஸ்',
    'Ganapathy': 'கணபதி',
    'Prozone Mall': 'புரோசோன் மால்',
    'Ramanathapuram': 'ராமநாதபுரம்',
    'Sungam': 'சுங்கம்',
    'Valankulam Lake': 'வாலாங்குளம்',
    'RS Puram': 'ஆர்.எஸ். புரம்',
    'Lawley Road': 'லாலி ரோடு',
    'TNAU': 'வேளாண் பல்கலைக்கழகம்',
    'Vadavalli': 'வடவள்ளி',
    'Marudhamalai': 'மருதமலை',
    'Thondamuthur': 'தொண்டாமுத்தூர்',
    'Eachanari': 'ஈச்சனாரி',
    'Ondipudur': 'ஒண்டிப்புதூர்',
    'Sulur': 'சூலூர்',
    'Hope College': 'ஹோப் காலேஜ்',
    'Hopes College': 'ஹோப்ஸ் காலேஜ்',
    'Sitra': 'சிட்ரா',
    'Airport': 'விமான நிலையம்',
    'Kovaipudur': 'கோவைப்புதூர்',
    'Sundarapuram': 'சுந்தராபுரம்',
    'Kinathukadavu': 'கிணத்துக்கடவு',
    'Pollachi': 'பொள்ளாச்சி',
    'Mettupalayam': 'மேட்டுப்பாளையம்',
    'Thudiyalur': 'துடியலூர்',
    'Periyanaickenpalayam': 'பெரியநாயக்கன்பாளையம்',
    'Annur': 'அன்னூர்',
    'Saibaba Colony': 'சாயிபாபா காலனி',
    'Cross Cut Road': 'கிராஸ் கட் ரோடு',
    '100 Feet Road': 'நூறு அடி ரோடு',
  };

  String getTamilStopName(String stop) {
    for (final entry in _tamilStops.entries) {
      if (stop.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(stop.toLowerCase())) {
        return entry.value;
      }
    }
    return LanguageService().translateStop(stop);
  }

  String _cleanBusNumber(String raw) {
    String cleaned = raw
        .replaceAll('TNSTC', '')
        .replaceAll('City Express', '')
        .replaceAll('—', '')
        .replaceAll('-', ' ')
        .trim();
    if (cleaned.isEmpty) cleaned = 'City Express';
    return cleaned;
  }

  /// Announces the accurate ETA, pickup stop, and destination of the selected bus
  void announceBusArrival({
    required String busNumber,
    required String destinationStop,
    required int etaMinutes,
    String? pickupStop,
    String? currentStop,
    VoiceAnnouncementLanguage? languageOverride,
  }) {
    final lang = languageOverride ?? _selectedLang;
    final cleanBus = _cleanBusNumber(busNumber);
    final taDest = getTamilStopName(destinationStop);
    final targetPickup = (pickupStop != null && pickupStop.trim().isNotEmpty)
        ? pickupStop.trim()
        : (currentStop != null && currentStop.trim().isNotEmpty ? currentStop.trim() : null);

    final bool hasPickup = targetPickup != null &&
        targetPickup.toLowerCase() != destinationStop.toLowerCase();

    String enText;
    String taText;

    if (hasPickup) {
      final taPickup = getTamilStopName(targetPickup);
      if (etaMinutes <= 1) {
        enText = 'Attention passengers. Bus $cleanBus towards $destinationStop is arriving now at $targetPickup.';
        taText = 'பயணிகள் கவனத்திற்கு. $taDest செல்லும் பேருந்து $cleanBus, $taPickup-க்கு இப்போது வந்து கொண்டிருக்கிறது.';
      } else {
        enText = 'Attention passengers. Bus $cleanBus towards $destinationStop will arrive at $targetPickup in $etaMinutes minutes.';
        taText = 'பயணிகள் கவனத்திற்கு. $taDest செல்லும் பேருந்து $cleanBus, $taPickup-க்கு இன்னும் $etaMinutes நிமிடங்களில் வந்து சேரும்.';
      }
    } else {
      if (etaMinutes <= 1) {
        enText = 'Attention passengers. Bus $cleanBus to $destinationStop is arriving now at your stop.';
        taText = 'பயணிகள் கவனத்திற்கு. $taDest செல்லும் பேருந்து $cleanBus இப்போது வந்து கொண்டிருக்கிறது.';
      } else {
        enText = 'Attention passengers. Bus $cleanBus to $destinationStop will arrive in $etaMinutes minutes.';
        taText = 'பயணிகள் கவனத்திற்கு. $taDest செல்லும் பேருந்து $cleanBus இன்னும் $etaMinutes நிமிடங்களில் வந்து சேரும்.';
      }
    }

    _lastSpokenEnglish = enText;
    _lastSpokenTamil = taText;
    _isSpeaking = true;
    notifyListeners();

    if (lang == VoiceAnnouncementLanguage.both) {
      platform_voice.speakBilingual(enText, taText);
    } else if (lang == VoiceAnnouncementLanguage.tamil) {
      platform_voice.speakText(taText, 'ta-IN');
    } else {
      platform_voice.speakText(enText, 'en-IN');
    }

    // Auto reset speaking state indicator after announcement finishes
    final durationSec = (lang == VoiceAnnouncementLanguage.both) ? 10 : 6;
    Future.delayed(Duration(seconds: durationSec), () {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  void stop() {
    _isSpeaking = false;
    platform_voice.stopSpeaking();
    notifyListeners();
  }
}
