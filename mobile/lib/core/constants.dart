class AppConstants {
  static const String appName = 'TRAVA';
  static const String tagline = "People Solving People's Problem.";
  static const String subtitle = 'Know Where Your Bus Is, on Every Route.';
  static const String demoCity = 'Coimbatore, Tamil Nadu, India';

  // Demo Route Config
  static const String defaultRouteNumber = '95';
  static const String defaultRouteName = 'Gandhipuram - Singanallur via Peelamedu';
  static const String defaultOrigin = 'Gandhipuram';
  static const String defaultDestination = 'Singanallur';

  // Backend API URL (Production Render URL with fallback)
  static String defaultBaseUrl = 'https://trava-app-backend.onrender.com/api/v1';

  // Demo Mode Badge text
  static const String demoBadgeText = 'DEMO MODE · SIMULATED GPS';
  static const String mockVerificationBadgeText = 'DEMO MODE · MOCK VERIFICATION';
}
