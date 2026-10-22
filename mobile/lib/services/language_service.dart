import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported regional languages in the exact priority order requested:
/// 1. Tamil (தமிழ்)
/// 2. English (English)
/// 3. Hindi (हिन्दी)
enum AppLanguage {
  tamil,
  english,
  hindi,
}

extension AppLanguageExtension on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.tamil:
        return 'ta';
      case AppLanguage.english:
        return 'en';
      case AppLanguage.hindi:
        return 'hi';
    }
  }

  String get nativeName {
    switch (this) {
      case AppLanguage.tamil:
        return 'தமிழ்';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.hindi:
        return 'हिन्दी';
    }
  }

  String get englishName {
    switch (this) {
      case AppLanguage.tamil:
        return 'Tamil';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.hindi:
        return 'Hindi';
    }
  }

  String get displayName {
    switch (this) {
      case AppLanguage.tamil:
        return 'தமிழ் (Tamil)';
      case AppLanguage.english:
        return 'English (English)';
      case AppLanguage.hindi:
        return 'हिन्दी (Hindi)';
    }
  }

  String get iconLabel {
    switch (this) {
      case AppLanguage.tamil:
        return 'தமிழ்';
      case AppLanguage.english:
        return 'EN';
      case AppLanguage.hindi:
        return 'हिन्दी';
    }
  }

  String get flag {
    switch (this) {
      case AppLanguage.tamil:
        return '🇮🇳';
      case AppLanguage.english:
        return '🌐';
      case AppLanguage.hindi:
        return '🇮🇳';
    }
  }

  String get scriptSample {
    switch (this) {
      case AppLanguage.tamil:
        return 'வணக்கம்';
      case AppLanguage.english:
        return 'Welcome';
      case AppLanguage.hindi:
        return 'नमस्ते';
    }
  }
}

