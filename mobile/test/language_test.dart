import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trava/services/language_service.dart';
import 'package:trava/features/common/language_selector_sheet.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final langService = LanguageService();
    await langService.setLanguage(AppLanguage.english);
  });

  test('LanguageService supports 3 regional languages in requested priority order', () {
    // 1. Tamil (First)
    // 2. English (Second)
    // 3. Hindi (Third)
    expect(AppLanguage.values.length, 3);
    expect(AppLanguage.values[0], AppLanguage.tamil);
    expect(AppLanguage.values[1], AppLanguage.english);
    expect(AppLanguage.values[2], AppLanguage.hindi);

    expect(AppLanguage.tamil.nativeName, 'தமிழ்');
    expect(AppLanguage.english.nativeName, 'English');
    expect(AppLanguage.hindi.nativeName, 'हिन्दी');
  });

  test('LanguageService translates keys across Tamil, English, and Hindi', () async {
    final lang = LanguageService();

    // English
    await lang.setLanguage(AppLanguage.english);
    expect(lang.tr('nav_home'), 'Home');
    expect(lang.tr('nav_track_bus'), 'Track Bus');
    expect(lang.tr('greeting_vanakkam'), 'Vanakkam');

    // Tamil (First)
    await lang.setLanguage(AppLanguage.tamil);
    expect(lang.tr('nav_home'), 'முகப்பு');
    expect(lang.tr('nav_track_bus'), 'பேருந்து வரைபடம்');
    expect(lang.tr('greeting_vanakkam'), 'வணக்கம்');

    // Hindi (Third)
    await lang.setLanguage(AppLanguage.hindi);
    expect(lang.tr('nav_home'), 'होम');
    expect(lang.tr('nav_track_bus'), 'बस ट्रैक');
    expect(lang.tr('greeting_vanakkam'), 'नमस्ते');
  });

  testWidgets('RegionalLanguagesCard renders all 3 language options interactively', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RegionalLanguagesCard(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 3 languages are displayed
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);

    // Switch to Tamil by tapping Tamil pill
    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();

    expect(LanguageService().currentLanguage, AppLanguage.tamil);

    // Switch to Hindi by tapping Hindi pill
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();

    expect(LanguageService().currentLanguage, AppLanguage.hindi);

    // Reset back to English
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(LanguageService().currentLanguage, AppLanguage.english);
  });

  test('LanguageService translates routes, bus stops, and bus services across all 3 languages', () async {
    final lang = LanguageService();

    // 1. Tamil Mode
    await lang.setLanguage(AppLanguage.tamil);
    expect(lang.translateRoute('Gandhipuram ↔ Singanallur (via Peelamedu)'),
        'காந்திபுரம் ↔ சிங்காநல்லூர் (பீளமேடு வழியாக)');
    expect(lang.translateRoute('Gandhipuram ↔ Ukkadam (via Railway Station)'),
        'காந்திபுரம் ↔ உக்கடம் (ரயில் நிலையம் வழியாக)');
    expect(lang.translateStop('Gandhipuram Central Bus Stand'), 'காந்திபுரம் மத்திய பேருந்து நிலையம்');
    expect(lang.translateStop('Lakshmi Mills Junction'), 'லட்சுமி மில்ஸ் சந்திப்பு');
    expect(lang.translateStop('Peelamedu Bus Stop'), 'பீளமேடு பேருந்து நிறுத்தம்');
    expect(lang.translateBus('TNSTC — Green Express'), 'TNSTC — கிரீன் எக்ஸ்பிரஸ்');
    expect(lang.tr('regular_checks_title'), 'வழக்கமான சோதனைகள்');
    expect(lang.tr('broken_down_badge'), 'பழுதடைந்தது');

    // 2. Hindi Mode
    await lang.setLanguage(AppLanguage.hindi);
    expect(lang.translateRoute('Gandhipuram ↔ Singanallur (via Peelamedu)'),
        'गांधीपुरम ↔ सिंगानल्लूर (पीलमेडू होकर)');
    expect(lang.translateRoute('Gandhipuram ↔ Ukkadam (via Railway Station)'),
        'गांधीपुरम ↔ उक्कड़म (रेलवे स्टेशन होकर)');
    expect(lang.translateStop('Gandhipuram Central Bus Stand'), 'गांधीपुरम सेंट्रल बस स्टैंड');
    expect(lang.translateStop('Lakshmi Mills Junction'), 'लक्ष्मी मिल्स जंक्शन');
    expect(lang.translateStop('Peelamedu Bus Stop'), 'पीलमेडू बस स्टॉप');
    expect(lang.translateBus('TNSTC — Green Express'), 'TNSTC — ग्रीन एक्सप्रेस');
    expect(lang.tr('regular_checks_title'), 'नियमित जांच');
    expect(lang.tr('broken_down_badge'), 'खराब हो गई');

    // 3. English Mode
    await lang.setLanguage(AppLanguage.english);
    expect(lang.translateRoute('Gandhipuram ↔ Singanallur (via Peelamedu)'),
        'Gandhipuram ↔ Singanallur (via Peelamedu)');
    expect(lang.translateStop('Gandhipuram Central Bus Stand'), 'Gandhipuram Central Bus Stand');
    expect(lang.translateBus('TNSTC — Green Express'), 'TNSTC — Green Express');
    expect(lang.tr('regular_checks_title'), 'Regular Checks');
    expect(lang.tr('broken_down_badge'), 'BROKEN DOWN');
  });
}
