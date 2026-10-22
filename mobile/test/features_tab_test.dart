import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trava/features/features/features_tab.dart';
import 'package:trava/services/api_service.dart';

void main() {
  setUp(() async {
    final api = ApiService();
    api.setNoNetMode(false);
  });

  testWidgets('FeaturesTab displays both sub-sections and executes Pass the Torch handoff', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesTab(initialSubSection: FeaturesSubSection.passTheTorch),
      ),
    );
    await tester.pumpAndSettle();

    // Verify sub-section pills are present
    expect(find.text('🔥 Pass the Torch'), findsOneWidget);
    expect(find.text('📡 Offline GPS'), findsOneWidget);
    expect(find.text('⏱️ Regular Checks'), findsOneWidget);

    // Verify Configure Your Journey form is displayed initially
    expect(find.text('CONFIGURE YOUR JOURNEY'), findsOneWidget);
    expect(find.text('Transit Route'), findsOneWidget);
    expect(find.text('Which bus are you travelling on?'), findsOneWidget);
    expect(find.text('Boarding Stop'), findsOneWidget);
    expect(find.text('Intended Destination Stop'), findsOneWidget);
    expect(find.text('Share Location'), findsOneWidget);

    // Tap Share Location to activate GPS sharing
    await tester.tap(find.text('Share Location'));
    await tester.pumpAndSettle();

    // Verify Passenger #1 Sam is sharing
    expect(find.text('Passenger #1: Sam (You)'), findsOneWidget);
    expect(find.text('Stop Sharing GPS (Simulate Alighting)'), findsOneWidget);

    // Tap Stop Sharing GPS
    await tester.tap(find.text('Stop Sharing GPS (Simulate Alighting)'));
    await tester.pump();

    // Verify scanning state
    expect(find.text('Scanning Bus Cabin...'), findsOneWidget);

    // Advance 2 seconds to let scan finish
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Verify Passenger #2 Priya S. is found
    expect(find.text('Priya S. · Seat 14B'), findsOneWidget);
    expect(find.text('🤝 Approve & Accept Torch (Passenger #2)'), findsOneWidget);

    // Tap the Approval Button
    await tester.tap(find.text('🤝 Approve & Accept Torch (Passenger #2)'));
    await tester.pumpAndSettle();

    // Verify Torch Successfully Passed
    expect(find.text('Torch Successfully Passed!'), findsOneWidget);
    expect(find.text('Reset Handoff Simulation'), findsOneWidget);
  });

  testWidgets('FeaturesTab switches to Offline GPS Sharing and shows No Net Mode controls', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesTab(initialSubSection: FeaturesSubSection.offlineGps),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline GPS Sharing'), findsOneWidget);
    expect(find.text('No Net Mode'), findsOneWidget);
    expect(find.text('Local GPS Record Queue'), findsOneWidget);
    expect(find.text('Timestamp Reconciliation Protocol'), findsOneWidget);
    expect(find.text('Simulate No Net Mode (15s EST Tracking & Buffer)'), findsOneWidget);

    // Tap Simulate No Net Mode to trigger 15s EST tracking
    await tester.tap(find.text('Simulate No Net Mode (15s EST Tracking & Buffer)'));
    await tester.pump();

    // Verify EST tracking mode is visible
    expect(find.text('EST · Estimated Tracking Mode'), findsOneWidget);

    // Fast-forward 16 seconds to complete simulation
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();

    // Verify live tracking resumes and reconciles
    expect(find.text('LIVE · Verified Tracking Mode'), findsOneWidget);
    expect(find.text('Network resumed! Live tracking verified: bus reached midpoint between Peelamedu and Nava India.'), findsOneWidget);
  });

  testWidgets('FeaturesTab Regular Checks handles 5m idle and breakdown broadcast', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesTab(initialSubSection: FeaturesSubSection.regularChecks),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Regular Checks section header & form
    expect(find.text('Regular Checks'), findsWidgets);
    expect(find.text('CONFIGURE YOUR JOURNEY'), findsOneWidget);
    expect(find.text('Share Location'), findsOneWidget);

    // Start sharing location in Regular Checks
    await tester.tap(find.text('Share Location'));
    await tester.pumpAndSettle();

    // Verify active sharing & simulation buttons
    expect(find.text('Passenger #1: Sam (You)'), findsOneWidget);
    expect(find.text('Assume that the location is idle for 5 minutes'), findsOneWidget);
    expect(find.text('No reply in 1 minute'), findsOneWidget);

    // Click Assume that the location is idle for 5 minutes
    await tester.tap(find.text('Assume that the location is idle for 5 minutes'));
    await tester.pumpAndSettle();

    // Verify pop-up alert content
    expect(find.text('Your location is idle for 5 minutes. Is there any problem? Is the bus breakdown or what?'), findsOneWidget);
    expect(find.text('Yes, the bus broke down'), findsOneWidget);
    expect(find.text('No, normal delay / traffic jam'), findsOneWidget);

    // Click Yes, the bus broke down
    await tester.tap(find.text('Yes, the bus broke down'));
    await tester.pumpAndSettle();

    // Verify passengers are informed of breakdown
    expect(find.text('🚨 PASSENGERS INFORMED: BUS BROKE DOWN'), findsOneWidget);
  });

  testWidgets('FeaturesTab Regular Checks handles No reply in 1 minute with automatic torch handoff', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: FeaturesTab(initialSubSection: FeaturesSubSection.regularChecks),
      ),
    );
    await tester.pumpAndSettle();

    // Start sharing location in Regular Checks
    await tester.tap(find.text('Share Location'));
    await tester.pumpAndSettle();

    // Click No reply in 1 minute
    await tester.tap(find.text('No reply in 1 minute'));
    await tester.pump();

    // Verify cabin scan triggers
    expect(find.text('Scanning Bus Cabin...'), findsOneWidget);

    // Fast forward scan
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Verify torch is passed to Priya S.
    expect(find.text('🔥 Torch Passed to Priya S. (Seat 14B)!'), findsOneWidget);
  });
}