class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _prefKey = 'trava_selected_language';

  final ValueNotifier<AppLanguage> currentLanguageNotifier =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  AppLanguage get currentLanguage => currentLanguageNotifier.value;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        if (savedCode == 'ta') {
          currentLanguageNotifier.value = AppLanguage.tamil;
        } else if (savedCode == 'hi') {
          currentLanguageNotifier.value = AppLanguage.hindi;
        } else {
          currentLanguageNotifier.value = AppLanguage.english;
        }
      }
    } catch (_) {
      // Fallback gracefully
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    currentLanguageNotifier.value = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language.code);
    } catch (_) {
      // Ignored if storage is unavailable
    }
  }

  static final Map<String, String> _humanFallbacks = {
    'guaranteed_reward_card_title': 'Interactive Scratch Card',
    'guaranteed_card_desc': 'Guaranteed reward coupon revealed upon reaching points goal.',
    'scratch_card_locked': 'Scratch Card Locked',
    'unlock_instructions_prefix': 'Earn points by sharing your bus journey GPS.',
    'partner_categories_header': 'Partner Categories',
    'total_community_balance': 'TOTAL BALANCE',
    'guaranteed_rewards_badge': 'GUARANTEED REWARDS',
    'ready_to_scratch_badge': 'READY TO SCRATCH',
    'all_partners': 'All Deals',
    'cat_bakeries': 'Bakery',
    'cat_restaurants': 'Restaurant',
    'cat_supermarkets': 'Supermarket',
    'cat_gym': 'Fitness',
    'partner_portal_header': 'Trava Merchant Partner Network',
    'partner_portal_desc': 'Redeem vouchers at verified local Coimbatore merchants.',
    'your_coupons_header': 'Available Coupons',
    'deals_suffix': 'Deals',
    'points_ledger_title': 'Community Activity Ledger',
    'swipe_to_scratch': 'Swipe across card to scratch & reveal!',
    'code_prefix': 'CODE:',
    'already_used_badge': 'USED',
    'active_badge': 'ACTIVE',
  };

  String tr(String key) {
    final lang = currentLanguage;
    final dict = _translations[key];
    if (dict != null) {
      final val = dict[lang] ?? dict[AppLanguage.english];
      if (val != null) return val;
    }
    return _humanFallbacks[key] ?? key.replaceAll('_', ' ');
  }

  /// Translates Coimbatore Bus Stops to chosen language
  String translateStop(String stopName) {
    if (currentLanguage == AppLanguage.english) return stopName;
    return _stopsTranslations[stopName]?[currentLanguage] ?? stopName;
  }

  /// Translates Coimbatore Route Titles to chosen language
  String translateRoute(String routeName) {
    if (currentLanguage == AppLanguage.english) return routeName;
    return _routeTranslations[routeName]?[currentLanguage] ?? routeName;
  }

  /// Translates Bus Service Name
  String translateBus(String busName) {
    if (currentLanguage == AppLanguage.english) return busName;
    return _busTranslations[busName]?[currentLanguage] ?? busName;
  }

  /// Translates Coimbatore Popular Corridor Chips
  String translateCorridorLabel(String label) {
    if (currentLanguage == AppLanguage.english) return label;
    return _corridorTranslations[label]?[currentLanguage] ?? label;
  }

  static const Map<String, Map<AppLanguage, String>> _corridorTranslations = {
    'Route 95 · Peelamedu': {
      AppLanguage.tamil: 'வழித்தடம் 95 · பீளமேடு',
      AppLanguage.hindi: 'मार्ग 95 · पीलमेडू',
    },
    'Route 111 · Railway Stn': {
      AppLanguage.tamil: 'வழித்தடம் 111 · ரயில் நிலையம்',
      AppLanguage.hindi: 'मार्ग 111 · रेलवे स्टेशन',
    },
    'Route 20C · IT Corridor': {
      AppLanguage.tamil: 'வழித்தடம் 20C · ஐடி காரிடார்',
      AppLanguage.hindi: 'मार्ग 20C · आईटी कॉरिडोर',
    },
    'Route 70 · Sungam Ring': {
      AppLanguage.tamil: 'வழித்தடம் 70 · சுங்கம் ரிங்',
      AppLanguage.hindi: 'मार्ग 70 · सुंगम रिंग',
    },
    'Route 10A · RS Puram': {
      AppLanguage.tamil: 'வழித்தடம் 10A · ஆர்.எஸ். புரம்',
      AppLanguage.hindi: 'मार्ग 10A · आर.एस. पुरम',
    },
  };

  static const Map<String, Map<AppLanguage, String>> _routeTranslations = {
    'Gandhipuram ↔ Singanallur (via Peelamedu)': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ சிங்காநல்லூர் (பீளமேடு வழியாக)',
      AppLanguage.hindi: 'गांधीपुरम ↔ सिंगानल्लूर (पीलमेडू होकर)',
    },
    'Gandhipuram ↔ Singanallur': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ சிங்காநல்லூர்',
      AppLanguage.hindi: 'गांधीपुरम ↔ सिंगानल्लूर',
    },
    'Gandhipuram ↔ Ukkadam (via Railway Station)': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ உக்கடம் (ரயில் நிலையம் வழியாக)',
      AppLanguage.hindi: 'गांधीपुरम ↔ उक्कड़म (रेलवे स्टेशन होकर)',
    },
    'Gandhipuram ↔ Ukkadam': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ உக்கடம்',
      AppLanguage.hindi: 'गांधीपुरम ↔ उक्कड़म',
    },
    'Gandhipuram ↔ Saravanampatti (via Ganapathy)': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ சரவணம்பட்டி (கணபதி வழியாக)',
      AppLanguage.hindi: 'गांधीपुरम ↔ सरवणमपट्टी (गणपति होकर)',
    },
    'Gandhipuram ↔ Saravanampatti (IT Corridor)': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ சரவணம்பட்டி (ஐடி காரிடார்)',
      AppLanguage.hindi: 'गांधीपुरम ↔ सरवणमपट्टी (आईटी कॉरिडोर)',
    },
    'Gandhipuram ↔ Saravanampatti': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ சரவணம்பட்டி',
      AppLanguage.hindi: 'गांधीपुरम ↔ सरवणमपट्टी',
    },
    'Singanallur ↔ Ukkadam (via Sungam)': {
      AppLanguage.tamil: 'சிங்காநல்லூர் ↔ உக்கடம் (சுங்கம் வழியாக)',
      AppLanguage.hindi: 'सिंगानल्लूर ↔ उक्कड़म (सुंगम होकर)',
    },
    'Singanallur ↔ Ukkadam': {
      AppLanguage.tamil: 'சிங்காநல்லூர் ↔ உக்கடம்',
      AppLanguage.hindi: 'सिंगानल्लूर ↔ उक्कड़म',
    },
    'Gandhipuram ↔ Vadavalli (via RS Puram)': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ வடவள்ளி (ஆர்.எஸ். புரம் வழியாக)',
      AppLanguage.hindi: 'गांधीपुरम ↔ वदवल्ली (आर.एस. पुरम होकर)',
    },
    'Gandhipuram ↔ Vadavalli': {
      AppLanguage.tamil: 'காந்திபுரம் ↔ வடவள்ளி',
      AppLanguage.hindi: 'गांधीपुरम ↔ वदवल्ली',
    },
    'Ukkadam ↔ Vadavalli (via Town Hall & RS Puram)': {
      AppLanguage.tamil: 'உக்கடம் ↔ வடவள்ளி (டவுன் ஹால் & ஆர்.எஸ். புரம் வழியாக)',
      AppLanguage.hindi: 'उक्कड़म ↔ वदवल्ली (टाउन हॉल और आर.एस. पुरम होकर)',
    },
  };

  static const Map<String, Map<AppLanguage, String>> _stopsTranslations = {
    'Gandhipuram': {
      AppLanguage.tamil: 'காந்திபுரம்',
      AppLanguage.hindi: 'गांधीपुरम',
    },
    'Gandhipuram Central Bus Stand': {
      AppLanguage.tamil: 'காந்திபுரம் மத்திய பேருந்து நிலையம்',
      AppLanguage.hindi: 'गांधीपुरम सेंट्रल बस स्टैंड',
    },
    'Lakshmi Mills': {
      AppLanguage.tamil: 'லட்சுமி மில்ஸ்',
      AppLanguage.hindi: 'लक्ष्मी मिल्स',
    },
    'Lakshmi Mills Junction': {
      AppLanguage.tamil: 'லட்சுமி மில்ஸ் சந்திப்பு',
      AppLanguage.hindi: 'लक्ष्मी मिल्स जंक्शन',
    },
    'Lakshmi': {
      AppLanguage.tamil: 'லட்சுமி',
      AppLanguage.hindi: 'लक्ष्मी',
    },
    'Nava India': {
      AppLanguage.tamil: 'நவ இந்தியா',
      AppLanguage.hindi: 'नवा इंडिया',
    },
    'Nava India Signal': {
      AppLanguage.tamil: 'நவ இந்தியா சிக்னல்',
      AppLanguage.hindi: 'नवा इंडिया सिग्नल',
    },
    'Nava': {
      AppLanguage.tamil: 'நவ',
      AppLanguage.hindi: 'नवा',
    },
    'Peelamedu': {
      AppLanguage.tamil: 'பீளமேடு',
      AppLanguage.hindi: 'पीलमेडू',
    },
    'Peelamedu Bus Stop': {
      AppLanguage.tamil: 'பீளமேடு பேருந்து நிறுத்தம்',
      AppLanguage.hindi: 'पीलमेडू बस स्टॉप',
    },
    'Peelamedu Bus Stand': {
      AppLanguage.tamil: 'பீளமேடு பேருந்து நிலையம்',
      AppLanguage.hindi: 'पीलमेडू बस स्टैंड',
    },
    'Fun Republic Mall Area': {
      AppLanguage.tamil: 'ஃபன் ரிபப்ளிக் மால் பகுதி',
      AppLanguage.hindi: 'फन रिपब्लिक मॉल क्षेत्र',
    },
    'Fun Mall Area': {
      AppLanguage.tamil: 'ஃபன் மால் பகுதி',
      AppLanguage.hindi: 'फन मॉल क्षेत्र',
    },
    'Fun Mall': {
      AppLanguage.tamil: 'ஃபன் மால்',
      AppLanguage.hindi: 'फन मॉल',
    },
    'Fun': {
      AppLanguage.tamil: 'ஃபன்',
      AppLanguage.hindi: 'फन',
    },
    'Singanallur': {
      AppLanguage.tamil: 'சிங்காநல்லூர்',
      AppLanguage.hindi: 'सिंगानल्लूर',
    },
    'Singanallur Bus Terminus': {
      AppLanguage.tamil: 'சிங்காநல்லூர் பேருந்து நிலையம்',
      AppLanguage.hindi: 'सिंगानल्लूर बस टर्मिनल',
    },
    'Railway Station': {
      AppLanguage.tamil: 'ரயில் நிலையம்',
      AppLanguage.hindi: 'रेलवे स्टेशन',
    },
    'Coimbatore Junction Railway Station': {
      AppLanguage.tamil: 'கோவை சந்திப்பு ரயில் நிலையம்',
      AppLanguage.hindi: 'कोयंबटूर जंक्शन रेलवे स्टेशन',
    },
    'Railway': {
      AppLanguage.tamil: 'ரயில்வே',
      AppLanguage.hindi: 'रेलवे',
    },
    'Collectorate': {
      AppLanguage.tamil: 'ஆட்சியர் அலுவலகம்',
      AppLanguage.hindi: 'कलेक्ट्रेट',
    },
    'Collectorate / District Court': {
      AppLanguage.tamil: 'ஆட்சியர் அலுவலகம் / மாவட்ட நீதிமன்றம்',
      AppLanguage.hindi: 'कलेक्ट्रेट / जिला न्यायालय',
    },
    'Town Hall': {
      AppLanguage.tamil: 'டவுன் ஹால்',
      AppLanguage.hindi: 'टाउन हॉल',
    },
    'Town Hall / Mani Koodu': {
      AppLanguage.tamil: 'டவுன் ஹால் / மணிக்கூண்டு',
      AppLanguage.hindi: 'टाउन हॉल / मणि कूडु',
    },
    'Town': {
      AppLanguage.tamil: 'டவுன்',
      AppLanguage.hindi: 'टाउन',
    },
    'Ukkadam': {
      AppLanguage.tamil: 'உக்கடம்',
      AppLanguage.hindi: 'उक्कड़म',
    },
    'Ukkadam Bus Terminus': {
      AppLanguage.tamil: 'உக்கடம் பேருந்து நிலையம்',
      AppLanguage.hindi: 'उक्कड़म बस टर्मिनल',
    },
    'Ganapathy': {
      AppLanguage.tamil: 'கணபதி',
      AppLanguage.hindi: 'गणपति',
    },
    'Ganapathy Bus Stop': {
      AppLanguage.tamil: 'கணபதி பேருந்து நிறுத்தம்',
      AppLanguage.hindi: 'गणपति बस स्टॉप',
    },
    'Prozone Mall': {
      AppLanguage.tamil: 'புரோசோன் மால்',
      AppLanguage.hindi: 'प्रोज़ोन मॉल',
    },
    'Prozone Mall / Sivanandapuram': {
      AppLanguage.tamil: 'புரோசோன் மால் / சிவானந்தபுரம்',
      AppLanguage.hindi: 'प्रोज़ोन मॉल / शिवानंदपुरम',
    },
    'CHIL SEZ': {
      AppLanguage.tamil: 'சில் செஸ்',
      AppLanguage.hindi: 'चिल सेज़',
    },
    'CHIL SEZ / KCT Tech Park': {
      AppLanguage.tamil: 'சில் செஸ் / கேசிடி டெக் பார்க்',
      AppLanguage.hindi: 'चिल सेज़ / केसीटी टेक पार्क',
    },
    'Saravanampatti': {
      AppLanguage.tamil: 'சரவணம்பட்டி',
      AppLanguage.hindi: 'सरवणमपट्टी',
    },
    'Saravanampatti Junction': {
      AppLanguage.tamil: 'சரவணம்பட்டி சந்திப்பு',
      AppLanguage.hindi: 'सरवणमपट्टी जंक्शन',
    },
    'Ramanathapuram': {
      AppLanguage.tamil: 'ராமநாதபுரம்',
      AppLanguage.hindi: 'रामनाथपुरम',
    },
    'Ramanathapuram Signal': {
      AppLanguage.tamil: 'ராமநாதபுரம் சிக்னல்',
      AppLanguage.hindi: 'रामनाथपुरम सिग्नल',
    },
    'Sungam': {
      AppLanguage.tamil: 'சுங்கம்',
      AppLanguage.hindi: 'सुंगम',
    },
    'Sungam Junction': {
      AppLanguage.tamil: 'சுங்கம் சந்திப்பு',
      AppLanguage.hindi: 'सुंगम जंक्शन',
    },
    'Valankulam Lake': {
      AppLanguage.tamil: 'வாலாங்குளம் ஏரி',
      AppLanguage.hindi: 'वालनकुलम झील',
    },
    'Valankulam Lake Promenade': {
      AppLanguage.tamil: 'வாலாங்குளம் ஏரி நடைபாதை',
      AppLanguage.hindi: 'वालनकुलम झील प्रोमेनेड',
    },
    'RS Puram': {
      AppLanguage.tamil: 'ஆர்.எஸ். புரம்',
      AppLanguage.hindi: 'आर.एस. पुरम',
    },
    'DB Road RS Puram': {
      AppLanguage.tamil: 'டி.பி. சாலை ஆர்.எஸ். புரம்',
      AppLanguage.hindi: 'डीबी रोड आर.एस. पुरम',
    },
    'Lawley Road': {
      AppLanguage.tamil: 'லாலி சாலை',
      AppLanguage.hindi: 'लॉली रोड',
    },
    'Lawley Road Junction': {
      AppLanguage.tamil: 'லாலி சாலை சந்திப்பு',
      AppLanguage.hindi: 'लॉली रोड जंक्शन',
    },
    'TNAU': {
      AppLanguage.tamil: 'டி.என்.ஏ.யு',
      AppLanguage.hindi: 'टीएनएयू',
    },
    'TNAU Agricultural University': {
      AppLanguage.tamil: 'டி.என்.ஏ.யு வேளாண்மைப் பல்கலைக்கழகம்',
      AppLanguage.hindi: 'टीएनएयू कृषि विश्वविद्यालय',
    },
    'Vadavalli': {
      AppLanguage.tamil: 'வடவள்ளி',
      AppLanguage.hindi: 'वदवल्ली',
    },
    'Vadavalli Bus Stand': {
      AppLanguage.tamil: 'வடவள்ளி பேருந்து நிலையம்',
      AppLanguage.hindi: 'वदवल्ली बस स्टैंड',
    },
    'Coimbatore': {
      AppLanguage.tamil: 'கோயம்புத்தூர்',
      AppLanguage.hindi: 'कोयंबटूर',
    },
  };

  static const Map<String, Map<AppLanguage, String>> _busTranslations = {
    'TNSTC — Green Express': {
      AppLanguage.tamil: 'TNSTC — கிரீன் எக்ஸ்பிரஸ்',
      AppLanguage.hindi: 'TNSTC — ग्रीन एक्सप्रेस',
    },
    'TNSTC Green Express': {
      AppLanguage.tamil: 'TNSTC கிரீன் எக்ஸ்பிரஸ்',
      AppLanguage.hindi: 'TNSTC ग्रीन एक्सप्रेस',
    },
    'Kovai Transports — City Star': {
      AppLanguage.tamil: 'கோவை டிரான்ஸ்போர்ட்ஸ் — சிட்டி ஸ்டார்',
      AppLanguage.hindi: 'कोवई ट्रांसपोर्ट्स — सिटी स्टार',
    },
    'Kovai Transports City Star': {
      AppLanguage.tamil: 'கோவை டிரான்ஸ்போர்ட்ஸ் சிட்டி ஸ்டார்',
      AppLanguage.hindi: 'कोवई ट्रांसपोर्ट्स सिटी स्टार',
    },
    'TNSTC — Deluxe Rider': {
      AppLanguage.tamil: 'TNSTC — டீலக்ஸ் ரைடர்',
      AppLanguage.hindi: 'TNSTC — डीलक्स राइडर',
    },
    'TNSTC Deluxe Rider': {
      AppLanguage.tamil: 'TNSTC டீலக்ஸ் ரைடர்',
      AppLanguage.hindi: 'TNSTC डीलक्स राइडर',
    },
    'G.V. Travels — Royal Flyer': {
      AppLanguage.tamil: 'ஜி.வி. டிராவல்ஸ் — ராயல் ஃப்ளையர்',
      AppLanguage.hindi: 'जी.वी. ट्रेवल्स — रॉयल फ़्लायर',
    },
    'G.V. Travels Royal Flyer': {
      AppLanguage.tamil: 'ஜி.வி. டிராவல்ஸ் ராயல் ஃப்ளையர்',
      AppLanguage.hindi: 'जी.वी. ट्रेवल्स रॉयल फ़्लायर',
    },
    'TNSTC — Town Shuttle': {
      AppLanguage.tamil: 'TNSTC — டவுன் ஷட்டில்',
      AppLanguage.hindi: 'TNSTC — टाउन शटल',
    },
    'TNSTC Town Shuttle': {
      AppLanguage.tamil: 'TNSTC டவுன் ஷட்டில்',
      AppLanguage.hindi: 'TNSTC टाउन शटल',
    },
    'Sri Murugan — Express Liner': {
      AppLanguage.tamil: 'ஸ்ரீ முருகன் — எக்ஸ்பிரஸ் லைனர்',
      AppLanguage.hindi: 'श्री मुरुगन — एक्सप्रेस लाइनर',
    },
    'Sri Murugan Express Liner': {
      AppLanguage.tamil: 'ஸ்ரீ முருகன் எக்ஸ்பிரஸ் லைனர்',
      AppLanguage.hindi: 'श्री मुरुगन एक्सप्रेस लाइनर',
    },
    'Rathinam — IT Express': {
      AppLanguage.tamil: 'ரத்தினம் — ஐடி எக்ஸ்பிரஸ்',
      AppLanguage.hindi: 'रत्नम — आईटी एक्सप्रेस',
    },
    'Rathinam IT Express': {
      AppLanguage.tamil: 'ரத்தினம் ஐடி எக்ஸ்பிரஸ்',
      AppLanguage.hindi: 'रत्नम आईटी एक्सप्रेस',
    },
    'TNSTC — Tech Flyer': {
      AppLanguage.tamil: 'TNSTC — டெக் ஃப்ளையர்',
      AppLanguage.hindi: 'TNSTC — टेक फ़्लायर',
    },
    'TNSTC Tech Flyer': {
      AppLanguage.tamil: 'TNSTC டெக் ஃப்ளையர்',
      AppLanguage.hindi: 'TNSTC टेक फ़्लायर',
    },
    'TNSTC — Ring Road Service': {
      AppLanguage.tamil: 'TNSTC — ரிங் ரோடு சேவை',
      AppLanguage.hindi: 'TNSTC — रिंग रोड सर्विस',
    },
    'TNSTC Ring Road Service': {
      AppLanguage.tamil: 'TNSTC ரிங் ரோடு சேவை',
      AppLanguage.hindi: 'TNSTC रिंग रोड सर्विस',
    },
    'SBR Transports — Fast Track': {
      AppLanguage.tamil: 'எஸ்.பி.ஆர் டிரான்ஸ்போர்ட்ஸ் — ஃபாஸ்ட் ட்ராக்',
      AppLanguage.hindi: 'एसबीआर ट्रांसपोर्ट्स — फास्ट ट्रैक',
    },
    'SBR Transports Fast Track': {
      AppLanguage.tamil: 'எஸ்.பி.ஆர் டிரான்ஸ்போர்ட்ஸ் ஃபாஸ்ட் ட்ராக்',
      AppLanguage.hindi: 'एसबीआर ट्रांसपोर्ट्स फास्ट ट्रैक',
    },
    'TNSTC — Marudhamalai Coach': {
      AppLanguage.tamil: 'TNSTC — மருதமலை கோச்',
      AppLanguage.hindi: 'TNSTC — मरुधमलई कोच',
    },
    'TNSTC Marudhamalai Coach': {
      AppLanguage.tamil: 'TNSTC மருதமலை கோச்',
      AppLanguage.hindi: 'TNSTC मरुधमलई कोच',
    },
    'City Star — Metro Deluxe': {
      AppLanguage.tamil: 'சிட்டி ஸ்டார் — மெட்ரோ டீலக்ஸ்',
      AppLanguage.hindi: 'सिटी स्टार — मेट्रो डीलक्स',
    },
    'City Star Metro Deluxe': {
      AppLanguage.tamil: 'சிட்டி ஸ்டார் மெட்ரோ டீலக்ஸ்',
      AppLanguage.hindi: 'सिटी स्टार मेट्रो डीलक्स',
    },
    'Cheran City Mover': {
      AppLanguage.tamil: 'சேரன் சிட்டி மூவர்',
      AppLanguage.hindi: 'चेरन सिटी मूवर',
    },
    'Kovai Deluxe Rapid': {
      AppLanguage.tamil: 'கோவை டீலக்ஸ் ரேபிட்',
      AppLanguage.hindi: 'कोवई डीलक्स रैपिड',
    },
    'Marutham Semi-Low Floor': {
      AppLanguage.tamil: 'மருதம் செமி-லோ ஃப்ளோர்',
      AppLanguage.hindi: 'मरुधम सेमी-लो फ्लोर',
    },
  };

  static const Map<String, Map<AppLanguage, String>> _translations = {
    // App Bar & Global
    'app_name': {
      AppLanguage.tamil: 'Trava',
      AppLanguage.english: 'Trava',
      AppLanguage.hindi: 'Trava',
    },
    'tagline': {
      AppLanguage.tamil: 'சமூகத்தால் இயங்கும் நிகழ்நேர பொதுப் போக்குவரத்து',
      AppLanguage.english: 'Community Powered Public Transit',
      AppLanguage.hindi: 'समुदाय संचालित सार्वजनिक पारगमन',
    },
    'city_coimbatore': {
      AppLanguage.tamil: 'கோயம்புத்தூர், தமிழ்நாடு',
      AppLanguage.english: 'Coimbatore, Tamil Nadu',
      AppLanguage.hindi: 'कोयंबटूर, तमिलनाडु',
    },
    'city_label': {
      AppLanguage.tamil: 'நகரம்',
      AppLanguage.english: 'City',
      AppLanguage.hindi: 'शहर',
    },

    // Navigation Tabs
    'nav_home': {
      AppLanguage.tamil: 'முகப்பு',
      AppLanguage.english: 'Home',
      AppLanguage.hindi: 'होम',
    },
    'nav_track_bus': {
      AppLanguage.tamil: 'பேருந்து வரைபடம்',
      AppLanguage.english: 'Track Bus',
      AppLanguage.hindi: 'बस ट्रैक',
    },
    'nav_share_gps': {
      AppLanguage.tamil: 'GPS பகிர்வு',
      AppLanguage.english: 'Share GPS',
      AppLanguage.hindi: 'जीपीएस शेयर',
    },
    'nav_features': {
      AppLanguage.tamil: 'அம்சங்கள்',
      AppLanguage.english: 'Features',
      AppLanguage.hindi: 'सुविधाएं',
    },
    'nav_rewards': {
      AppLanguage.tamil: 'சன்மானங்கள்',
      AppLanguage.english: 'Rewards',
      AppLanguage.hindi: 'रिवार्ड्स',
    },
    'rewards_spotlight_sub': {
      AppLanguage.tamil: 'புள்ளிகளை மீட்டு பேக்கரி & கூட்டாளர் சலுகைகளைப் பெறுங்கள்',
      AppLanguage.english: 'Redeem points for bakery & partner discount coupons',
      AppLanguage.hindi: 'बेकरी और पार्टनर डिस्काउंट कूपन के लिए अंक भुनाएं',
    },
    'nav_profile': {
      AppLanguage.tamil: 'சுயவிவரம்',
      AppLanguage.english: 'Profile',
      AppLanguage.hindi: 'प्रोफ़ाइल',
    },

    // Language Selector UI
    'select_language': {
      AppLanguage.tamil: 'மொழியைத் தேர்ந்தெடுக்கவும்',
      AppLanguage.english: 'Select Language',
      AppLanguage.hindi: 'भाषा चुनें',
    },
    'regional_languages': {
      AppLanguage.tamil: 'பிராந்திய மொழிகள் (3 மொழிகள்)',
      AppLanguage.english: 'Regional Languages (3 Languages)',
      AppLanguage.hindi: 'क्षेत्रीय भाषाएं (3 भाषाएं)',
    },
    'regional_languages_sub': {
      AppLanguage.tamil: 'தமிழ், English மற்றும் हिन्दी இடையே எப்போது வேண்டுமானாலும் மாறலாம்',
      AppLanguage.english: 'Easily switch between Tamil, English, and Hindi anytime',
      AppLanguage.hindi: 'तमिल, अंग्रेजी और हिंदी के बीच कभी भी आसानी से बदलें',
    },
    'change_language': {
      AppLanguage.tamil: 'மொழியை மாற்றவும்',
      AppLanguage.english: 'Change Language',
      AppLanguage.hindi: 'भाषा बदलें',
    },
    'language_changed_toast': {
      AppLanguage.tamil: 'மொழி தமிழுக்கு மாற்றப்பட்டது',
      AppLanguage.english: 'Language switched to English',
      AppLanguage.hindi: 'भाषा हिंदी में बदल दी गई है',
    },

    // Home Tab
    'greeting_vanakkam': {
      AppLanguage.tamil: 'வணக்கம்',
      AppLanguage.english: 'Vanakkam',
      AppLanguage.hindi: 'नमस्ते',
    },
    'simulation_active_online': {
      AppLanguage.tamil: 'Trava உருவகப்படுத்துதல் செயலில் உள்ளது · நேரலை ஒத்திசைவு ஆன்லைன்',
      AppLanguage.english: 'Trava Simulation Active · Authoritative Sync Online',
      AppLanguage.hindi: 'Trava सिमुलेशन सक्रिय · आधिकारिक सिंक ऑनलाइन है',
    },
    'offline_mode_banner': {
      AppLanguage.tamil: 'ஆஃப்லைன் முறை · இருப்பிடப் பதிவுகள் உள்நாட்டில் வரிசைப்படுத்தப்படும்',
      AppLanguage.english: 'Offline Mode · Contributions will queue locally',
      AppLanguage.hindi: 'ऑफलाइन मोड · योगदान स्थानीय रूप से कतारबद्ध होंगे',
    },
    'badge_demo': {
      AppLanguage.tamil: 'டெமோ',
      AppLanguage.english: 'DEMO',
      AppLanguage.hindi: 'डेमो',
    },
    'badge_demo_mode': {
      AppLanguage.tamil: 'டெமோ முறை',
      AppLanguage.english: 'DEMO MODE',
      AppLanguage.hindi: 'डेमो मोड',
    },
    'badge_new': {
      AppLanguage.tamil: 'புதியது',
      AppLanguage.english: 'NEW',
      AppLanguage.hindi: 'नया',
    },
    'badge_stops': {
      AppLanguage.tamil: 'நிறுத்தங்கள்',
      AppLanguage.english: 'STOPS',
      AppLanguage.hindi: 'स्टॉप',
    },
    'pts': {
      AppLanguage.tamil: 'புள்ளிகள்',
      AppLanguage.english: 'pts',
      AppLanguage.hindi: 'अंक',
    },
    'community_points': {
      AppLanguage.tamil: 'சமூகப் புள்ளிகள்',
      AppLanguage.english: 'Community Points',
      AppLanguage.hindi: 'सामुदायिक अंक',
    },
    'track_bus_card_sub': {
      AppLanguage.tamil: 'பேருந்து நிறுத்தத்தில் பயணி: நேரலை பேருந்து & வருகை நேரத்தைக் காண்க',
      AppLanguage.english: 'Passenger at bus stop: See live bus & dynamic ETA',
      AppLanguage.hindi: 'बस स्टॉप पर यात्री: लाइव बस और गतिशील ईटीए देखें',
    },
    'share_gps_card_sub': {
      AppLanguage.tamil: 'பேருந்தில் பயணி: இருப்பிடத்தைப் பகிர்ந்து +50 புள்ளிகள் பெறுங்கள்',
      AppLanguage.english: 'Passenger on bus: Share location & earn +50 pts',
      AppLanguage.hindi: 'बस में यात्री: लोकेशन शेयर करें और +50 अंक अर्जित करें',
    },
    'features_spotlight_sub': {
      AppLanguage.tamil: '🔥 டார்ச் பகிர்வு & 📡 ஆஃப்லைன் ஜிபிஎஸ் பகிர்வு',
      AppLanguage.english: '🔥 Pass the Torch & 📡 Offline GPS Sharing',
      AppLanguage.hindi: '🔥 टॉर्च पास & 📡 ऑफलाइन जीपीएस शेयरिंग',
    },
    'featured_demo_route': {
      AppLanguage.tamil: 'சிறப்பு டெமோ வழித்தடங்கள்',
      AppLanguage.english: 'Featured Demo Route',
      AppLanguage.hindi: 'विशेष डेमो मार्ग',
    },
    'view_all': {
      AppLanguage.tamil: 'அனைத்தையும் காண்க',
      AppLanguage.english: 'View All',
      AppLanguage.hindi: 'सभी देखें',
    },
    'search_routes': {
      AppLanguage.tamil: 'பேருந்து அல்லது வழித்தடத்தைத் தேடுங்கள்...',
      AppLanguage.english: 'Search buses, routes or stops...',
      AppLanguage.hindi: 'बस या मार्ग संख्या खोजें...',
    },
    'active_transit_routes': {
      AppLanguage.tamil: 'செயலில் உள்ள பேருந்து வழித்தடங்கள்',
      AppLanguage.english: 'Active Transit Routes',
      AppLanguage.hindi: 'सक्रिय बस मार्ग',
    },
    'verified_live': {
      AppLanguage.tamil: 'நேரலை சரிபார்க்கப்பட்டது',
      AppLanguage.english: 'Verified Live',
      AppLanguage.hindi: 'सत्यापित लाइव',
    },
    'active_buses_live': {
      AppLanguage.tamil: 'நேரலை பேருந்துகள்',
      AppLanguage.english: 'Active Buses Live',
      AppLanguage.hindi: 'सक्रिय बसें लाइव',
    },

    // Track Bus Screen
    'transit_corridors_title': {
      AppLanguage.tamil: 'கோயம்புத்தூர் போக்குவரத்து வழித்தடம்',
      AppLanguage.english: 'Coimbatore Transit Corridor',
      AppLanguage.hindi: 'कोयंबटूर पारगमन गलियारा',
    },
    'where_boarding': {
      AppLanguage.tamil: 'நீங்கள் எங்கு ஏறுகிறீர்கள்?',
      AppLanguage.english: 'Where are you boarding?',
      AppLanguage.hindi: 'आप कहाँ से चढ़ रहे हैं?',
    },
    'where_destination': {
      AppLanguage.tamil: 'நீங்கள் எங்கு செல்ல வேண்டும்?',
      AppLanguage.english: 'Where do you want to go?',
      AppLanguage.hindi: 'आप कहाँ जाना चाहते हैं?',
    },
    'search_routes_btn': {
      AppLanguage.tamil: 'வழித்தடங்கள் & நேரலை பேருந்துகளைத் தேடுங்கள்',
      AppLanguage.english: 'Search Routes & Live Buses',
      AppLanguage.hindi: 'मार्ग और लाइव बसें खोजें',
    },
    'popular_corridors': {
      AppLanguage.tamil: 'பிரபலமான வழித்தடங்கள்',
      AppLanguage.english: 'Popular Transit Corridors',
      AppLanguage.hindi: 'लोकप्रिय पारगमन गलियारे',
    },
    'matching_routes': {
      AppLanguage.tamil: 'பொருந்தும் பேருந்து வழித்தடங்கள்',
      AppLanguage.english: 'Matching Transit Routes',
      AppLanguage.hindi: 'मिलते-जुलते बस मार्ग',
    },
    'next_bus': {
      AppLanguage.tamil: 'அடுத்த பேருந்து',
      AppLanguage.english: 'Next Bus',
      AppLanguage.hindi: 'अगली बस',
    },
    'mins_away': {
      AppLanguage.tamil: 'நிமிடங்களில் வரும்',
      AppLanguage.english: 'mins away',
      AppLanguage.hindi: 'मिनट दूर',
    },
    'crowd_level': {
      AppLanguage.tamil: 'கூட்ட நெரிசல்',
      AppLanguage.english: 'Crowd Level',
      AppLanguage.hindi: 'भीड़ का स्तर',
    },
    'track_on_map': {
      AppLanguage.tamil: 'நேரலை வரைபடத்தில் காண்க ➔',
      AppLanguage.english: 'Track on Live Map ➔',
      AppLanguage.hindi: 'लाइव मैप पर ट्रैक करें ➔',
    },
    'no_routes_found': {
      AppLanguage.tamil: 'தேர்ந்தெடுக்கப்பட்ட நிறுத்தங்களுக்கு இடையே நேரடி வழித்தடம் கிடைக்கவில்லை',
      AppLanguage.english: 'No direct routes found between selected stops',
      AppLanguage.hindi: 'चयनित स्टॉप के बीच कोई सीधा मार्ग नहीं मिला',
    },

    // Features Tab
    'features_title': {
      AppLanguage.tamil: 'Trava சிறப்பம்சங்கள்',
      AppLanguage.english: 'Trava Features',
      AppLanguage.hindi: 'Trava सुविधाएं',
    },
    'pass_the_torch': {
      AppLanguage.tamil: '🔥 டார்ச் பகிர்வு',
      AppLanguage.english: '🔥 Pass the Torch',
      AppLanguage.hindi: '🔥 टॉर्च पास करें',
    },
    'pass_the_torch_title': {
      AppLanguage.tamil: 'டார்ச் பகிர்வு',
      AppLanguage.english: 'Pass the Torch',
      AppLanguage.hindi: 'टॉर्च पास करें',
    },
    'offline_gps': {
      AppLanguage.tamil: '📡 ஆஃப்லைன் GPS',
      AppLanguage.english: '📡 Offline GPS',
      AppLanguage.hindi: '📡 ऑफलाइन जीपीएस',
    },
    'regular_checks': {
      AppLanguage.tamil: '⏱️ வழக்கமான சோதனைகள்',
      AppLanguage.english: '⏱️ Regular Checks',
      AppLanguage.hindi: '⏱️ नियमित जांच',
    },
    'configure_journey': {
      AppLanguage.tamil: 'உங்கள் பயணத்தை திட்டமிடுங்கள்',
      AppLanguage.english: 'CONFIGURE YOUR JOURNEY',
      AppLanguage.hindi: 'अपनी यात्रा सेट करें',
    },
    'transit_route': {
      AppLanguage.tamil: 'பேருந்து வழித்தடம்',
      AppLanguage.english: 'Transit Route',
      AppLanguage.hindi: 'बस मार्ग',
    },
    'which_bus': {
      AppLanguage.tamil: 'நீங்கள் எந்த பேருந்தில் பயணிக்கிறீர்கள்?',
      AppLanguage.english: 'Which bus are you travelling on?',
      AppLanguage.hindi: 'आप किस बस में यात्रा कर रहे हैं?',
    },
    'boarding_stop': {
      AppLanguage.tamil: 'ஏறும் பேருந்து நிறுத்தம்',
      AppLanguage.english: 'Boarding Stop',
      AppLanguage.hindi: 'चढ़ने का स्टॉप',
    },
    'destination_stop': {
      AppLanguage.tamil: 'சேரும் பேருந்து நிறுத்தம்',
      AppLanguage.english: 'Intended Destination Stop',
      AppLanguage.hindi: 'गंतव्य स्टॉप',
    },
    'share_location': {
      AppLanguage.tamil: 'இருப்பிடத்தைப் பகிரவும்',
      AppLanguage.english: 'Share Location',
      AppLanguage.hindi: 'लोकेशन शेयर करें',
    },
    'assume_idle_5min': {
      AppLanguage.tamil: 'இருப்பிடம் 5 நிமிடங்கள் செயலற்றது எனக் கொள்க',
      AppLanguage.english: 'Assume that the location is idle for 5 minutes',
      AppLanguage.hindi: 'मानें कि लोकेशन 5 मिनट से निष्क्रिय है',
    },
    'no_reply_1min': {
      AppLanguage.tamil: '1 நிமிடத்தில் பதில் இல்லை',
      AppLanguage.english: 'No reply in 1 minute',
      AppLanguage.hindi: '1 मिनट में कोई जवाब नहीं',
    },
    'idle_alert_title': {
      AppLanguage.tamil: 'செயலற்ற எச்சரிக்கை (5 நிமிடம்)',
      AppLanguage.english: 'Inactivity Alert (5 Mins Idle)',
      AppLanguage.hindi: 'निष्क्रियता चेतावनी (5 मिनट)',
    },
    'idle_alert_prompt': {
      AppLanguage.tamil: 'உங்கள் இருப்பிடம் 5 நிமிடங்கள் செயலற்றதாக உள்ளது. ஏதேனும் பிரச்சனையா? பேருந்து பழுதாகிவிட்டதா?',
      AppLanguage.english: 'Your location is idle for 5 minutes. Is there any problem? Is the bus breakdown or what?',
      AppLanguage.hindi: 'आपकी लोकेशन 5 मिनट से निष्क्रिय है। क्या कोई समस्या है? क्या बस खराब हो गई है?',
    },
    'yes_bus_breakdown': {
      AppLanguage.tamil: 'ஆம், பேருந்து பழுதாகிவிட்டது',
      AppLanguage.english: 'Yes, the bus broke down',
      AppLanguage.hindi: 'हाँ, बस खराब हो गई है',
    },
    'no_normal_traffic': {
      AppLanguage.tamil: 'இல்லை, சாதாரண போக்குவரத்து நெரிசல்',
      AppLanguage.english: 'No, normal delay / traffic jam',
      AppLanguage.hindi: 'नहीं, सामान्य ट्रैफ़िक जाम है',
    },
    'passengers_informed_breakdown': {
      AppLanguage.tamil: '🚨 பயணிகளுக்கு அறிவிக்கப்பட்டது: பேருந்து பழுதாகியுள்ளது',
      AppLanguage.english: '🚨 PASSENGERS INFORMED: BUS BROKE DOWN',
      AppLanguage.hindi: '🚨 यात्रियों को सूचित किया गया: बस खराब हो गई है',
    },
    'breakdown_details_text': {
      AppLanguage.tamil: 'வழித்தடம் 95-ல் உள்ள அனைத்து பயணிகளுக்கும், TNSTC கிரீன் எக்ஸ்பிரஸ் (TN 38 N 2481) பீளமேடு அருகே பழுதாகியுள்ளது என்ற உடனடி அறிவிப்பு அனுப்பப்பட்டுள்ளது.',
      AppLanguage.english: 'All passengers on Route 95 and commuters waiting at upcoming bus stops have received an immediate notification that TNSTC Green Express (TN 38 N 2481) has broken down near Peelamedu.',
      AppLanguage.hindi: 'रूट 95 के सभी यात्रियों और आगामी बस स्टॉप पर प्रतीक्षा कर रहे यात्रियों को तत्काल सूचना भेज दी गई है कि TNSTC ग्रीन एक्सप्रेस (TN 38 N 2481) पीलमेडू के पास खराब हो गई है।',
    },
    'torch_passed_priya': {
      AppLanguage.tamil: '🔥 பிரியா எஸ். (இருக்கை 14B) க்கு டார்ச் மாற்றப்பட்டது!',
      AppLanguage.english: '🔥 Torch Passed to Priya S. (Seat 14B)!',
      AppLanguage.hindi: '🔥 प्रिया एस. (सीट 14B) को टॉर्च सौंपी गई!',
    },
    'torch_passed_details': {
      AppLanguage.tamil: 'பயணி செயலற்ற நிலையில் இருந்ததால், ஜிபிஎஸ் ஒளிபரப்பு தானாகவே பயணி #2 (பிரியா எஸ்.)-க்கு மாற்றப்பட்டது. ஒரு நொடியும் இழக்காமல் நேரலை கண்காணிப்பு தொடர்கிறது!',
      AppLanguage.english: 'Due to contributor inactivity, GPS transmission was automatically handed over to Passenger #2 (Priya S.). Live bus tracking continues without losing a second!',
      AppLanguage.hindi: 'योगदानकर्ता की निष्क्रियता के कारण, जीपीएस प्रसारण स्वचालित रूप से यात्री #2 (प्रिया एस.) को सौंप दिया गया। बिना एक सेकंड गंवाए लाइव बस ट्रैकिंग जारी है!',
    },
    'reset_simulation': {
      AppLanguage.tamil: 'சிமுலேஷனை மீட்டமைக்கவும்',
      AppLanguage.english: 'Reset Simulation',
      AppLanguage.hindi: 'सिमुलेशन रीसेट करें',
    },
    'scanning_cabin': {
      AppLanguage.tamil: 'பேருந்து அறையை ஸ்கேன் செய்கிறது...',
      AppLanguage.english: 'Scanning Bus Cabin...',
      AppLanguage.hindi: 'बस केबिन स्कैन हो रहा है...',
    },
    'passenger_sam': {
      AppLanguage.tamil: 'பயணி #1: சாம் (நீங்கள்)',
      AppLanguage.english: 'Passenger #1: Sam (You)',
      AppLanguage.hindi: 'यात्री #1: सैम (आप)',
    },

    // Profile & Settings
    'profile_and_settings': {
      AppLanguage.tamil: 'சுயவிவரம் & அமைப்புகள்',
      AppLanguage.english: 'Profile & Settings',
      AppLanguage.hindi: 'प्रोफ़ाइल और सेटिंग्स',
    },
    'community_impact': {
      AppLanguage.tamil: 'சமூக பங்களிப்பு · கோயம்புத்தூர்',
      AppLanguage.english: 'COMMUNITY IMPACT · COIMBATORE',
      AppLanguage.hindi: 'सामुदायिक प्रभाव · कोयंबटूर',
    },
    'fellow_passengers_assisted': {
      AppLanguage.tamil: '24 சக பயணிகளுக்கு உதவப்பட்டது',
      AppLanguage.english: '24 Fellow Passengers Assisted',
      AppLanguage.hindi: '24 सह-यात्रियों की सहायता की गई',
    },
    'community_impact_sub': {
      AppLanguage.tamil: 'பொதுப் போக்குவரத்து வழித்தடங்களில் ஜிபிஎஸ் பகிர்வதன் மூலம், உங்கள் தகவல் பயணிகள் சரியான நேரத்தில் பயணிக்க உதவியது.',
      AppLanguage.english: 'By contributing GPS coordinates on public transit routes, your updates helped commuters time their journeys accurately.',
      AppLanguage.hindi: 'सार्वजनिक पारगमन मार्गों पर जीपीएस साझा करके, आपके अपडेट ने यात्रियों को अपनी यात्रा को सही समय पर करने में मदद की।',
    },
    'privacy_first': {
      AppLanguage.tamil: 'தனியுரிமை & தன்னார்வப் பங்களிப்பு',
      AppLanguage.english: 'Privacy & Voluntary Contribution',
      AppLanguage.hindi: 'गोपनीयता और स्वैच्छिक योगदान',
    },
    'privacy_bullet_1': {
      AppLanguage.tamil: '1. நீங்கள் பயணத்தைத் தொடங்கும் போது மட்டுமே ஜிபிஎஸ் பகிரப்படுகிறது.\n2. சக பயணிகள் பேருந்தின் இருப்பிடம் மற்றும் வருகை நேரத்தை மட்டுமே காண்கிறார்கள்.\n3. தனிப்பட்ட அடையாளங்கள் மற்றும் பெயர்கள் ஒருபோதும் பகிரப்படாது.\n4. புகைப்பட சரிபார்ப்பு படங்கள் நிரந்தரமாக சேமிக்கப்படாது.',
      AppLanguage.english: '1. GPS sharing only occurs when you explicitly start a journey.\n2. Fellow passengers see aggregated bus location and dynamic ETA.\n3. Personal identities, names, and individual movement trails are never exposed.\n4. Photo check images are processed for verification and not stored permanently.',
      AppLanguage.hindi: '1. जीपीएस शेयरिंग केवल तब होती है जब आप स्पष्ट रूप से यात्रा शुरू करते हैं।\n2. साथी यात्री केवल बस की लोकेशन और आने का समय देखते हैं।\n3. व्यक्तिगत पहचान और नाम कभी उजागर नहीं किए जाते।\n4. फोटो चेक इमेज स्थायी रूप से संग्रहीत नहीं की जाती हैं।',
    },
    'no_net_mode_title': {
      AppLanguage.tamil: 'நோ நெட் முறை (ஆஃப்லைன்)',
      AppLanguage.english: 'No Net Mode',
      AppLanguage.hindi: 'नो नेट मोड (ऑफलाइन)',
    },
    'no_net_sub_on': {
      AppLanguage.tamil: 'இணைய இணைப்பு இல்லாத நிலை. ஜிபிஎஸ் பதிவுகள் உள்நாட்டில் பஃபர் செய்யப்படும்.',
      AppLanguage.english: 'Simulating zero internet connectivity. Live GPS records will buffer into local FIFO queue.',
      AppLanguage.hindi: 'शून्य इंटरनेट कनेक्टिविटी का अनुकरण। लाइव जीपीएस रिकॉर्ड स्थानीय कतार में बफर होंगे।',
    },
    'no_net_sub_off': {
      AppLanguage.tamil: 'ஆஃப்லைன் பகுதிகளை உருவகப்படுத்துங்கள். உள்ளூர் வரிசைப்படுத்தலை சோதிக்க இயக்கவும்.',
      AppLanguage.english: 'Simulate offline transit zones. Toggle ON to test local queuing and timestamp reconciliation.',
      AppLanguage.hindi: 'ऑफलाइन पारगमन क्षेत्रों का अनुकरण करें। स्थानीय कतार और टाइमस्टैम्प समाधान का परीक्षण करने के लिए चालू करें।',
    },
    'open_offline_portal': {
      AppLanguage.tamil: 'ஆஃப்லைன் ஜிபிஎஸ் பகிர்வு போர்ட்டலைத் திற ➔',
      AppLanguage.english: 'Open Offline GPS Sharing Portal ➔',
      AppLanguage.hindi: 'ऑफलाइन जीपीएस शेयरिंग पोर्टल खोलें ➔',
    },
    'judge_controls': {
      AppLanguage.tamil: 'டெமோ கட்டுப்பாடுகள்',
      AppLanguage.english: 'Judge Demonstration Controls',
      AppLanguage.hindi: 'डेमो नियंत्रण',
    },
    'server_url': {
      AppLanguage.tamil: 'சர்வர் இணைப்பு URL',
      AppLanguage.english: 'Server URL / Mobile IP',
      AppLanguage.hindi: 'सर्वर यूआरएल / मोबाइल आईपी',
    },
    'reset_demo_btn': {
      AppLanguage.tamil: 'டெமோவை மீட்டமைக்கவும்',
      AppLanguage.english: 'Reset Demo Presentation State',
      AppLanguage.hindi: 'डेमो स्थिति को रीसेट करें',
    },
    'logout_btn': {
      AppLanguage.tamil: 'வெளியேறு',
      AppLanguage.english: 'Log Out',
      AppLanguage.hindi: 'लॉग आउट',
    },

    // Rewards Tab
    'rewards_title': {
      AppLanguage.tamil: 'சன்மானங்கள் & கூப்பன்கள்',
      AppLanguage.english: 'Rewards & Coupons',
      AppLanguage.hindi: 'रिवार्ड्स और कूपन',
    },
    'guaranteed_card_title': {
      AppLanguage.tamil: 'உறுதிப்படுத்தப்பட்ட சன்மான அட்டை',
      AppLanguage.english: 'Guaranteed Reward Card',
      AppLanguage.hindi: 'गारंटीकृत रिवॉर्ड कार्ड',
    },
    'ready_to_scratch': {
      AppLanguage.tamil: 'சொறிந்து திறக்க தயார்',
      AppLanguage.english: 'READY TO SCRATCH',
      AppLanguage.hindi: 'स्क्रैच के लिए तैयार',
    },
    'guaranteed_card_sub': {
      AppLanguage.tamil: 'ஒவ்வொரு Trava சன்மான அட்டையும் உண்மையான உள்ளூர் சலுகையை உறுதி செய்கிறது.',
      AppLanguage.english: 'Every Trava reward card guarantees an authentic local reward. No losing cards.',
      AppLanguage.hindi: 'प्रत्येक Trava रिवॉर्ड कार्ड एक वास्तविक स्थानीय इनाम की गारंटी देता है। कोई नुकसान नहीं।',
    },
    'partner_categories_title': {
      AppLanguage.tamil: 'கூட்டாளர் சன்மான பிரிவுகள்',
      AppLanguage.english: 'Partner Reward Categories',
      AppLanguage.hindi: 'पार्टनर रिवॉर्ड श्रेणियां',
    },
    'partner_portal_title': {
      AppLanguage.tamil: 'கூட்டாளர் வணிகர் போர்ட்டல்',
      AppLanguage.english: 'Partner Merchant Portal',
      AppLanguage.hindi: 'पार्टनर मर्चेंट पोर्टल',
    },
    'partner_portal_sub': {
      AppLanguage.tamil: 'பேக்கரி, உணவகம், பல்பொருள் அங்காடி & உடற்பயிற்சி கூட்டாளர்கள் குறியீடுகளை சரிபார்க்கும் தளம்: http://localhost:5000/bakery',
      AppLanguage.english: 'Bakery, Restaurant, Supermarket & Gym partners validate codes at: http://localhost:5000/bakery',
      AppLanguage.hindi: 'बेकरी, रेस्टोरेंट, सुपरमार्केट और जिम पार्टनर कोड सत्यापित करते हैं: http://localhost:5000/bakery',
    },
    'your_coupons_title': {
      AppLanguage.tamil: 'உங்கள் சலுகைக் கூப்பன்கள்',
      AppLanguage.english: 'Your Redeemed & Active Coupons',
      AppLanguage.hindi: 'आपके सक्रिय और भुनाए गए कूपन',
    },
    'deals_count': {
      AppLanguage.tamil: 'சலுகைகள்',
      AppLanguage.english: 'Deals',
      AppLanguage.hindi: 'डील्स',
    },
    'card_locked_title': {
      AppLanguage.tamil: 'சன்மான அட்டை பூட்டப்பட்டுள்ளது',
      AppLanguage.english: 'Scratch Card Locked',
      AppLanguage.hindi: 'स्क्रैच कार्ड लॉक है',
    },
    'card_locked_sub': {
      AppLanguage.tamil: 'திறக்க பேருந்தில் ஜிபிஎஸ் பகிர்ந்து 100 புள்ளிகளை அடையுங்கள்.',
      AppLanguage.english: 'Reach 100 points by sharing GPS on a bus to unlock.',
      AppLanguage.hindi: 'अनलॉक करने के लिए बस में जीपीएस साझा करके 100 अंक तक पहुंचें।',
    },
    'swipe_scratch': {
      AppLanguage.tamil: 'திறக்க விரலால் தேய்க்கவும்!',
      AppLanguage.english: 'Swipe finger to scratch and reveal!',
      AppLanguage.hindi: 'रिवील करने के लिए उंगली से स्क्रैच करें!',
    },
    'all_partners': {
      AppLanguage.tamil: 'அனைத்து சலுகைகள்',
      AppLanguage.english: 'All Deals',
      AppLanguage.hindi: 'सभी डील्स',
    },
    'cat_bakeries': {
      AppLanguage.tamil: 'பேக்கரி',
      AppLanguage.english: 'Bakery',
      AppLanguage.hindi: 'बेकरी',
    },
    'cat_restaurants': {
      AppLanguage.tamil: 'உணவகம்',
      AppLanguage.english: 'Restaurant',
      AppLanguage.hindi: 'रेस्टोरेंट',
    },
    'cat_supermarkets': {
      AppLanguage.tamil: 'பல்பொருள் அங்காடி',
      AppLanguage.english: 'Supermarket',
      AppLanguage.hindi: 'सुपरमार्केट',
    },
    'cat_gym': {
      AppLanguage.tamil: 'உடற்பயிற்சி & ஃபிட்னஸ்',
      AppLanguage.english: 'Gym & Fitness',
      AppLanguage.hindi: 'जिम और फिटनेस',
    },

    // Auth
    'sign_in_title': {
      AppLanguage.tamil: 'மீண்டும் வருக',
      AppLanguage.english: 'Welcome Back',
      AppLanguage.hindi: 'वापसी पर स्वागत है',
    },
    'sign_in_sub': {
      AppLanguage.tamil: 'Trava மூலம் நிகழ்நேர பேருந்து சேவையை அணுகவும்',
      AppLanguage.english: 'Sign in to access community transit tracking',
      AppLanguage.hindi: 'सामुदायिक पारगमन ट्रैकिंग के लिए साइन इन करें',
    },
    'btn_sign_in': {
      AppLanguage.tamil: 'உள்நுழைக',
      AppLanguage.english: 'Sign In',
      AppLanguage.hindi: 'साइन इन करें',
    },
    'btn_quick_demo': {
      AppLanguage.tamil: 'விரைவு டெமோ உள்நுழைவு',
      AppLanguage.english: 'Quick Demo Login',
      AppLanguage.hindi: 'त्वरित डेमो लॉगिन',
    },

    // Track Bus Tab Specifics
    'starting_point_label': {
      AppLanguage.tamil: 'தொடக்கப் புள்ளி (நீங்கள் எங்கு இருக்கிறீர்கள்?)',
      AppLanguage.english: 'STARTING POINT (WHERE ARE YOU?)',
      AppLanguage.hindi: 'शुरुआती बिंदु (आप कहाँ हैं?)',
    },
    'destination_point_label': {
      AppLanguage.tamil: 'இறுதி சேருமிடம்',
      AppLanguage.english: 'DESTINATION POINT',
      AppLanguage.hindi: 'गंतव्य बिंदु',
    },
    'search_available_routes_btn': {
      AppLanguage.tamil: 'கிடைக்கும் வழித்தடங்கள் & பேருந்துகளைத் தேடுங்கள்',
      AppLanguage.english: 'Search Available Routes & Buses',
      AppLanguage.hindi: 'उपलब्ध मार्ग और बसें खोजें',
    },
    'popular_coimbatore_corridors': {
      AppLanguage.tamil: 'பிரபலமான கோயம்புத்தூர் வழித்தடங்கள்',
      AppLanguage.english: 'POPULAR COIMBATORE CORRIDORS',
      AppLanguage.hindi: 'लोकप्रिय कोयंबटूर गलियारे',
    },
    'no_direct_routes_found': {
      AppLanguage.tamil: 'நேரடி வழித்தடம் கிடைக்கவில்லை',
      AppLanguage.english: 'No Direct Routes Found',
      AppLanguage.hindi: 'कोई सीधा मार्ग नहीं मिला',
    },
    'available_routes': {
      AppLanguage.tamil: 'கிடைக்கும் வழித்தடங்கள்',
      AppLanguage.english: 'Available Routes',
      AppLanguage.hindi: 'उपलब्ध मार्ग',
    },
    'live_simulation': {
      AppLanguage.tamil: '● நேரலை சிமுலேஷன்',
      AppLanguage.english: '● LIVE SIMULATION',
      AppLanguage.hindi: '● लाइव सिमुलेशन',
    },
    'route_prefix': {
      AppLanguage.tamil: 'வழித்தடம்',
      AppLanguage.english: 'Route',
      AppLanguage.hindi: 'मार्ग',
    },
    'mins_unit': {
      AppLanguage.tamil: 'நிமிடங்கள்',
      AppLanguage.english: 'mins',
      AppLanguage.hindi: 'मिनट',
    },
    'active_buses_count': {
      AppLanguage.tamil: 'செயலில் உள்ள பேருந்துகள்',
      AppLanguage.english: 'Active Buses',
      AppLanguage.hindi: 'सक्रिय बसें',
    },
    'govt_label': {
      AppLanguage.tamil: 'அரசு',
      AppLanguage.english: 'Govt',
      AppLanguage.hindi: 'सरकारी',
    },
    'private_label': {
      AppLanguage.tamil: 'தனியார்',
      AppLanguage.english: 'Private',
      AppLanguage.hindi: 'निजी',
    },
    'no_buses_running': {
      AppLanguage.tamil: 'இந்த வழித்தடத்தில் தற்போது பேருந்துகள் எதுவும் இயங்கவில்லை.',
      AppLanguage.english: 'No buses running right now on this route.',
      AppLanguage.hindi: 'इस मार्ग पर अभी कोई बस नहीं चल रही है।',
    },
    'tnstc_govt': {
      AppLanguage.tamil: 'TNSTC அரசு',
      AppLanguage.english: 'TNSTC GOVT',
      AppLanguage.hindi: 'TNSTC सरकारी',
    },
    'private_prefix': {
      AppLanguage.tamil: 'தனியார்',
      AppLanguage.english: 'PRIVATE',
      AppLanguage.hindi: 'निजी',
    },
    'min_eta': {
      AppLanguage.tamil: 'நிமிட வருகை நேரம்',
      AppLanguage.english: 'min ETA',
      AppLanguage.hindi: 'मिनट ईटीए',
    },
    'seats_available': {
      AppLanguage.tamil: 'இருக்கைகள் உள்ளன',
      AppLanguage.english: 'Seats Available',
      AppLanguage.hindi: 'सीटें उपलब्ध',
    },
    'packed': {
      AppLanguage.tamil: 'கூட்டம் நிறைந்தது',
      AppLanguage.english: 'Packed',
      AppLanguage.hindi: 'खचाखच भरी',
    },
    'empty': {
      AppLanguage.tamil: 'காலியாக உள்ளது',
      AppLanguage.english: 'Empty',
      AppLanguage.hindi: 'खाली',
    },
    'open_live_map': {
      AppLanguage.tamil: 'நேரலை வரைபடத்தைத் திற',
      AppLanguage.english: 'Open Live Map',
      AppLanguage.hindi: 'लाइव मैप खोलें',
    },
    'no_direct_route_connecting': {
      AppLanguage.tamil: 'இணைக்கும் நேரடி வழித்தடம் இல்லை',
      AppLanguage.english: 'No Direct Route Connecting',
      AppLanguage.hindi: 'कोई सीधा कनेक्टिंग मार्ग नहीं',
    },
    'pro_tip_routes': {
      AppLanguage.tamil: '💡 குறிப்பு: பெரும்பாலான வழித்தடங்கள் காந்திபுரம் மத்திய பேருந்து நிலையம் அல்லது சிங்காநல்லூர் வழியாக இணைகின்றன.',
      AppLanguage.english: '💡 Pro Tip: Most routes connect smoothly via Gandhipuram Central Bus Stand or Singanallur Terminus.',
      AppLanguage.hindi: '💡 सुझाव: अधिकांश मार्ग गांधीपुरम सेंट्रल बस स्टैंड या सिंगानल्लूर के माध्यम से आसानी से जुड़ते हैं।',
    },
    'show_all_routes_btn': {
      AppLanguage.tamil: 'அனைத்து 5 தீவிர கோயம்புத்தூர் வழித்தடங்களையும் காட்டு',
      AppLanguage.english: 'Show All 5 Active Coimbatore Routes',
      AppLanguage.hindi: 'सभी 5 सक्रिय कोयंबटूर मार्ग दिखाएं',
    },

    // Rewards Tab Additional
    'total_community_balance': {
      AppLanguage.tamil: 'மொத்த சமூக இருப்பு',
      AppLanguage.english: 'TOTAL COMMUNITY BALANCE',
      AppLanguage.hindi: 'कुल सामुदायिक शेष',
    },
    'guaranteed_rewards_badge': {
      AppLanguage.tamil: 'உறுதிப்படுத்தப்பட்ட சன்மானம்',
      AppLanguage.english: 'GUARANTEED REWARDS',
      AppLanguage.hindi: 'गारंटीकृत पुरस्कार',
    },
    'points_label': {
      AppLanguage.tamil: 'புள்ளிகள்',
      AppLanguage.english: 'Points',
      AppLanguage.hindi: 'अंक',
    },
    'next_reward_card_prefix': {
      AppLanguage.tamil: 'அடுத்த சன்மான அட்டை',
      AppLanguage.english: 'Next Reward Card',
      AppLanguage.hindi: 'अगला रिवॉर्ड कार्ड',
    },
    'guaranteed_reward_prefix': {
      AppLanguage.tamil: 'உறுதிப்படுத்தப்பட்ட',
      AppLanguage.english: 'GUARANTEED',
      AppLanguage.hindi: 'गारंटीकृत',
    },
    'reward_suffix': {
      AppLanguage.tamil: 'சன்மானம்',
      AppLanguage.english: 'REWARD',
      AppLanguage.hindi: 'पुरस्कार',
    },
    'code_prefix': {
      AppLanguage.tamil: 'குறியீடு:',
      AppLanguage.english: 'CODE:',
      AppLanguage.hindi: 'कोड:',
    },
    'already_used_badge': {
      AppLanguage.tamil: 'பயன்படுத்தப்பட்டது',
      AppLanguage.english: 'ALREADY USED',
      AppLanguage.hindi: 'उपयोग किया गया',
    },
    'active_badge': {
      AppLanguage.tamil: 'செயலில் உள்ளது',
      AppLanguage.english: 'ACTIVE',
      AppLanguage.hindi: 'सक्रिय',
    },
    'no_coupons_found': {
      AppLanguage.tamil: 'இந்த பிரிவில் கூப்பன்கள் எதுவும் கிடைக்கவில்லை.',
      AppLanguage.english: 'No coupons found for this category.',
      AppLanguage.hindi: 'इस श्रेणी के लिए कोई कूपन नहीं मिला।',
    },
    'points_ledger_title': {
      AppLanguage.tamil: 'புள்ளிகள் பரிவர்த்தனை கணக்கு',
      AppLanguage.english: 'Points Transaction Ledger',
      AppLanguage.hindi: 'अंक लेनदेन खाता',
    },
    'balance_pts_prefix': {
      AppLanguage.tamil: 'இருப்பு:',
      AppLanguage.english: 'Balance:',
      AppLanguage.hindi: 'शेष:',
    },

    // Features Tab Additional
    'stop_sharing_gps': {
      AppLanguage.tamil: 'ஜிபிஎஸ் பகிர்வை நிறுத்து (இறங்குவதை உருவகப்படுத்து)',
      AppLanguage.english: 'Stop Sharing GPS (Simulate Alighting)',
      AppLanguage.hindi: 'जीपीएस शेयरिंग बंद करें (उतरने का अनुकरण)',
    },
    'approve_torch_btn': {
      AppLanguage.tamil: '🤝 ஒப்புதல் அளித்து டார்ச்சை ஏற்றுக்கொள் (பயணி #2)',
      AppLanguage.english: '🤝 Approve & Accept Torch (Passenger #2)',
      AppLanguage.hindi: '🤝 टॉर्च स्वीकार करें (यात्री #2)',
    },
    'torch_passed_title': {
      AppLanguage.tamil: 'டார்ச் வெற்றிகரமாக மாற்றப்பட்டது!',
      AppLanguage.english: 'Torch Successfully Passed!',
      AppLanguage.hindi: 'टॉर्च सफलतापूर्वक सौंप दी गई!',
    },
    'reset_handoff_btn': {
      AppLanguage.tamil: 'சிமுலேஷனை மீட்டமைக்கவும்',
      AppLanguage.english: 'Reset Handoff Simulation',
      AppLanguage.hindi: 'हैंडऑफ सिमुलेशन रीसेट करें',
    },
    'offline_gps_sharing_title': {
      AppLanguage.tamil: 'ஆஃப்லைன் ஜிபிஎஸ் பகிர்வு',
      AppLanguage.english: 'Offline GPS Sharing',
      AppLanguage.hindi: 'ऑफलाइन जीपीएस शेयरिंग',
    },
    'no_net_mode': {
      AppLanguage.tamil: 'நோ நெட் முறை',
      AppLanguage.english: 'No Net Mode',
      AppLanguage.hindi: 'नो नेट मोड',
    },
    'local_gps_queue': {
      AppLanguage.tamil: 'உள்ளூர் ஜிபிஎஸ் பதிவு வரிசை',
      AppLanguage.english: 'Local GPS Record Queue',
      AppLanguage.hindi: 'स्थानीय जीपीएस रिकॉर्ड कतार',
    },
    'reconciliation_protocol': {
      AppLanguage.tamil: 'நேர முத்திரை ஒத்திசைவு நெறிமுறை',
      AppLanguage.english: 'Timestamp Reconciliation Protocol',
      AppLanguage.hindi: 'टाइमस्टैम्प समाधान प्रोटोकॉल',
    },
    'simulate_no_net_btn': {
      AppLanguage.tamil: 'நோ நெட் முறையை உருவகப்படுத்து (15 வினாடி EST & பஃபர்)',
      AppLanguage.english: 'Simulate No Net Mode (15s EST Tracking & Buffer)',
      AppLanguage.hindi: 'नो नेट मोड का अनुकरण करें (15 सेकंड ईएसटी और बफर)',
    },
    'est_mode': {
      AppLanguage.tamil: 'EST · கணிக்கப்பட்ட கண்காணிப்பு முறை',
      AppLanguage.english: 'EST · Estimated Tracking Mode',
      AppLanguage.hindi: 'ईएसटी · अनुमानित ट्रैकिंग मोड',
    },
    'live_verified_mode': {
      AppLanguage.tamil: 'நேரலை · சரிபார்க்கப்பட்ட கண்காணிப்பு முறை',
      AppLanguage.english: 'LIVE · Verified Tracking Mode',
      AppLanguage.hindi: 'लाइव · सत्यापित ट्रैकिंग मोड',
    },
    'network_resumed_msg': {
      AppLanguage.tamil: 'இணையம் மீண்டும் வந்தது! நேரலை கண்காணிப்பு சரிபார்க்கப்பட்டது: பேருந்து பீளமேடு மற்றும் நவ இந்தியா இடையே நடுப்பகுதியை அடைந்தது.',
      AppLanguage.english: 'Network resumed! Live tracking verified: bus reached midpoint between Peelamedu and Nava India.',
      AppLanguage.hindi: 'नेटवर्क फिर से शुरू! लाइव ट्रैकिंग सत्यापित: बस पीलमेडू और नवा इंडिया के बीच मध्य बिंदु पर पहुंच गई।',
    },
    'regular_checks_title': {
      AppLanguage.tamil: 'வழக்கமான சோதனைகள்',
      AppLanguage.english: 'Regular Checks',
      AppLanguage.hindi: 'नियमित जांच',
    },

    // Share GPS Tab
    'community_bus_tracking_title': {
      AppLanguage.tamil: 'சமூக பேருந்து கண்காணிப்பு',
      AppLanguage.english: 'Community Bus Tracking',
      AppLanguage.hindi: 'सामुदायिक बस ट्रैकिंग',
    },
    'share_journey_desc': {
      AppLanguage.tamil: 'மற்ற பயணிகள் இந்த பேருந்தைக் கண்காணிக்க உங்கள் பயணத்தின் இருப்பிடத்தைப் பகிருங்கள்.',
      AppLanguage.english: "Share your journey's location to help other passengers track this bus.",
      AppLanguage.hindi: 'अन्य यात्रियों को इस बस को ट्रैक करने में मदद करने के लिए अपनी यात्रा की लोकेशन साझा करें।',
    },
    'share_gps_rewards_desc': {
      AppLanguage.tamil: 'Trava விரைவு கேமரா சரிபார்ப்புடன் பேருந்து இருப்பை உறுதி செய்கிறது. பேக்கரி, உணவகம், பல்பொருள் அங்காடி போன்ற உள்ளூர் சலுகை அட்டைகளைத் திறக்க ஒவ்வொரு தகுதியான பயணத்திற்கும் +50 புள்ளிகளைப் பெறுங்கள்.',
      AppLanguage.english: 'Trava verifies active bus occupancy with a quick camera photo check. Earn +50 points per eligible journey to unlock guaranteed local reward scratch cards (Bakery, Restaurant, Supermarket, Gym).',
      AppLanguage.hindi: 'Trava त्वरित कैमरा फोटो जांच के साथ बस में उपस्थिति सत्यापित करता है। गारंटीकृत स्थानीय इनाम कार्ड अनलॉक करने के लिए प्रत्येक यात्रा पर +50 अंक अर्जित करें।',
    },
    'privacy_preserved_note': {
      AppLanguage.tamil: 'தனியுரிமை பாதுகாப்பானது: மற்ற பயணிகள் பேருந்து குறியீட்டை மட்டுமே காண்பார்கள், உங்கள் தனிப்பட்ட சுயவிவரம் அல்லது வரலாற்று விவரங்களை அல்ல.',
      AppLanguage.english: 'Privacy Preserved: Other passengers only see the bus marker, never your personal profile or location history.',
      AppLanguage.hindi: 'गोपनीयता सुरक्षित: अन्य यात्री केवल बस मार्कर देखते हैं, आपकी व्यक्तिगत प्रोफ़ाइल या लोकेशन इतिहास कभी नहीं।',
    },
    'verify_and_share_btn': {
      AppLanguage.tamil: 'சரிபார்த்து இருப்பிடத்தைப் பகிரவும்',
      AppLanguage.english: 'Verify & Share Location',
      AppLanguage.hindi: 'सत्यापित करें और लोकेशन शेयर करें',
    },
    'quick_demo_start_btn': {
      AppLanguage.tamil: 'விரைவு டெமோ தொடக்கம் (கேமரா புறக்கணிப்பு)',
      AppLanguage.english: 'Quick Demo Start (Bypass Camera)',
      AppLanguage.hindi: 'त्वरित डेमो प्रारंभ (कैमरा बाईपास)',
    },
    'reconciliation_steps': {
      AppLanguage.tamil: '1. ஒவ்வொரு ஜிபிஎஸ் பிங்கும் பங்களிப்பாளர் சாதனத்தில் துல்லியமான நேர முத்திரையுடன் குறிக்கப்படுகிறது.\n2. நெட்வொர்க் மீண்டும் இணையும்போது, Trava வரிசையாக பதிவுகளை செயலாக்குகிறது.\n3. தற்போதைய அதிகாரப்பூர்வ நிலையை விட பழைய காலாவதியான பாக்கெட்டுகள் நிராகரிக்கப்படுகின்றன.\n4. பேருந்து குறிப்பான் புதிய சரிபார்க்கப்பட்ட ஆயத்தொலைவுக்கு முன்னோக்கி புதுப்பிக்கப்படுகிறது.',
      AppLanguage.english: '1. Each GPS ping is tagged with high-precision ISO-8601 UTC timestamps on the contributor device.\n2. When network reconnects, Trava processes the queue sequentially.\n3. Stale or delayed packets older than current authoritative position are rejected.\n4. The bus marker updates forward to the newest verified coordinate.',
      AppLanguage.hindi: '1. प्रत्येक जीपीएस पिंग योगदानकर्ता डिवाइस पर उच्च-सटीक टाइमस्टैम्प के साथ टैग किया जाता है।\n2. नेटवर्क फिर से जुड़ने पर, Trava कतार को क्रमिक रूप से संसाधित करता है।\n3. वर्तमान आधिकारिक स्थिति से पुराने पैकेट अस्वीकार कर दिए जाते हैं।\n4. बस मार्कर नवीनतम सत्यापित निर्देशांक पर अपडेट होता है।',
    },
    'starting_demo_sharing': {
      AppLanguage.tamil: 'டெமோ பகிர்வு தொடங்குகிறது...',
      AppLanguage.english: 'Starting Demo Sharing...',
      AppLanguage.hindi: 'डेमो शेयरिंग शुरू हो रही है...',
    },
    'verify_demo_credentials': {
      AppLanguage.tamil: 'டெமோ நற்சான்றிதழ்களைப் பயன்படுத்தி சரிபார்க்கவும்',
      AppLanguage.english: 'Verify Using Demo Credentials',
      AppLanguage.hindi: 'डेमो क्रेडेंशियल्स का उपयोग करके सत्यापित करें',
    },
    'verify_photo_btn': {
      AppLanguage.tamil: 'புகைப்படத்தை சரிபார்த்து பகிரத் தொடங்குங்கள்',
      AppLanguage.english: 'Verify Photo & Start Sharing',
      AppLanguage.hindi: 'फ़ोटो सत्यापित करें और साझा करना प्रारंभ करें',
    },
    'passenger_1_sam': {
      AppLanguage.tamil: 'பயணி #1: சாம் (நீங்கள்)',
      AppLanguage.english: 'Passenger #1: Sam (You)',
      AppLanguage.hindi: 'यात्री #1: सैम (आप)',
    },
    'priya_seat': {
      AppLanguage.tamil: 'பிரியா எஸ். · இருக்கை 14B',
      AppLanguage.english: 'Priya S. · Seat 14B',
      AppLanguage.hindi: 'प्रिया एस. · सीट 14B',
    },
    'assume_idle_btn': {
      AppLanguage.tamil: 'இருப்பிடம் 5 நிமிடங்கள் செயலற்ற நிலையில் உள்ளது என கருதுங்கள்',
      AppLanguage.english: 'Assume that the location is idle for 5 minutes',
      AppLanguage.hindi: 'मान लें कि स्थान 5 मिनट के लिए निष्क्रिय है',
    },
    'no_reply_btn': {
      AppLanguage.tamil: '1 நிமிடத்தில் பதில் இல்லை',
      AppLanguage.english: 'No reply in 1 minute',
      AppLanguage.hindi: '1 मिनट में कोई उत्तर नहीं',
    },
    'idle_dialog_title': {
      AppLanguage.tamil: 'உங்கள் இருப்பிடம் 5 நிமிடங்கள் செயலற்ற நிலையில் உள்ளது. ஏதேனும் பிரச்சனையா? பேருந்து பழுதடைந்துவிட்டதா அல்லது என்ன?',
      AppLanguage.english: 'Your location is idle for 5 minutes. Is there any problem? Is the bus breakdown or what?',
      AppLanguage.hindi: 'आपका स्थान 5 मिनट से निष्क्रिय है। क्या कोई समस्या है? क्या बस खराब हो गई है या क्या?',
    },
    'bus_broke_down_btn': {
      AppLanguage.tamil: 'ஆம், பேருந்து பழுதடைந்துவிட்டது',
      AppLanguage.english: 'Yes, the bus broke down',
      AppLanguage.hindi: 'हाँ, बस खराब हो गई',
    },
    'normal_delay_btn': {
      AppLanguage.tamil: 'இல்லை, சாதாரண தாமதம் / போக்குவரத்து நெரிசல்',
      AppLanguage.english: 'No, normal delay / traffic jam',
      AppLanguage.hindi: 'नहीं, सामान्य देरी / ट्रैफिक जाम',
    },
    'decentralized_handoff_sub': {
      AppLanguage.tamil: 'பரவலாக்கப்பட்ட பங்களிப்பாளர் ஒப்படைப்பு',
      AppLanguage.english: 'Decentralized Contributor Handoff',
      AppLanguage.hindi: 'विकेंद्रीकृत योगदानकर्ता हैंडऑफ',
    },
    'pass_torch_desc': {
      AppLanguage.tamil: 'ஒரு பயணி ஜிபிஎஸ் பகிர்வை நிறுத்தும்போது, அதே பேருந்தில் பயணிக்கும் மற்றொரு தகுதியான பயணியை Trava தானாகவே தேடுகிறது, இதனால் நேரலை கண்காணிப்பு ஒரு நொடியும் குறையாமல் தொடர்கிறது.',
      AppLanguage.english: 'When one passenger stops sharing GPS, Trava automatically looks for another eligible passenger travelling on the same bus, keeping live tracking continuous without dropping a second.',
      AppLanguage.hindi: 'जब एक यात्री जीपीएस शेयर करना बंद करता है, तो Trava उसी बस में यात्रा कर रहे किसी अन्य योग्य यात्री को स्वचालित रूप से ढूंढता है।',
    },
    'primary_contributor_sharing': {
      AppLanguage.tamil: 'முதன்மை பங்களிப்பாளர் · இருப்பிடத்தைப் பகிர்கிறார்',
      AppLanguage.english: 'Primary Contributor · Sharing Location',
      AppLanguage.hindi: 'प्राथमिक योगदानकर्ता · स्थान साझा कर रहे हैं',
    },
    'searching_passenger_route95': {
      AppLanguage.tamil: 'டார்ச்சை ஒப்படைக்க வழித்தடம் 95-ல் மற்றொரு தகுதியான பயணியைத் தேடுகிறது...',
      AppLanguage.english: 'Searching for another eligible passenger on Route 95 to pass the torch...',
      AppLanguage.hindi: 'टॉर्च सौंपने के लिए रूट 95 पर किसी अन्य योग्य यात्री की तलाश की जा रही है...',
    },
    'eligible_passenger_found': {
      AppLanguage.tamil: 'பேருந்துக்குள் தகுதியான பயணி கண்டுபிடிக்கப்பட்டார்! 🎯',
      AppLanguage.english: 'Eligible Passenger Found Inside Bus! 🎯',
      AppLanguage.hindi: 'बस के अंदर योग्य यात्री मिला! 🎯',
    },
    'torch_active_passenger2': {
      AppLanguage.tamil: 'பயணி #2-ல் டார்ச் செயலில் உள்ளது!',
      AppLanguage.english: 'Torch Active on Passenger #2!',
      AppLanguage.hindi: 'यात्री #2 पर टॉर्च सक्रिय है!',
    },
    'gps_uninterrupted': {
      AppLanguage.tamil: 'ஜிபிஎஸ் ஸ்ட்ரீமிங் தடையின்றி இயங்குகிறது',
      AppLanguage.english: 'GPS streaming uninterrupted',
      AppLanguage.hindi: 'जीपीएस निर्बाध रूप से स्ट्रीम हो रहा है',
    },
    'awaiting_approval': {
      AppLanguage.tamil: 'டார்ச்சை ஒப்படைக்க ஒப்புதலுக்காக காத்திருக்கிறது',
      AppLanguage.english: 'Awaiting approval to pass the torch',
      AppLanguage.hindi: 'टॉर्च सौंपने की मंजूरी का इंतज़ार है',
    },
    'verified_onboard_sub': {
      AppLanguage.tamil: 'பேருந்தில் இருப்பது சரிபார்க்கப்பட்டது · வலுவான ஜிபிஎஸ் · பேட்டரி 84%',
      AppLanguage.english: 'Verified onboard · High GPS Signal · Battery 84%',
      AppLanguage.hindi: 'सत्यापित ऑनबोर्ड · उच्च जीपीएस सिग्नल · बैटरी 84%',
    },
    'priya_handoff_desc': {
      AppLanguage.tamil: 'Trava பிரியா எஸ்.-க்கு ஒப்படைப்பு கோரிக்கையை அனுப்பியுள்ளது. ஒப்புதல் கிடைத்ததும், பிரியா இந்த பேருந்தின் இருப்பிடத்தைப் பகிர்வதை ஏற்பார்.',
      AppLanguage.english: 'Trava has sent a handoff request to Priya S. When approved, Priya will take over sharing the location for this bus.',
      AppLanguage.hindi: 'Trava ने प्रिया एस. को हैंडऑफ अनुरोध भेजा है। स्वीकृत होने पर, प्रिया इस बस के स्थान को साझा करना संभालेंगी।',
    },
    'priya_sharing_live': {
      AppLanguage.tamil: 'பிரியா எஸ். இப்போது நேரலை இருப்பிடத்தைப் பகிர்கிறார். பேருந்து நிறுத்தங்களில் உள்ள பயணிகள் எந்தவித கண்காணிப்பு தடையுமின்றி காண்கிறார்கள்.',
      AppLanguage.english: 'Priya S. is now sharing live location. Fellow passengers at bus stops experience zero tracking blackout.',
      AppLanguage.hindi: 'प्रिया एस. अब लाइव लोकेशन शेयर कर रही हैं। बस स्टॉप पर अन्य यात्री बिना किसी रुकावट के ट्रैक कर सकते हैं।',
    },
    'offline_gps_desc': {
      AppLanguage.tamil: 'இணையம் இல்லாதபோது ஜிபிஎஸ் பதிவுகள் உள்ளூரில் சேமிக்கப்படும். இணைப்பு திரும்பியதும் ஒத்திசைக்கப்படும். நேர முத்திரைகள் புதிய தரவு மேலெழுதப்படுவதைத் தடுக்கின்றன.',
      AppLanguage.english: 'GPS records can be queued locally when the internet is unavailable. Queued records sync when connectivity returns. Timestamps help prevent old GPS records from overwriting newer location.',
      AppLanguage.hindi: 'इंटरनेट न होने पर जीपीएस रिकॉर्ड स्थानीय रूप से कतारबद्ध किए जा सकते हैं। कनेक्टिविटी वापस आने पर सिंक होते हैं।',
    },
    'queue_and_recon_sub': {
      AppLanguage.tamil: 'உள்ளூர் வரிசைப்படுத்தல் & நேர முத்திரை ஒத்திசைவு',
      AppLanguage.english: 'Local Queueing & Timestamp Reconciliation',
      AppLanguage.hindi: 'स्थानीय कतार और टाइमस्टैम्प मिलान',
    },
    'regular_checks_desc': {
      AppLanguage.tamil: 'ஜிபிஎஸ் பங்களிப்பாளர் 5 நிமிடங்கள் ஒரே இடத்தில் இருந்தால், Trava பாதுகாப்பு சோதனையை நடத்தும். பேருந்து பழுதானால் பயணிகளுக்கு எச்சரிக்கை அனுப்பப்படும். 1 நிமிடத்தில் பதிலளிக்கவில்லை என்றால் டார்ச் தானாக அடுத்த பயணிக்கு செல்லும்.',
      AppLanguage.english: 'When a GPS contributor stays stationary for 5 minutes, Trava runs a safety check. If the bus is broken down, commuters are alerted. If unanswered within 1 minute, the torch passes to another passenger.',
      AppLanguage.hindi: 'जब जीपीएस योगदानकर्ता 5 मिनट तक स्थिर रहता है, तो Trava सुरक्षा जांच चलाता है। यदि बस खराब हो जाती है, तो यात्रियों को सतर्क किया जाता है।',
    },
    'inactivity_detection_sub': {
      AppLanguage.tamil: 'செயலற்ற தன்மையைக் கண்டறிதல் & அவசர நெறிமுறை',
      AppLanguage.english: 'Inactivity Detection & Emergency Protocol',
      AppLanguage.hindi: 'निष्क्रियता का पता लगाना और आपातकालीन प्रोटोकॉल',
    },
    'broken_down_badge': {
      AppLanguage.tamil: 'பழுதடைந்தது',
      AppLanguage.english: 'BROKEN DOWN',
      AppLanguage.hindi: 'खराब हो गई',
    },
    'torch_passed_badge': {
      AppLanguage.tamil: 'டார்ச் மாற்றப்பட்டது',
      AppLanguage.english: 'TORCH PASSED',
      AppLanguage.hindi: 'टॉर्च सौंपी गई',
    },
    'idle_5m_badge': {
      AppLanguage.tamil: '5நிமி செயலற்றது',
      AppLanguage.english: 'IDLE 5M',
      AppLanguage.hindi: '5 मिनट निष्क्रिय',
    },
    'sharing_live_badge': {
      AppLanguage.tamil: 'நேரலை பகிர்வு',
      AppLanguage.english: 'SHARING LIVE',
      AppLanguage.hindi: 'लाइव साझा',
    },
    'simulate_no_reply_1min': {
      AppLanguage.tamil: 'உருவகப்படுத்து: 1 நிமிடத்தில் பதில் இல்லை (டார்ச் மாற்று)',
      AppLanguage.english: 'Simulate: No reply in 1 minute (Pass Torch)',
      AppLanguage.hindi: 'अनुकरण: 1 मिनट में कोई उत्तर नहीं (टॉर्च सौंपें)',
    },
    'stop_sharing_reset': {
      AppLanguage.tamil: 'ஜிபிஎஸ் பகிர்வை நிறுத்து (மீட்டமை)',
      AppLanguage.english: 'Stop Sharing GPS (Reset)',
      AppLanguage.hindi: 'जीपीएस साझा करना बंद करें (रीसेट)',
    },
    'breakdown_broadcast_desc': {
      AppLanguage.tamil: 'வழித்தடம் 95-ல் உள்ள அனைத்து பயணிகளுக்கும் மற்றும் அடுத்தடுத்த நிறுத்தங்களில் காத்திருக்கும் பயணிகளுக்கும் TNSTC கிரீன் எக்ஸ்பிரஸ் (TN 38 N 2481) பீளமேடு அருகில் பழுதடைந்துவிட்டது என்ற உடனடி அறிவிப்பு கிடைத்துள்ளது.',
      AppLanguage.english: 'All passengers on Route 95 and commuters waiting at upcoming bus stops have received an immediate notification that TNSTC Green Express (TN 38 N 2481) has broken down near Peelamedu.',
      AppLanguage.hindi: 'मार्ग 95 के सभी यात्रियों और आगामी बस स्टॉप पर प्रतीक्षा कर रहे यात्रियों को तत्काल सूचना मिल गई है कि टीएनएसटीसी ग्रीन एक्सप्रेस पीलमेडू के पास खराब हो गई है।',
    },
    'torch_passed_inactivity_desc': {
      AppLanguage.tamil: 'பங்களிப்பாளர் பதிலளிக்காததால், ஜிபிஎஸ் பகிர்வு தானாகவே பயணி #2 (பிரியா எஸ்.)-க்கு மாற்றப்பட்டது. நேரலை பேருந்து கண்காணிப்பு ஒரு நொடியும் இழக்காமல் தொடர்கிறது!',
      AppLanguage.english: 'Due to contributor inactivity, GPS transmission was automatically handed over to Passenger #2 (Priya S.). Live bus tracking continues without losing a second!',
      AppLanguage.hindi: 'योगदानकर्ता की निष्क्रियता के कारण, जीपीएस ट्रांसमिशन स्वचालित रूप से यात्री #2 (प्रिया एस.) को सौंप दिया गया। लाइव ट्रैकिंग जारी है!',
    },
    'inactivity_alert_title': {
      AppLanguage.tamil: 'செயலற்ற எச்சரிக்கை (5 நிமிடம் இயங்கவில்லை)',
      AppLanguage.english: 'Inactivity Alert (5 Mins Idle)',
      AppLanguage.hindi: 'निष्क्रियता चेतावनी (5 मिनट निष्क्रिय)',
    },
    'inactivity_time_prompt': {
      AppLanguage.tamil: 'தயவுசெய்து 30-40 வினாடிகளுக்குள் பதிலளிக்கவும் அல்லது கண்காணிப்பு டார்ச் தானாகவே பேருந்தில் உள்ள மற்றொரு பயணிக்கு அனுப்பப்படும்.',
      AppLanguage.english: 'Please reply within 30-40 seconds or the tracking torch will automatically pass to another onboard passenger.',
      AppLanguage.hindi: 'कृपया 30-40 सेकंड के भीतर उत्तर दें अन्यथा ट्रैकिंग टॉर्च स्वचालित रूप से अन्य यात्री को सौंप दी जाएगी।',
    },
    'simulation_protocol_sub': {
      AppLanguage.tamil: 'வழக்கமான சோதனை நெறிமுறை சிமுலேஷன்',
      AppLanguage.english: 'REGULAR CHECK PROTOCOL SIMULATION',
      AppLanguage.hindi: 'नियमित जांच प्रोटोकॉल सिमुलेशन',
    },
    'simulate_stationary_desc': {
      AppLanguage.tamil: 'பங்களிப்பாளர் 5 நிமிடங்கள் ஒரே இடத்தில் நிற்பது அல்லது பதில் சாளரத்தைத் தவறவிடுவதை உருவகப்படுத்துங்கள்:',
      AppLanguage.english: 'Simulate contributor remaining stationary for 5 minutes or missing response window:',
      AppLanguage.hindi: 'योगदानकर्ता के 5 मिनट तक स्थिर रहने या प्रतिक्रिया न देने का अनुकरण करें:',
    },
    'seconds_left': {
      AppLanguage.tamil: 'நொடிகள் மீதம்',
      AppLanguage.english: 's left',
      AppLanguage.hindi: 'सेकंड शेष',
    },
    'map_status_alert': {
      AppLanguage.tamil: 'எச்சரிக்கை',
      AppLanguage.english: 'ALERT',
      AppLanguage.hindi: 'अलर्ट',
    },
    'map_status_torch': {
      AppLanguage.tamil: 'டார்ச்',
      AppLanguage.english: 'TORCH',
      AppLanguage.hindi: 'टॉर्च',
    },
    'map_status_idle': {
      AppLanguage.tamil: 'செயலற்றது',
      AppLanguage.english: 'IDLE',
      AppLanguage.hindi: 'निष्क्रिय',
    },
    'map_status_live': {
      AppLanguage.tamil: 'நேரலை',
      AppLanguage.english: 'LIVE',
      AppLanguage.hindi: 'लाइव',
    },
    'map_msg_broken': {
      AppLanguage.tamil: 'அறிவிப்பு: பீளமேடு அருகில் பேருந்து பழுதானது · பயணிகள் எச்சரிக்கப்பட்டனர்',
      AppLanguage.english: 'BROADCAST: Bus Broke Down near Peelamedu · Commuters Alerted',
      AppLanguage.hindi: 'प्रसारण: पीलमेडू के पास बस खराब हुई · यात्री सतर्क',
    },
    'map_msg_torch': {
      AppLanguage.tamil: 'தொடர்ச்சி: பிரியா எஸ். (இருக்கை 14B)-உடன் டார்ச் செயலில் உள்ளது',
      AppLanguage.english: 'CONTINUOUS: Torch active with Priya S. (Seat 14B)',
      AppLanguage.hindi: 'निरंतर: प्रिया एस. (सीट 14B) के साथ टॉर्च सक्रिय है',
    },
    'map_msg_idle': {
      AppLanguage.tamil: 'செயலற்றது: பங்களிப்பாளர் 5நிமி அசையவில்லை · பதிலுக்காக காத்திருக்கிறது',
      AppLanguage.english: 'INACTIVITY: Contributor stationary 5m · Awaiting reply',
      AppLanguage.hindi: 'निष्क्रियता: योगदानकर्ता 5 मिनट स्थिर · उत्तर की प्रतीक्षा',
    },
    'map_msg_synced': {
      AppLanguage.tamil: 'வழித்தடம் 95 · பீளமேடு காரிடார் · ஜிபிஎஸ் ஒத்திசைக்கப்பட்டது',
      AppLanguage.english: 'Route 95 · Peelamedu Corridor · GPS Synced',
      AppLanguage.hindi: 'मार्ग 95 · पीलमेडू कॉरिडोर · जीपीएस समन्वयित',
    },
    'unresponsive_searching_p2': {
      AppLanguage.tamil: '1 நிமிடத்திற்குப் பிறகும் பங்களிப்பாளர் பதிலளிக்கவில்லை. வழித்தடம் 95-ல் மற்றொரு பயணியைத் தேடுகிறது...',
      AppLanguage.english: 'Contributor unresponsive after 1 minute. Searching for another passenger onboard Route 95...',
      AppLanguage.hindi: '1 मिनट बाद भी योगदानकर्ता ने उत्तर नहीं दिया। मार्ग 95 पर अन्य यात्री की तलाश...',
    },
    'snack_torch_approved': {
      AppLanguage.tamil: '🔥 டார்ச் அங்கீகரிக்கப்பட்டது! பிரியா எஸ். இப்போது செயலில் ஜிபிஎஸ் ஆயத்தொலைவுகளைப் பகிர்கிறார்.',
      AppLanguage.english: '🔥 Torch Approved! Priya S. is now actively sharing GPS coordinates.',
      AppLanguage.hindi: '🔥 टॉर्च स्वीकृत! प्रिया एस. अब सक्रिय रूप से जीपीएस निर्देशांक साझा कर रही हैं।',
    },
    'snack_network_resumed': {
      AppLanguage.tamil: 'நெட்வொர்க் மீண்டும் இணைக்கப்பட்டது · நேரலை கண்காணிப்பு மற்றும் EST பீளமேடு - நவ இந்தியாவில் பொருந்தியது!',
      AppLanguage.english: 'Network resumed · Live tracking and EST matched at Peelamedu - Nava India!',
      AppLanguage.hindi: 'नेटवर्क पुनः शुरू · पीलमेडू - नवा इंडिया पर लाइव ट्रैकिंग और ईएसटी मेल खाए!',
    },
    'snack_bus_breakdown': {
      AppLanguage.tamil: '🚨 பயணிகளுக்கு தகவல் தெரிவிக்கப்பட்டது: பீளமேடு அருகே பேருந்து பழுதானது. பயணிகள் எச்சரிக்கப்பட்டனர்!',
      AppLanguage.english: '🚨 Passengers informed: Bus broke down near Peelamedu. Commuters notified!',
      AppLanguage.hindi: '🚨 यात्रियों को सूचित किया गया: पीलमेडू के पास बस खराब हुई। यात्री सतर्क!',
    },
    'snack_normal_delay': {
      AppLanguage.tamil: '✅ சரிபார்க்கப்பட்டது: வழக்கமான தாமதம் / போக்குவரத்து நெரிசல். ஜிபிஎஸ் கண்காணிப்பு தொடர்கிறது.',
      AppLanguage.english: '✅ Verified: Normal delay / traffic jam. GPS tracking continues.',
      AppLanguage.hindi: '✅ सत्यापित: सामान्य देरी / ट्रैफिक जाम। जीपीएस ट्रैकिंग जारी है।',
    },
    'snack_no_reply_torch_passed': {
      AppLanguage.tamil: '🔥 பதில் கிடைக்கவில்லை. கண்காணிப்பைத் தொடர டார்ச் பிரியா எஸ். (இருக்கை 14B)-க்கு மாற்றப்பட்டது!',
      AppLanguage.english: '🔥 No reply received. Torch passed to Priya S. (Seat 14B) to continue tracking!',
      AppLanguage.hindi: '🔥 कोई जवाब नहीं मिला। ट्रैकिंग जारी रखने के लिए टॉर्च प्रिया एस. (सीट 14B) को सौंपी गई!',
    },
    'sharing_active_snack': {
      AppLanguage.tamil: 'வழக்கமான சோதனைகளில் இருப்பிடப் பகிர்வு செயலில் உள்ளது!',
      AppLanguage.english: 'Location sharing active in Regular Checks!',
      AppLanguage.hindi: 'नियमित जांच में स्थान साझाकरण सक्रिय है!',
    },
    'location_sharing_active_stream': {
      AppLanguage.tamil: 'இருப்பிடப் பகிர்வு செயலில் உள்ளது! பயணிகளுக்கு ஜிபிஎஸ் ஸ்ட்ரீமிங் செய்யப்படுகிறது...',
      AppLanguage.english: 'Location sharing active! Streaming GPS to passengers...',
      AppLanguage.hindi: 'स्थान साझाकरण सक्रिय है! यात्रियों को जीपीएस स्ट्रीम किया जा रहा है...',
    },
    'sharing_live_gps': {
      AppLanguage.tamil: 'நேரலை ஜிபிஎஸ் பகிர்வு',
      AppLanguage.english: 'Sharing Live GPS',
      AppLanguage.hindi: 'लाइव जीपीएस साझाकरण',
    },
    'location_not_valid': {
      AppLanguage.tamil: 'இருப்பிடம் செல்லுபடியாகாது',
      AppLanguage.english: 'LOCATION NOT VALID',
      AppLanguage.hindi: 'स्थान मान्य नहीं है',
    },
    'location_check_failed': {
      AppLanguage.tamil: 'இருப்பிட சோதனை தோல்வியடைந்தது',
      AppLanguage.english: 'Location Check Failed',
      AppLanguage.hindi: 'स्थान जांच विफल',
    },
    'location_mismatch_desc': {
      AppLanguage.tamil: 'நீங்கள் சரியான இடத்தில் இல்லை அல்லது பகிர்ந்த இடத்தில் இல்லை. உங்களால் ஜிபிஎஸ் பகிர முடியாது.',
      AppLanguage.english: "You are not in a valid location or you are not in the location you shared. You can't share GPS.",
      AppLanguage.hindi: 'आप किसी मान्य स्थान पर नहीं हैं या उस स्थान पर नहीं हैं जिसे आपने साझा किया है। आप जीपीएस साझा नहीं कर सकते।',
    },
    'route_corridor': {
      AppLanguage.tamil: 'வழித்தட காரிடார்:',
      AppLanguage.english: 'Route Corridor:',
      AppLanguage.hindi: 'मार्ग कॉरिडोर:',
    },
    'current_device_location': {
      AppLanguage.tamil: 'தற்போதைய சாதன இருப்பிடம்:',
      AppLanguage.english: 'Current Device Location:',
      AppLanguage.hindi: 'वर्तमान उपकरण स्थान:',
    },
    'out_of_transit_bounds': {
      AppLanguage.tamil: 'போக்குவரத்து எல்லைக்கு வெளியே',
      AppLanguage.english: 'Out of Transit Bounds',
      AppLanguage.hindi: 'पारगमन सीमा से बाहर',
    },
    'gps_stream_status': {
      AppLanguage.tamil: 'ஜிபிஎஸ் ஸ்ட்ரீம் நிலை:',
      AppLanguage.english: 'GPS Stream Status:',
      AppLanguage.hindi: 'जीपीएस स्ट्रीम स्थिति:',
    },
    'terminated_status': {
      AppLanguage.tamil: 'நிறுத்தப்பட்டது 🚫',
      AppLanguage.english: 'Terminated 🚫',
      AppLanguage.hindi: 'समाप्त 🚫',
    },
    'return_to_routes': {
      AppLanguage.tamil: 'வழித்தடங்களுக்கு திரும்பு',
      AppLanguage.english: 'Return to Routes',
      AppLanguage.hindi: 'मार्गों पर वापस लौटें',
    },
    'complete_bus_journey_title': {
      AppLanguage.tamil: 'பேருந்து பயணத்தை முடிக்கவா?',
      AppLanguage.english: 'Complete Bus Journey?',
      AppLanguage.hindi: 'बस यात्रा पूरी करें?',
    },
    'complete_bus_journey_desc': {
      AppLanguage.tamil: 'இது உங்கள் ஜிபிஎஸ் பங்களிப்பை நிறுத்தி, பயணித்த தூரத்தைச் சரிபார்த்து, வெகுமதிப் புள்ளிகளை வழங்கும்.',
      AppLanguage.english: 'This will stop your GPS contribution, verify your travel distance, and award your community reward points.',
      AppLanguage.hindi: 'यह आपके जीपीएस योगदान को रोक देगा, आपकी यात्रा दूरी को सत्यापित करेगा और अंक प्रदान करेगा।',
    },
    'continue_sharing_btn': {
      AppLanguage.tamil: 'பகிர்வதைத் தொடரவும்',
      AppLanguage.english: 'Continue Sharing',
      AppLanguage.hindi: 'साझा करना जारी रखें',
    },
    'stop_claim_points_btn': {
      AppLanguage.tamil: 'நிறுத்தி புள்ளிகளைப் பெறுக',
      AppLanguage.english: 'Stop & Claim Points',
      AppLanguage.hindi: 'रोकें और अंक प्राप्त करें',
    },
    'points_awarded_title': {
      AppLanguage.tamil: 'புள்ளிகள் வழங்கப்பட்டன!',
      AppLanguage.english: 'Points Awarded!',
      AppLanguage.hindi: 'अंक प्रदान किए गए!',
    },
    'points_earned_label': {
      AppLanguage.tamil: 'புள்ளிகள் பெறப்பட்டன',
      AppLanguage.english: 'Points Earned',
      AppLanguage.hindi: 'अंक अर्जित',
    },
    'total_balance_label': {
      AppLanguage.tamil: 'மொத்த இருப்பு:',
      AppLanguage.english: 'Total Balance:',
      AppLanguage.hindi: 'कुल शेष:',
    },
    'target_reached_scratch': {
      AppLanguage.tamil: 'இலக்கு எட்டப்பட்டது! உத்தரவாதமான ஸ்கிராட்ச் கார்டு தயார்.',
      AppLanguage.english: 'Target Reached! Guaranteed Scratch Card is now ready.',
      AppLanguage.hindi: 'लक्ष्य पूरा हुआ! गारंटीकृत स्क्रैच कार्ड अब तैयार है।',
    },
    'open_rewards_scratch_btn': {
      AppLanguage.tamil: 'ரிவார்ட்ஸ் & ஸ்கிராட்ச் கார்டைத் திறக்கவும்',
      AppLanguage.english: 'Open Rewards & Scratch Card',
      AppLanguage.hindi: 'रिवार्ड्स और स्क्रैच कार्ड खोलें',
    },
    'contribution_broadcast_active': {
      AppLanguage.tamil: 'பங்களிப்பு ஒளிபரப்பு செயலில் உள்ளது',
      AppLanguage.english: 'CONTRIBUTION BROADCAST ACTIVE',
      AppLanguage.hindi: 'योगदान प्रसारण सक्रिय है',
    },
    'active_transmitting_sub': {
      AppLanguage.tamil: 'இந்த வழித்தடத்தில் காத்திருக்கும் பயணிகளுக்கு உதவ உங்கள் ஸ்மார்ட்போன் போக்குவரத்து ஆயத்தொலைவுகளை தீவிரமாக அனுப்புகிறது.',
      AppLanguage.english: 'Your smartphone is actively transmitting transit coordinates to assist passengers waiting along this route.',
      AppLanguage.hindi: 'इस मार्ग पर प्रतीक्षा कर रहे यात्रियों की सहायता के लिए आपका स्मार्टफोन पारगमन निर्देशांक प्रसारित कर रहा है।',
    },
    'verified_on_bus': {
      AppLanguage.tamil: '● பேருந்தில் சரிபார்க்கப்பட்டது',
      AppLanguage.english: '● VERIFIED ON-BUS',
      AppLanguage.hindi: '● बस में सत्यापित',
    },
    'label_distance': {
      AppLanguage.tamil: 'தூரம்',
      AppLanguage.english: 'DISTANCE',
      AppLanguage.hindi: 'दूरी',
    },
    'label_gps_records': {
      AppLanguage.tamil: 'ஜிபிஎஸ் பதிவுகள்',
      AppLanguage.english: 'GPS RECORDS',
      AppLanguage.hindi: 'जीपीएस रिकॉर्ड',
    },
    'label_points': {
      AppLanguage.tamil: 'புள்ளிகள்',
      AppLanguage.english: 'POINTS',
      AppLanguage.hindi: 'अंक',
    },
    'label_min_distance': {
      AppLanguage.tamil: 'குறைந்தது: 0.5 கி.மீ',
      AppLanguage.english: 'Min: 0.5 km',
      AppLanguage.hindi: 'न्यूनतम: 0.5 किमी',
    },
    'label_sent': {
      AppLanguage.tamil: 'அனுப்பப்பட்டது',
      AppLanguage.english: 'sent',
      AppLanguage.hindi: 'भेजे गए',
    },
    'label_accuracy': {
      AppLanguage.tamil: 'துல்லியம்: ±6மீ',
      AppLanguage.english: 'Accuracy: ±6m',
      AppLanguage.hindi: 'सटीकता: ±6मी',
    },
    'label_guaranteed': {
      AppLanguage.tamil: 'உத்தரவாதம்',
      AppLanguage.english: 'Guaranteed',
      AppLanguage.hindi: 'गारंटीकृत',
    },
  };
}
