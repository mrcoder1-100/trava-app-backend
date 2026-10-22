import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/theme.dart';
import '../../models/bus_route.dart';
import '../../models/bus_service.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../common/language_selector_sheet.dart';

enum FeaturesSubSection {
  passTheTorch,
  offlineGps,
  regularChecks,
}

class FeaturesTab extends StatefulWidget {
  final FeaturesSubSection initialSubSection;
  final Function(int)? onNavigateTab;

  const FeaturesTab({
    super.key,
    this.initialSubSection = FeaturesSubSection.passTheTorch,
    this.onNavigateTab,
  });

  @override
  State<FeaturesTab> createState() => _FeaturesTabState();
}

class _FeaturesTabState extends State<FeaturesTab> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final LanguageService _langService = LanguageService();
  late FeaturesSubSection _activeSubSection;

  // --- Sub-section 1: Pass the Torch State ---
  bool _isActivelySharing = false;
  bool _isScanningForPassenger = false;
  bool _passenger2Found = false;
  bool _torchAcceptedByPassenger2 = false;
  bool _isApproving = false;

  // Transit Route & Bus selection for Pass the Torch
  List<BusRouteModel> _routes = [];
  List<BusServiceModel> _buses = [];
  String _selectedRouteId = 'route_95';
  String _selectedBusId = 'bus_95_a';
  String _selectedBoardingStopId = 'stop_gandhipuram';
  String _selectedDestinationStopId = 'stop_singanallur';

  static final BusRouteModel _fallbackRoute = BusRouteModel(
    id: 'route_95',
    routeNumber: '95',
    name: 'Gandhipuram ↔ Singanallur (via Peelamedu)',
    city: 'Coimbatore',
    origin: 'Gandhipuram',
    destination: 'Singanallur',
    distanceKm: 9.8,
    estimatedDurationMinutes: 32,
    stops: [
      StopModel(id: 'stop_gandhipuram', name: 'Gandhipuram Central Bus Stand', shortName: 'Gandhipuram', sequence: 1, latitude: 11.016844, longitude: 76.967812, isMajorJunction: true),
      StopModel(id: 'stop_lakshmi_mills', name: 'Lakshmi Mills Junction', shortName: 'Lakshmi Mills', sequence: 2, latitude: 11.018500, longitude: 76.961200, isMajorJunction: true),
      StopModel(id: 'stop_nava_india', name: 'Nava India Bus Stop', shortName: 'Nava India', sequence: 3, latitude: 11.020500, longitude: 76.967000, isMajorJunction: false),
      StopModel(id: 'stop_peelamedu', name: 'Peelamedu Bus Stand', shortName: 'Peelamedu', sequence: 4, latitude: 11.023500, longitude: 76.974000, isMajorJunction: true),
      StopModel(id: 'stop_singanallur', name: 'Singanallur Bus Terminus', shortName: 'Singanallur', sequence: 5, latitude: 10.998055, longitude: 77.032011, isMajorJunction: true),
    ],
    direction: 'OUTBOUND',
  );

  static final BusServiceModel _fallbackBus = BusServiceModel(
    id: 'bus_95_a',
    busNumber: 'TNSTC — Green Express',
    vehicleReg: 'TN 38 N 2481',
    routeId: 'route_95',
    direction: 'OUTBOUND',
    crowdStatus: 'MODERATE',
    trackingStatus: 'LIVE_CONTRIBUTOR',
    locationFreshness: 'LIVE',
    isSimulated: true,
    currentProgress: 0.35,
    speedKmH: 28,
    currentStopId: 'stop_gandhipuram',
    nextStopId: 'stop_lakshmi_mills',
    currentLatitude: 11.016844,
    currentLongitude: 76.967812,
    bearing: 45,
    etaMinutes: 10,
    distanceRemainingKm: 6.2,
  );

  BusRouteModel get _currentRoute {
    return _routes.firstWhere(
      (r) => r.id == _selectedRouteId,
      orElse: () => _routes.isNotEmpty ? _routes.first : _fallbackRoute,
    );
  }

  BusServiceModel get _currentBus {
    return _buses.firstWhere(
      (b) => b.id == _selectedBusId,
      orElse: () => _buses.isNotEmpty ? _buses.first : _fallbackBus,
    );
  }

  StopModel get _currentBoardingStop {
    final route = _currentRoute;
    return route.stops.firstWhere(
      (s) => s.id == _selectedBoardingStopId,
      orElse: () => route.stops.isNotEmpty ? route.stops.first : _fallbackRoute.stops.first,
    );
  }

  StopModel get _currentDestinationStop {
    final route = _currentRoute;
    return route.stops.firstWhere(
      (s) => s.id == _selectedDestinationStopId,
      orElse: () => route.stops.isNotEmpty ? route.stops.last : _fallbackRoute.stops.last,
    );
  }

  // --- Sub-section 2: Offline GPS Sharing State ---
  final MapController _mapController = MapController();
  bool _isOfflineSimulating = false;
  int _countdownSeconds = 15;
  Timer? _countdownTimer;
  String? _resumedNotificationMessage;
  bool _showResumedNotification = false;

  // Map Coordinates for Route 95 (Avinashi Road Corridor)
  final List<ll.LatLng> _routePoints = const [
    ll.LatLng(11.0168, 76.9558), // Gandhipuram
    ll.LatLng(11.0185, 76.9612), // Lakshmi Mills
    ll.LatLng(11.0205, 76.9670), // Nava India
    ll.LatLng(11.0235, 76.9740), // Peelamedu
    ll.LatLng(11.0270, 76.9810), // PSG Tech
    ll.LatLng(11.0310, 76.9890), // SITRA
  ];

  // Bus positions
  ll.LatLng _currentBusPos = const ll.LatLng(11.0235, 76.9740); // Pre-pause (At Peelamedu)
  final ll.LatLng _initialBusPos = const ll.LatLng(11.0235, 76.9740); // Peelamedu
  final ll.LatLng _reconciledBusPos = const ll.LatLng(11.0220, 76.9705); // In the middle of Peelamedu & Nava India

  // Queued records during offline mode
  final List<Map<String, dynamic>> _offlinePings = [];

  // --- Sub-section 3: Regular Checks State ---
  final MapController _rcMapController = MapController();
  bool _rcIsActivelySharing = false;
  bool _rcIsIdle5Min = false;
  int _rcCountdownSeconds = 35;
  Timer? _rcCountdownTimer;
  bool _rcIsBusBrokenDown = false;
  bool _rcIsScanningPassenger = false;
  bool _rcTorchPassed = false;
  final ll.LatLng _rcBusPos = const ll.LatLng(11.0235, 76.9740); // Near Peelamedu

  @override
  void initState() {
    super.initState();
    _activeSubSection = widget.initialSubSection;
    _api.addListener(_onApiStateChanged);
    _loadTransitData();

    // If already in No Net Mode when entering this portal, start offline simulation
    if (_api.isNoNetMode && _activeSubSection == FeaturesSubSection.offlineGps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startOfflineSimulation();
      });
    }
  }

  Future<void> _loadTransitData() async {
    final routes = await _api.getRoutes();
    final buses = await _api.getRouteBuses(_selectedRouteId);
    if (mounted) {
      setState(() {
        if (routes.isNotEmpty) {
          _routes = routes;
          final r = routes.firstWhere((r) => r.id == _selectedRouteId, orElse: () => routes.first);
          _selectedRouteId = r.id;
          if (r.stops.isNotEmpty) {
            _selectedBoardingStopId = r.stops.first.id;
            _selectedDestinationStopId = r.stops.last.id;
          }
        }
        if (buses.isNotEmpty) {
          _buses = buses;
          _selectedBusId = buses.first.id;
        }
      });
    }
  }

  Future<void> _onRouteChanged(String newRouteId) async {
    setState(() {
      _selectedRouteId = newRouteId;
    });
    final buses = await _api.getRouteBuses(newRouteId);
    if (mounted) {
      setState(() {
        _buses = buses;
        if (buses.isNotEmpty) {
          _selectedBusId = buses.first.id;
        }
        final r = _routes.firstWhere((r) => r.id == newRouteId, orElse: () => _fallbackRoute);
        if (r.stops.isNotEmpty) {
          _selectedBoardingStopId = r.stops.first.id;
          _selectedDestinationStopId = r.stops.last.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _api.removeListener(_onApiStateChanged);
    _countdownTimer?.cancel();
    _rcCountdownTimer?.cancel();
    super.dispose();
  }

  void _onApiStateChanged() {
    if (mounted) {
      if (_api.isNoNetMode && !_isOfflineSimulating && _activeSubSection == FeaturesSubSection.offlineGps) {
        _startOfflineSimulation();
      }
      setState(() {});
    }
  }

  // --- Pass the Torch Handlers ---

  void _handleStartSharingLocation() {
    setState(() {
      _isActivelySharing = true;
      _isScanningForPassenger = false;
      _passenger2Found = false;
      _torchAcceptedByPassenger2 = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share_location, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _langService.tr('location_sharing_active_stream'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F4C3A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleTurnOffSharing() {
    setState(() {
      _isActivelySharing = false;
      _isScanningForPassenger = true;
      _passenger2Found = false;
      _torchAcceptedByPassenger2 = false;
    });

    // Simulate scanning bus cabin for 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isScanningForPassenger = false;
          _passenger2Found = true;
        });
      }
    });
  }

  Future<void> _handleApproveTorch() async {
    setState(() {
      _isApproving = true;
    });

    // Notify backend
    await _api.triggerPassTheTorch(busId: _selectedBusId);

    if (mounted) {
      setState(() {
        _isApproving = false;
        _torchAcceptedByPassenger2 = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_langService.tr('snack_torch_approved')),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetPassTheTorch() {
    setState(() {
      _isActivelySharing = false;
      _isScanningForPassenger = false;
      _passenger2Found = false;
      _torchAcceptedByPassenger2 = false;
    });
  }

  // --- Offline GPS Sharing Handlers ---

  void _toggleNoNetMode(bool value) {
    _api.setNoNetMode(value);
    if (value) {
      _startOfflineSimulation();
    } else {
      _countdownTimer?.cancel();
      setState(() {
        _isOfflineSimulating = false;
      });
    }
  }

  void _startOfflineSimulation() {
    _countdownTimer?.cancel();
    setState(() {
      _isOfflineSimulating = true;
      _countdownSeconds = 15;
      _showResumedNotification = false;
      _currentBusPos = _initialBusPos; // Starts at Peelamedu
      _offlinePings.clear();
    });

    // Keep map camera focused at the Peelamedu - Nava India corridor
    try {
      _mapController.move(const ll.LatLng(11.0220, 76.9705), 14.8);
    } catch (_) {}

    // Queue simulated sensor pings across 15 seconds from Peelamedu towards Nava India
    final samplePings = [
      {'ping': 1, 'lat': 11.0232, 'lng': 76.9733, 'sec': 3},
      {'ping': 2, 'lat': 11.0229, 'lng': 76.9726, 'sec': 6},
      {'ping': 3, 'lat': 11.0226, 'lng': 76.9719, 'sec': 9},
      {'ping': 4, 'lat': 11.0223, 'lng': 76.9712, 'sec': 12},
      {'ping': 5, 'lat': 11.0220, 'lng': 76.9705, 'sec': 15},
    ];

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdownSeconds--;

        // Calculate smooth progress along the path from Peelamedu to midpoint (0.0 -> 1.0)
        final elapsed = 15 - _countdownSeconds;
        final progress = (elapsed / 15.0).clamp(0.0, 1.0);

        // Move the bus slowly in EST mode towards the middle of Peelamedu & Nava India
        final lat = _initialBusPos.latitude + (_reconciledBusPos.latitude - _initialBusPos.latitude) * progress;
        final lng = _initialBusPos.longitude + (_reconciledBusPos.longitude - _initialBusPos.longitude) * progress;
        _currentBusPos = ll.LatLng(lat, lng);

        // Check if we need to add a ping to local storage queue
        for (final sp in samplePings) {
          if (sp['sec'] == elapsed && !_offlinePings.any((p) => p['ping'] == sp['ping'])) {
            final now = DateTime.now().subtract(Duration(seconds: _countdownSeconds));
            final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
            _offlinePings.add({
              'ping': sp['ping'],
              'lat': sp['lat'],
              'lng': sp['lng'],
              'time': timeStr,
              'status': 'QUEUED LOCALLY',
            });
          }
        }
      });

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _finishOfflineSimulation();
      }
    });
  }

  void _finishOfflineSimulation() {
    // Automatically turn off No Net Mode
    _api.setNoNetMode(false);

    setState(() {
      _isOfflineSimulating = false;
      // Authoritative live position matches the EST final position (midpoint of Peelamedu & Nava India)
      _currentBusPos = _reconciledBusPos;
      _showResumedNotification = true;
      _resumedNotificationMessage =
          'Network resumed! Live tracking verified: bus reached midpoint between Peelamedu and Nava India.';

      // Update ping statuses to synced
      for (final p in _offlinePings) {
        p['status'] = 'SYNCED & RECONCILED';
      }
    });

    // Keep map camera at the exact corridor view
    try {
      _mapController.move(const ll.LatLng(11.0220, 76.9705), 14.8);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_langService.tr('snack_network_resumed')),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --- Regular Checks Handlers ---

  void _rcHandleStartSharingLocation() {
    setState(() {
      _rcIsActivelySharing = true;
      _rcIsIdle5Min = false;
      _rcIsBusBrokenDown = false;
      _rcIsScanningPassenger = false;
      _rcTorchPassed = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share_location, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _langService.tr('sharing_active_snack'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F4C3A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _rcHandleAssumeIdle5Min() {
    _rcCountdownTimer?.cancel();
    setState(() {
      _rcIsIdle5Min = true;
      _rcIsBusBrokenDown = false;
      _rcIsScanningPassenger = false;
      _rcTorchPassed = false;
      _rcCountdownSeconds = 35;
    });

    _rcCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _rcCountdownSeconds--;
      });
      if (_rcCountdownSeconds <= 0) {
        timer.cancel();
        _rcHandleNoReplyTimeout();
      }
    });
  }

  void _rcHandleBusBreakdown() {
    _rcCountdownTimer?.cancel();
    setState(() {
      _rcIsIdle5Min = false;
      _rcIsBusBrokenDown = true;
      _rcTorchPassed = false;
      _rcIsScanningPassenger = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_langService.tr('snack_bus_breakdown')),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _rcHandleNormalTraffic() {
    _rcCountdownTimer?.cancel();
    setState(() {
      _rcIsIdle5Min = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_langService.tr('snack_normal_delay')),
        backgroundColor: AppTheme.emerald,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _rcHandleNoReplyTimeout() {
    _rcCountdownTimer?.cancel();
    setState(() {
      _rcIsIdle5Min = false;
      _rcIsScanningPassenger = true;
    });

    // Simulate scanning bus cabin for 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _rcIsScanningPassenger = false;
          _rcTorchPassed = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_langService.tr('snack_no_reply_torch_passed')),
            backgroundColor: AppTheme.emerald,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _rcReset() {
    _rcCountdownTimer?.cancel();
    setState(() {
      _rcIsActivelySharing = false;
      _rcIsIdle5Min = false;
      _rcIsBusBrokenDown = false;
      _rcIsScanningPassenger = false;
      _rcTorchPassed = false;
      _rcCountdownSeconds = 35;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text(
          _langService.tr('nav_features'),
          style: const TextStyle(fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: QuickLanguagePill(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Feature Sub-section Switcher (Pill Style)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeSubSection = FeaturesSubSection.passTheTorch;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          decoration: BoxDecoration(
                            color: _activeSubSection == FeaturesSubSection.passTheTorch
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeSubSection == FeaturesSubSection.passTheTorch
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _langService.tr('pass_the_torch'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: _activeSubSection == FeaturesSubSection.passTheTorch
                                      ? AppTheme.emeraldDark
                                      : AppTheme.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeSubSection = FeaturesSubSection.offlineGps;
                          });
                          if (_api.isNoNetMode && !_isOfflineSimulating) {
                            _startOfflineSimulation();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          decoration: BoxDecoration(
                            color: _activeSubSection == FeaturesSubSection.offlineGps
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeSubSection == FeaturesSubSection.offlineGps
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _langService.tr('offline_gps'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: _activeSubSection == FeaturesSubSection.offlineGps
                                      ? AppTheme.emeraldDark
                                      : AppTheme.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeSubSection = FeaturesSubSection.regularChecks;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          decoration: BoxDecoration(
                            color: _activeSubSection == FeaturesSubSection.regularChecks
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeSubSection == FeaturesSubSection.regularChecks
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _langService.tr('regular_checks'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: _activeSubSection == FeaturesSubSection.regularChecks
                                      ? AppTheme.emeraldDark
                                      : AppTheme.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Content Area based on selected sub-section
            Padding(
              padding: const EdgeInsets.all(20),
              child: _activeSubSection == FeaturesSubSection.passTheTorch
                  ? _buildPassTheTorchSection()
                  : (_activeSubSection == FeaturesSubSection.offlineGps
                      ? _buildOfflineGpsSection()
                      : _buildRegularChecksSection()),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SUB-SECTION 1: PASS THE TORCH 🔥
  // ==========================================

  Widget _buildPassTheTorchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header & Concept Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F4C3A), Color(0xFF1B6B52)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.emerald.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _langService.tr('pass_the_torch_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _langService.tr('decentralized_handoff_sub'),
                          style: const TextStyle(
                            color: Color(0xFFA7F3D0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _langService.tr('pass_torch_desc'),
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // STAGE 1: Journey Configuration Card (Before Sharing)
        if (!_isActivelySharing && !_isScanningForPassenger && !_passenger2Found && !_torchAcceptedByPassenger2) ...[
          // Privacy Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF78350F), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _langService.tr('privacy_preserved_note'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Configure Your Journey Card (Exact match to uploaded image)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _langService.tr('configure_journey'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.muted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Transit Route Selection
                _buildFieldLabel(_langService.tr('transit_route')),
                DropdownButtonFormField<String>(
                  value: (_routes.isNotEmpty && _routes.any((r) => r.id == _selectedRouteId))
                      ? _selectedRouteId
                      : (_routes.isNotEmpty ? _routes.first.id : _fallbackRoute.id),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: (_routes.isNotEmpty ? _routes : [_fallbackRoute]).map((r) {
                    return DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        '${_langService.tr('route_prefix')} ${r.routeNumber}: ${r.origin} ↔ ${r.destination}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _onRouteChanged(val);
                  },
                ),
                const SizedBox(height: 16),

                // 2. Bus Selection
                _buildFieldLabel(_langService.tr('which_bus')),
                DropdownButtonFormField<String>(
                  value: (_buses.isNotEmpty && _buses.any((b) => b.id == _selectedBusId))
                      ? _selectedBusId
                      : (_buses.isNotEmpty ? _buses.first.id : _fallbackBus.id),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: (_buses.isNotEmpty ? _buses : [_fallbackBus]).map((bus) {
                    return DropdownMenuItem(
                      value: bus.id,
                      child: Text(
                        '${bus.busNumber.replaceFirst('TNSTC — ', '')} (${bus.vehicleReg})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBusId = val);
                  },
                ),
                const SizedBox(height: 16),

                // 3. Boarding Stop
                _buildFieldLabel(_langService.tr('boarding_stop')),
                DropdownButtonFormField<String>(
                  value: _currentRoute.stops.any((s) => s.id == _selectedBoardingStopId)
                      ? _selectedBoardingStopId
                      : (_currentRoute.stops.isNotEmpty ? _currentRoute.stops.first.id : null),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _currentRoute.stops.map((stop) {
                    return DropdownMenuItem(
                      value: stop.id,
                      child: Text(
                        _langService.translateStop(stop.name),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBoardingStopId = val);
                  },
                ),
                const SizedBox(height: 16),

                // 4. Intended Destination Stop
                _buildFieldLabel(_langService.tr('destination_stop')),
                DropdownButtonFormField<String>(
                  value: _currentRoute.stops.any((s) => s.id == _selectedDestinationStopId)
                      ? _selectedDestinationStopId
                      : (_currentRoute.stops.isNotEmpty ? _currentRoute.stops.last.id : null),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _currentRoute.stops.map((stop) {
                    return DropdownMenuItem(
                      value: stop.id,
                      child: Text(
                        _langService.translateStop(stop.name),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDestinationStopId = val);
                  },
                ),
                const SizedBox(height: 24),

                // Share Location Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleStartSharingLocation,
                    icon: const Icon(Icons.share_location, color: Colors.white),
                    label: Text(
                      _langService.tr('share_location'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C3A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // STAGE 2: Actively Sharing Location (Passenger #1 - Sam)
        if (_isActivelySharing) ...[
          // Bus Route Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'BUS ${_currentRoute.routeNumber}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentRoute.origin.isNotEmpty && _currentRoute.destination.isNotEmpty
                            ? '${_langService.tr('route_prefix')} ${_currentRoute.routeNumber} · ${_currentRoute.origin} ↔ ${_currentRoute.destination}'
                            : '${_langService.tr('route_prefix')} ${_currentRoute.routeNumber} · ${_langService.translateRoute(_currentRoute.name)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '${_langService.translateBus(_currentBus.busNumber.replaceFirst('TNSTC — ', ''))} (${_currentBus.vehicleReg})',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LIVE CABIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary Contributor: Passenger #1 (Sam) Active Sharing Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.emerald, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.emerald.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.emeraldDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _langService.tr('passenger_1_sam'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.circle, color: AppTheme.liveGreen, size: 8),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _langService.tr('primary_contributor_sharing'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF065F46),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Boarding & Destination route indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trip_origin, size: 16, color: AppTheme.emerald),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _langService.translateStop(_currentBoardingStop.shortName.isNotEmpty ? _currentBoardingStop.shortName : _currentBoardingStop.name),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward, size: 14, color: AppTheme.muted),
                      ),
                      const Icon(Icons.location_on, size: 16, color: AppTheme.amber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _langService.translateStop(_currentDestinationStop.shortName.isNotEmpty ? _currentDestinationStop.shortName : _currentDestinationStop.name),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // GPS Telemetry Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.gps_fixed, color: AppTheme.emerald, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Streaming GPS: 11.0168°N, 76.9558°E · Speed: 28 km/h · Accuracy: ±3m',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stop Sharing GPS Button (Simulate Alighting)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleTurnOffSharing,
                    icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFDC2626)),
                    label: Text(
                      _langService.tr('stop_sharing_gps'),
                      style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Scanning State
        if (_isScanningForPassenger) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.amber),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _langService.tr('scanning_cabin'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF78350F)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _langService.tr('searching_passenger_route95'),
                        style: const TextStyle(fontSize: 12, color: Colors.brown),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Passenger #2 Found / Torch Handoff Card
        if (_passenger2Found) ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _torchAcceptedByPassenger2 ? AppTheme.emerald : AppTheme.amber,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.amber.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _torchAcceptedByPassenger2
                            ? AppTheme.emerald.withOpacity(0.15)
                            : AppTheme.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _torchAcceptedByPassenger2 ? Icons.check_circle : Icons.person_pin_circle,
                        color: _torchAcceptedByPassenger2 ? AppTheme.emerald : const Color(0xFF78350F),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _torchAcceptedByPassenger2
                                ? _langService.tr('torch_active_passenger2')
                                : _langService.tr('eligible_passenger_found'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _torchAcceptedByPassenger2 ? AppTheme.emeraldDark : const Color(0xFF78350F),
                            ),
                          ),
                          Text(
                            _torchAcceptedByPassenger2
                                ? _langService.tr('gps_uninterrupted')
                                : _langService.tr('awaiting_approval'),
                            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Passenger #2 Profile Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.amber.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'P',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _langService.tr('priya_seat'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _langService.tr('verified_onboard_sub'),
                              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (!_torchAcceptedByPassenger2) ...[
                  Text(
                    _langService.tr('priya_handoff_desc'),
                    style: const TextStyle(fontSize: 13, color: AppTheme.charcoal, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // The Approval Button Requested by the user
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isApproving ? null : _handleApproveTorch,
                      icon: _isApproving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.handshake_outlined, color: Colors.white),
                      label: Text(
                        _isApproving ? 'Approving Torch...' : _langService.tr('approve_torch_btn'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ] else ...[
                  // Torch Successfully Passed
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.emerald, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _langService.tr('torch_passed_title'),
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF065F46), fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _langService.tr('priya_sharing_live'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _resetPassTheTorch,
                    icon: const Icon(Icons.refresh, color: AppTheme.emerald),
                    label: Text(
                      _langService.tr('reset_handoff_btn'),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.emeraldDark),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.emerald),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  // ==========================================
  // SUB-SECTION 2: OFFLINE GPS SHARING 📡
  // ==========================================

  Widget _buildOfflineGpsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header & Concept Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cloud_off, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _langService.tr('offline_gps_sharing_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _langService.tr('queue_and_recon_sub'),
                          style: const TextStyle(
                            color: Color(0xFFBFDBFE),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _langService.tr('offline_gps_desc'),
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Prominent Notification Banner when Network Resumes
        if (_showResumedNotification && _resumedNotificationMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.emerald, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.emerald.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.emerald, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOTIFICATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.emeraldDark,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _resumedNotificationMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFF065F46)),
                  onPressed: () {
                    setState(() {
                      _showResumedNotification = false;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // No Net Mode Switch Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _api.isNoNetMode || _isOfflineSimulating ? const Color(0xFFEF4444) : AppTheme.border,
              width: _api.isNoNetMode || _isOfflineSimulating ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _api.isNoNetMode || _isOfflineSimulating
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.signal_cellular_connected_no_internet_4_bar,
                        color: _api.isNoNetMode || _isOfflineSimulating
                            ? const Color(0xFFDC2626)
                            : AppTheme.muted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _langService.tr('no_net_mode'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _api.isNoNetMode || _isOfflineSimulating
                                ? 'Offline: EST Tracking active · 15s sim'
                                : 'Normal internet connectivity · LIVE Tracking',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _api.isNoNetMode || _isOfflineSimulating
                                  ? const Color(0xFFD97706)
                                  : AppTheme.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: _api.isNoNetMode || _isOfflineSimulating,
                activeTrackColor: const Color(0xFFD97706),
                onChanged: _toggleNoNetMode,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tracking Mode Indicator Banner (EST vs LIVE)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _isOfflineSimulating ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isOfflineSimulating ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOfflineSimulating ? const Color(0xFFD97706) : AppTheme.emerald,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isOfflineSimulating ? 'EST' : 'LIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOfflineSimulating
                          ? _langService.tr('est_mode')
                          : _langService.tr('live_verified_mode'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _isOfflineSimulating ? const Color(0xFF92400E) : const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isOfflineSimulating
                          ? 'No network: Displaying estimated dead-reckoning movement (Peelamedu → Nava India). Arriving in ~3 mins. Live pings buffer locally.'
                          : 'Network connected: Authoritative live GPS coordinates streaming from onboard passenger contributor.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOfflineSimulating ? const Color(0xFFB45309) : const Color(0xFF047857),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Route Map Container
        Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const ll.LatLng(11.0220, 76.9705),
                  initialZoom: 14.8,
                  minZoom: 12,
                  maxZoom: 17,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    userAgentPackageName: 'com.trava.trava',
                    maxZoom: 19,
                  ),
                  // Route 95 Polyline
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: AppTheme.emerald,
                      ),
                    ],
                  ),
                  // Bus Stop Markers
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: const ll.LatLng(11.0168, 76.9558),
                        width: 120,
                        height: 52,
                        child: _mapStopLabel('Gandhipuram'),
                      ),
                      Marker(
                        point: const ll.LatLng(11.0185, 76.9612),
                        width: 120,
                        height: 52,
                        child: _mapStopLabel('Lakshmi Mills'),
                      ),
                      Marker(
                        point: const ll.LatLng(11.0205, 76.9670),
                        width: 120,
                        height: 52,
                        child: _mapStopLabel('Nava India'),
                      ),
                      Marker(
                        point: const ll.LatLng(11.0235, 76.9740),
                        width: 120,
                        height: 52,
                        child: _mapStopLabel('Peelamedu'),
                      ),
                      // Animated Bus Marker with dynamic EST / LIVE tag
                      Marker(
                        point: _currentBusPos,
                        width: 58,
                        height: 58,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _isOfflineSimulating ? const Color(0xFFD97706) : const Color(0xFF0F4C3A),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                _isOfflineSimulating ? 'EST' : 'LIVE',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _isOfflineSimulating ? const Color(0xFFD97706) : const Color(0xFF0F4C3A),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: _isOfflineSimulating
                                        ? const Color(0xFFD97706).withOpacity(0.4)
                                        : Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Status Floating Pill on Map
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isOfflineSimulating ? const Color(0xFFD97706) : AppTheme.liveGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isOfflineSimulating ? 'EST' : 'LIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isOfflineSimulating
                              ? 'EST TRACKING · Moving Peelamedu → Nava India ($_countdownSeconds s left)'
                              : 'LIVE TRACKING · Route 95 · Avinashi Road · Synced GPS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _isOfflineSimulating ? const Color(0xFFB45309) : const Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recenter map button
              Positioned(
                bottom: 12,
                right: 12,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.emeraldDark,
                  onPressed: () {
                    _mapController.move(_currentBusPos, 14.5);
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action Trigger Button for the Simulation
        if (!_isOfflineSimulating) ...[
          ElevatedButton.icon(
            onPressed: () => _toggleNoNetMode(true),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              _langService.tr('simulate_no_net_btn'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _countdownSeconds / 15.0,
                        strokeWidth: 3.5,
                        color: const Color(0xFFD97706),
                        backgroundColor: const Color(0xFFFEF3C7),
                      ),
                      Text(
                        '$_countdownSeconds',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No Net Mode Active (15s EST Test)',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF92400E), fontSize: 14),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Showing estimated (EST) bus progression towards Nava India while sensor GPS buffers locally.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Offline FIFO Queue List
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.storage_outlined, color: AppTheme.emerald, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _langService.tr('local_gps_queue'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _offlinePings.isEmpty ? Colors.grey.shade100 : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_offlinePings.length} PINGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _offlinePings.isEmpty ? AppTheme.muted : const Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_offlinePings.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No offline records queued. Toggle No Net Mode to buffer coordinates.',
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ),
                ),
              ] else ...[
                ..._offlinePings.map((p) {
                  final isSynced = p['status'] == 'SYNCED & RECONCILED';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSynced ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSynced ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSynced ? Icons.check_circle : Icons.timer_outlined,
                          size: 16,
                          color: isSynced ? AppTheme.emerald : const Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ping #${p['ping']} · ${p['lat']}°N, ${p['lng']}°E',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p['time']}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSynced ? const Color(0xFFA7F3D0).withOpacity(0.5) : const Color(0xFFFECACA).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSynced ? 'SYNCED' : 'QUEUED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isSynced ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Timestamp Reconciliation Mechanism Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_clock, color: AppTheme.charcoal, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _langService.tr('reconciliation_protocol'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _langService.tr('reconciliation_steps'),
                style: const TextStyle(fontSize: 12, color: AppTheme.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // SUB-SECTION 3: REGULAR CHECKS ⏱️
  // ==========================================

  Widget _buildRegularChecksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header & Concept Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF312E81), Color(0xFF4338CA)], // Deep Indigo
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('⏱️', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _langService.tr('regular_checks_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          _langService.tr('inactivity_detection_sub'),
                          style: const TextStyle(
                            color: Color(0xFFC7D2FE),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _langService.tr('regular_checks_desc'),
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Split Layout: Left side controls & notifications, Right side map
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildRegularChecksLeftPanel()),
                  const SizedBox(width: 20),
                  Expanded(flex: 5, child: _buildRegularChecksRightMap()),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRegularChecksLeftPanel(),
                  const SizedBox(height: 20),
                  _buildRegularChecksRightMap(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildRegularChecksLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_rcIsActivelySharing) ...[
          // Privacy Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFF78350F), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _langService.tr('privacy_preserved_note'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Configure Your Journey Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _langService.tr('configure_journey'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.muted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Route
                _buildFieldLabel(_langService.tr('transit_route')),
                DropdownButtonFormField<String>(
                  value: (_routes.isNotEmpty && _routes.any((r) => r.id == _selectedRouteId))
                      ? _selectedRouteId
                      : (_routes.isNotEmpty ? _routes.first.id : _fallbackRoute.id),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: (_routes.isNotEmpty ? _routes : [_fallbackRoute]).map((r) {
                    return DropdownMenuItem(
                      value: r.id,
                      child: Text(
                        '${_langService.tr('transit_route')} ${r.routeNumber}: ${r.origin} ↔ ${r.destination}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) _onRouteChanged(val);
                  },
                ),
                const SizedBox(height: 16),

                // Bus
                _buildFieldLabel(_langService.tr('which_bus')),
                DropdownButtonFormField<String>(
                  value: (_buses.isNotEmpty && _buses.any((b) => b.id == _selectedBusId))
                      ? _selectedBusId
                      : (_buses.isNotEmpty ? _buses.first.id : _fallbackBus.id),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: (_buses.isNotEmpty ? _buses : [_fallbackBus]).map((bus) {
                    return DropdownMenuItem(
                      value: bus.id,
                      child: Text(
                        '${bus.busNumber.replaceFirst('TNSTC — ', '')} (${bus.vehicleReg})',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBusId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Boarding Stop
                _buildFieldLabel(_langService.tr('boarding_stop')),
                DropdownButtonFormField<String>(
                  value: _currentRoute.stops.any((s) => s.id == _selectedBoardingStopId)
                      ? _selectedBoardingStopId
                      : (_currentRoute.stops.isNotEmpty ? _currentRoute.stops.first.id : null),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _currentRoute.stops.map((stop) {
                    return DropdownMenuItem(
                      value: stop.id,
                      child: Text(
                        _langService.translateStop(stop.name),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBoardingStopId = val);
                  },
                ),
                const SizedBox(height: 16),

                // Destination Stop
                _buildFieldLabel(_langService.tr('destination_stop')),
                DropdownButtonFormField<String>(
                  value: _currentRoute.stops.any((s) => s.id == _selectedDestinationStopId)
                      ? _selectedDestinationStopId
                      : (_currentRoute.stops.isNotEmpty ? _currentRoute.stops.last.id : null),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _currentRoute.stops.map((stop) {
                    return DropdownMenuItem(
                      value: stop.id,
                      child: Text(
                        _langService.translateStop(stop.name),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDestinationStopId = val);
                  },
                ),
                const SizedBox(height: 24),

                // Share Location Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _rcHandleStartSharingLocation,
                    icon: const Icon(Icons.share_location, color: Colors.white),
                    label: Text(
                      _langService.tr('share_location'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C3A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Active Contributor Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _rcIsBusBrokenDown
                    ? const Color(0xFFEF4444)
                    : (_rcTorchPassed ? AppTheme.emerald : const Color(0xFF4338CA)),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4338CA).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'S',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4338CA)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _langService.tr('passenger_1_sam'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${_langService.tr('transit_route')} ${_currentRoute.routeNumber} · ${_langService.translateBus(_currentBus.busNumber)}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _rcIsBusBrokenDown
                            ? const Color(0xFFFEE2E2)
                            : (_rcTorchPassed
                                ? const Color(0xFFECFDF5)
                                : (_rcIsIdle5Min ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF))),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _rcIsBusBrokenDown
                            ? _langService.tr('broken_down_badge')
                            : (_rcTorchPassed
                                ? _langService.tr('torch_passed_badge')
                                : (_rcIsIdle5Min ? _langService.tr('idle_5m_badge') : _langService.tr('sharing_live_badge'))),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: _rcIsBusBrokenDown
                              ? const Color(0xFFDC2626)
                              : (_rcTorchPassed
                                  ? const Color(0xFF065F46)
                                  : (_rcIsIdle5Min ? const Color(0xFF92400E) : const Color(0xFF4338CA))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 16, color: AppTheme.emerald),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _rcIsIdle5Min
                              ? 'GPS: 11.0235°N, 76.9740°E · Speed: 0 km/h · Status: Stationary'
                              : 'GPS: 11.0235°N, 76.9740°E · Speed: 28 km/h · Accuracy: ±3m',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Simulation Actions Trigger Card
          if (!_rcIsIdle5Min && !_rcIsBusBrokenDown && !_rcTorchPassed && !_rcIsScanningPassenger) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _langService.tr('simulation_protocol_sub'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _langService.tr('simulate_stationary_desc'),
                    style: const TextStyle(fontSize: 12, color: AppTheme.charcoal, height: 1.3),
                  ),
                  const SizedBox(height: 16),

                  // Button 1: Assume that the location is idle for 5 minutes
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _rcHandleAssumeIdle5Min,
                      icon: const Icon(Icons.timer_outlined, color: Colors.white),
                      label: Text(
                        _langService.tr('assume_idle_btn'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706), // Amber
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Button 2: No reply in 1 minute
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _rcHandleNoReplyTimeout,
                      icon: const Icon(Icons.hourglass_disabled, color: Color(0xFF4338CA)),
                      label: Text(
                        _langService.tr('no_reply_btn'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF4338CA)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // INACTIVITY ALERT POP-UP CARD (when _rcIsIdle5Min is true)
          if (_rcIsIdle5Min) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _langService.tr('inactivity_alert_title'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF92400E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_rcCountdownSeconds ${_langService.tr('seconds_left')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Prompt question
                  Text(
                    _langService.tr('idle_dialog_title'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF78350F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _langService.tr('inactivity_time_prompt'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(height: 18),

                  // Option A: Yes, the bus broke down
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _rcHandleBusBreakdown,
                      icon: const Icon(Icons.car_crash_outlined, color: Colors.white),
                      label: Text(
                        _langService.tr('bus_broke_down_btn'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option B: No, normal traffic / delay
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _rcHandleNormalTraffic,
                      icon: const Icon(Icons.traffic, color: Color(0xFF047857)),
                      label: Text(
                        _langService.tr('normal_delay_btn'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF047857)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFA7F3D0), width: 1.5),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Option C: No reply in 1 minute simulation button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _rcHandleNoReplyTimeout,
                      icon: const Icon(Icons.timer_off_outlined, size: 18, color: Color(0xFF4338CA)),
                      label: Text(
                        _langService.tr('simulate_no_reply_1min'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF4338CA)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // BUS BREAKDOWN BROADCAST RESULT CARD
          if (_rcIsBusBrokenDown) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDC2626), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_problem, color: Color(0xFFDC2626), size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _langService.tr('passengers_informed_breakdown'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _langService.tr('breakdown_broadcast_desc'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _rcReset,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        _langService.tr('reset_handoff_btn'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF991B1B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // SCANNING PASSENGER STATE
          if (_rcIsScanningPassenger) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4338CA)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _langService.tr('scanning_cabin'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF312E81)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _langService.tr('unresponsive_searching_p2'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // TORCH PASSED CARD
          if (_rcTorchPassed) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.emerald, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.emerald.withOpacity(0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.emerald, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _langService.tr('torch_passed_priya'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _langService.tr('torch_passed_inactivity_desc'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF047857), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _rcReset,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        _langService.tr('reset_handoff_btn'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C3A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Stop Sharing Location Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _rcReset,
              icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFDC2626)),
              label: Text(
                _langService.tr('stop_sharing_reset'),
                style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegularChecksRightMap() {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _rcIsBusBrokenDown
              ? const Color(0xFFDC2626)
              : (_rcTorchPassed ? AppTheme.emerald : AppTheme.border),
          width: _rcIsBusBrokenDown ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _rcMapController,
            options: MapOptions(
              initialCenter: const ll.LatLng(11.0220, 76.9705),
              initialZoom: 14.8,
              minZoom: 12,
              maxZoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.trava.trava',
                maxZoom: 19,
              ),
              // Route 95 Polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5,
                    color: _rcIsBusBrokenDown ? const Color(0xFFEF4444) : AppTheme.emerald,
                  ),
                ],
              ),
              // Bus Stop Markers
              MarkerLayer(
                markers: [
                  Marker(
                    point: const ll.LatLng(11.0168, 76.9558),
                    width: 120,
                    height: 52,
                    child: _mapStopLabel('Gandhipuram'),
                  ),
                  Marker(
                    point: const ll.LatLng(11.0185, 76.9612),
                    width: 120,
                    height: 52,
                    child: _mapStopLabel('Lakshmi Mills'),
                  ),
                  Marker(
                    point: const ll.LatLng(11.0205, 76.9670),
                    width: 120,
                    height: 52,
                    child: _mapStopLabel('Nava India'),
                  ),
                  Marker(
                    point: const ll.LatLng(11.0235, 76.9740),
                    width: 120,
                    height: 52,
                    child: _mapStopLabel('Peelamedu'),
                  ),
                  // Dynamic Bus Marker
                  Marker(
                    point: _rcBusPos,
                    width: 76,
                    height: 76,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _rcIsBusBrokenDown
                                ? const Color(0xFFDC2626)
                                : (_rcTorchPassed
                                    ? AppTheme.emerald
                                    : (_rcIsIdle5Min ? const Color(0xFFD97706) : const Color(0xFF0F4C3A))),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            _rcIsBusBrokenDown
                                ? '⚠️ ${_langService.tr('map_status_alert')}'
                                : (_rcTorchPassed ? '🔥 ${_langService.tr('map_status_torch')}' : (_rcIsIdle5Min ? '⏱️ ${_langService.tr('map_status_idle')}' : _langService.tr('map_status_live'))),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _rcIsBusBrokenDown
                                ? const Color(0xFFDC2626)
                                : (_rcTorchPassed
                                    ? AppTheme.emerald
                                    : (_rcIsIdle5Min ? const Color(0xFFD97706) : const Color(0xFF0F4C3A))),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: (_rcIsBusBrokenDown ? const Color(0xFFDC2626) : AppTheme.emerald).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _rcIsBusBrokenDown
                                ? Icons.warning_amber_rounded
                                : (_rcIsIdle5Min ? Icons.pause_circle_filled : Icons.directions_bus),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Floating Top Status Pill over map
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _rcIsBusBrokenDown
                          ? const Color(0xFFDC2626)
                          : (_rcTorchPassed
                              ? AppTheme.emerald
                              : (_rcIsIdle5Min ? const Color(0xFFD97706) : AppTheme.liveGreen)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _rcIsBusBrokenDown
                          ? _langService.tr('map_status_alert')
                          : (_rcTorchPassed ? _langService.tr('map_status_torch') : (_rcIsIdle5Min ? _langService.tr('map_status_idle') : _langService.tr('map_status_live'))),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _rcIsBusBrokenDown
                          ? _langService.tr('map_msg_broken')
                          : (_rcTorchPassed
                              ? _langService.tr('map_msg_torch')
                              : (_rcIsIdle5Min
                                  ? _langService.tr('map_msg_idle')
                                  : _langService.tr('map_msg_synced'))),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _rcIsBusBrokenDown
                            ? const Color(0xFF991B1B)
                            : (_rcTorchPassed
                                ? const Color(0xFF065F46)
                                : (_rcIsIdle5Min ? const Color(0xFF92400E) : const Color(0xFF065F46))),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recenter map button
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.emeraldDark,
              onPressed: () {
                _rcMapController.move(_rcBusPos, 14.8);
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapStopLabel(String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _langService.translateStop(name),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
          ),
        ),
        const Icon(Icons.location_pin, color: AppTheme.emerald, size: 14),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.charcoal),
      ),
    );
  }
}
