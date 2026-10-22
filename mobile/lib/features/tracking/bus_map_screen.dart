import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_route.dart';
import '../../models/bus_service.dart';
import '../../services/api_service.dart';
import '../../services/voice_service.dart';

enum GoogleMapLayerType {
  streets,
  satellite,
  terrain,
}

class BusMapScreen extends StatefulWidget {
  final BusServiceModel bus;
  final BusRouteModel? route;
  final String boardingStop;
  final String destinationStop;

  const BusMapScreen({
    super.key,
    required this.bus,
    this.route,
    required this.boardingStop,
    required this.destinationStop,
  });

  @override
  State<BusMapScreen> createState() => _BusMapScreenState();
}

class _BusMapScreenState extends State<BusMapScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  late BusServiceModel _currentBus;
  Timer? _pollingTimer;
  late AnimationController _pulseController;
  late AnimationController _moveController;
  late Animation<double> _latAnimation;
  late Animation<double> _lngAnimation;
  late Animation<double> _progressAnimation;
  double _animatedLat = 0;
  double _animatedLng = 0;
  double _animatedProgress = 0;
  String? _targetedStopName;

  // Map state
  final MapController _mapController = MapController();
  GoogleMapLayerType _selectedLayer = GoogleMapLayerType.streets;
  bool _useGoogleMaps = true;
  bool _followBus = true;
  bool _isStatsMinimized = false;

  String get _googleTileUrl {
    switch (_selectedLayer) {
      case GoogleMapLayerType.satellite:
        // Google Hybrid (Satellite + Roads + Labels)
        return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case GoogleMapLayerType.terrain:
        // Google Terrain
        return 'https://mt1.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case GoogleMapLayerType.streets:
        // Google Street Map (Roads, buildings, traffic)
        return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
    }
  }

  int _pollCount = 0;

  @override
  void initState() {
    super.initState();
    _currentBus = widget.bus;
    _targetedStopName = widget.boardingStop;
    _pollCount = 0;

    // Ensure we have a valid bus ID and route-specific initial data
    final routeId = (widget.route?.id ?? _currentBus.routeId).toLowerCase();
    final cleanId = routeId.replaceFirst('route_', '');
    final stops = widget.route?.stops;

    double defaultLat = 11.0168;
    double defaultLng = 76.9678;
    if (stops != null && stops.isNotEmpty) {
      defaultLat = stops.first.latitude;
      defaultLng = stops.first.longitude;
    } else if (routeId.contains('70')) {
      defaultLat = 10.9980;
      defaultLng = 77.0320;
    } else if (routeId.contains('20c') || routeId.contains('20')) {
      defaultLat = 11.0500;
      defaultLng = 76.9850;
    } else if (routeId.contains('10a') || routeId.contains('10')) {
      defaultLat = 11.0145;
      defaultLng = 76.9300;
    } else if (routeId.contains('111')) {
      defaultLat = 10.9950;
      defaultLng = 76.9620;
    }

    if (_currentBus.id.isEmpty) {
      _currentBus = BusServiceModel(
        id: 'bus_${cleanId}_a',
        busNumber: widget.bus.busNumber.isNotEmpty ? widget.bus.busNumber : 'TNSTC — City Express',
        vehicleReg: widget.bus.vehicleReg.isNotEmpty ? widget.bus.vehicleReg : 'TN 38 N 1000',
        routeId: routeId,
        direction: 'OUTBOUND',
        crowdStatus: widget.bus.crowdStatus,
        trackingStatus: widget.bus.trackingStatus,
        locationFreshness: widget.bus.locationFreshness,
        isSimulated: true,
        currentProgress: widget.bus.currentProgress > 0 ? widget.bus.currentProgress : 0.2,
        speedKmH: widget.bus.speedKmH > 0 ? widget.bus.speedKmH : 30,
        currentStopId: widget.bus.currentStopId,
        nextStopId: widget.bus.nextStopId,
        currentLatitude: widget.bus.currentLatitude != 0 ? widget.bus.currentLatitude : defaultLat,
        currentLongitude: widget.bus.currentLongitude != 0 ? widget.bus.currentLongitude : defaultLng,
        bearing: widget.bus.bearing,
        etaMinutes: widget.bus.etaMinutes > 0 ? widget.bus.etaMinutes : 10,
        distanceRemainingKm: widget.bus.distanceRemainingKm >= 2.0 ? widget.bus.distanceRemainingKm : 4.5,
      );
    } else if (_currentBus.currentLatitude == 0 || _currentBus.currentLatitude < 5.0) {
      _currentBus = _currentBus.copyWith(
        currentLatitude: defaultLat,
        currentLongitude: defaultLng,
      );
    }

    _animatedLat = _currentBus.currentLatitude;
    _animatedLng = _currentBus.currentLongitude;
    _animatedProgress = _currentBus.currentProgress;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _latAnimation = Tween<double>(begin: _animatedLat, end: _animatedLat).animate(_moveController);
    _lngAnimation = Tween<double>(begin: _animatedLng, end: _animatedLng).animate(_moveController);
    _progressAnimation = Tween<double>(begin: _animatedProgress, end: _animatedProgress).animate(_moveController);

    _moveController.addListener(() {
      setState(() {
        _animatedLat = _latAnimation.value;
        _animatedLng = _lngAnimation.value;
        _animatedProgress = _progressAnimation.value;
      });
    });

    // Immediately fetch authoritative live GPS to snap bus into place with zero delay
    _pollLiveBus(isInitial: true);

    // Poll live simulated positions every 2 seconds from authoritative backend
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollLiveBus();
    });
  }

  Future<void> _pollLiveBus({bool isInitial = false}) async {
    final defaultBusId = widget.route != null
        ? 'bus_${widget.route!.id.toLowerCase().replaceFirst("route_", "")}_a'
        : 'bus_95_a';
    final busId = _currentBus.id.isNotEmpty ? _currentBus.id : defaultBusId;
    final updated = await _api.getBusLive(busId);
    if (updated != null && mounted) {
      final oldLat = _animatedLat != 0 ? _animatedLat : _currentBus.currentLatitude;
      final oldLng = _animatedLng != 0 ? _animatedLng : _currentBus.currentLongitude;
      final oldProg = _animatedProgress != 0 ? _animatedProgress : _currentBus.currentProgress;

      final distKm = _calcDistanceKm(oldLat, oldLng, updated.currentLatitude, updated.currentLongitude);
      _pollCount++;
      // Snap instantly if:
      // 1) First or second poll (initial sync)
      // 2) Distance moved exceeds 50 meters (jump, turn-around, reset)
      // This completely eliminates fast movement/flying across the map on all routes!
      final shouldSnap = isInitial || _pollCount <= 2 || distKm > 0.05;

      _currentBus = updated;

      if (shouldSnap) {
        _moveController.stop();
        setState(() {
          _animatedLat = updated.currentLatitude;
          _animatedLng = updated.currentLongitude;
          _animatedProgress = updated.currentProgress;
          _latAnimation = Tween<double>(begin: _animatedLat, end: _animatedLat).animate(_moveController);
          _lngAnimation = Tween<double>(begin: _animatedLng, end: _animatedLng).animate(_moveController);
          _progressAnimation = Tween<double>(begin: _animatedProgress, end: _animatedProgress).animate(_moveController);
        });
      } else {
        // Smoothly animate marker from old position to new position over the 2-second interval (~15m at ~27 km/h)
        _latAnimation = Tween<double>(begin: oldLat, end: updated.currentLatitude).animate(
          CurvedAnimation(parent: _moveController, curve: Curves.linear),
        );
        _lngAnimation = Tween<double>(begin: oldLng, end: updated.currentLongitude).animate(
          CurvedAnimation(parent: _moveController, curve: Curves.linear),
        );
        _progressAnimation = Tween<double>(begin: oldProg, end: updated.currentProgress).animate(
          CurvedAnimation(parent: _moveController, curve: Curves.linear),
        );
        _moveController.forward(from: 0.0);
      }

      // Animate map camera to smoothly follow the bus if enabled
      if (_useGoogleMaps && _followBus) {
        try {
          _mapController.move(
            ll.LatLng(updated.currentLatitude, updated.currentLongitude),
            _mapController.camera.zoom,
          );
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _pulseController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  void _recenterBus() {
    try {
      final targetLat = _animatedLat != 0 ? _animatedLat : _currentBus.currentLatitude;
      final targetLng = _animatedLng != 0 ? _animatedLng : _currentBus.currentLongitude;
      _mapController.move(
        ll.LatLng(targetLat, targetLng),
        14.5,
      );
    } catch (_) {}
  }

  void _showCrowdReportModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report Crowd Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Help fellow passengers waiting at bus stops across Coimbatore.',
                style: TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _crowdOption('EMPTY', 'Empty Bus', 'Plenty of seats available', Colors.blue, Icons.airline_seat_recline_extra),
              const SizedBox(height: 10),
              _crowdOption('SEATS_AVAILABLE', 'Seats Available', 'Normal passenger capacity', AppTheme.liveGreen, Icons.airline_seat_individual_suite),
              const SizedBox(height: 10),
              _crowdOption('PACKED', 'Packed / Standing Only', 'Very crowded bus', Colors.red, Icons.groups),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _crowdOption(String category, String title, String subtitle, Color color, IconData icon) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final busId = _currentBus.id.isNotEmpty ? _currentBus.id : 'bus_95_a';
        await _api.submitCrowdReport(busId, category);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Crowd report recorded: $title. Thank you!'),
              backgroundColor: AppTheme.emerald,
            ),
          );
          _pollLiveBus();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
          color: color.withOpacity(0.06),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calcDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  String _formatArrivalTime(int minutes) {
    final arrival = DateTime.now().add(Duration(minutes: minutes));
    final hour = arrival.hour == 0 ? 12 : (arrival.hour > 12 ? arrival.hour - 12 : arrival.hour);
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = arrival.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _triggerVoiceAnnouncement(int targetedEta, {VoiceAnnouncementLanguage? lang}) {
    final targetStop = _targetedStopName ?? widget.boardingStop;
    VoiceService().announceBusArrival(
      busNumber: _currentBus.busNumber,
      pickupStop: targetStop,
      destinationStop: widget.destinationStop,
      etaMinutes: targetedEta,
      languageOverride: lang,
    );
  }

  Widget _buildVoiceAnnouncementCard(int targetedEta, String activeTargetStop, List<StopModel> stops) {
    final voice = VoiceService();
    return AnimatedBuilder(
      animation: voice,
      builder: (context, _) {
        final isSpeaking = voice.isSpeaking;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSpeaking ? const Color(0xFFECFDF5) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSpeaking ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              width: isSpeaking ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Stop Selector Chips (Gandhipuram, Peelamedu, Fun Mall, Singanallur, etc.)
              Row(
                children: [
                  const Icon(Icons.pin_drop, size: 14, color: AppTheme.emerald),
                  const SizedBox(width: 4),
                  const Text(
                    'Announce for Stop:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                  ),
                  const Spacer(),
                  if (isSpeaking)
                    GestureDetector(
                      onTap: () => voice.stop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stop, size: 12, color: Colors.red.shade800),
                            const SizedBox(width: 2),
                            Text('Stop Audio', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red.shade800)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Boarding Stop Chip
                    ChoiceChip(
                      selected: activeTargetStop.toLowerCase() == widget.boardingStop.toLowerCase(),
                      label: Text('🟢 ${widget.boardingStop}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      selectedColor: const Color(0xFFDCFCE7),
                      onSelected: (_) {
                        setState(() => _targetedStopName = widget.boardingStop);
                      },
                    ),
                    const SizedBox(width: 6),
                    // Destination Stop Chip
                    ChoiceChip(
                      selected: activeTargetStop.toLowerCase() == widget.destinationStop.toLowerCase(),
                      label: Text('🏁 ${widget.destinationStop}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      selectedColor: const Color(0xFFFEF3C7),
                      onSelected: (_) {
                        setState(() => _targetedStopName = widget.destinationStop);
                      },
                    ),
                    const SizedBox(width: 6),
                    // Other stops on the route
                    ...stops.where((s) =>
                      s.shortName.toLowerCase() != widget.boardingStop.toLowerCase() &&
                      s.shortName.toLowerCase() != widget.destinationStop.toLowerCase()
                    ).map((s) {
                      final isSel = activeTargetStop.toLowerCase() == s.shortName.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          selected: isSel,
                          label: Text(s.shortName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          selectedColor: const Color(0xFFE0F2FE),
                          onSelected: (_) {
                            setState(() => _targetedStopName = s.shortName);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Trigger Buttons Row: Both, English (Male), Tamil (Female)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _triggerVoiceAnnouncement(targetedEta, lang: VoiceAnnouncementLanguage.both),
                      icon: const Icon(Icons.record_voice_over, size: 14),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '🔊 Both',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _triggerVoiceAnnouncement(targetedEta, lang: VoiceAnnouncementLanguage.english),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '🇬🇧 English',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _triggerVoiceAnnouncement(targetedEta, lang: VoiceAnnouncementLanguage.tamil),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Color(0xFF047857)),
                        backgroundColor: const Color(0xFFECFDF5),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '🇮🇳 தமிழ்',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Spoken subtitles
              if (voice.lastSpokenEnglish.isNotEmpty || voice.lastSpokenTamil.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (voice.lastSpokenEnglish.isNotEmpty)
                        Text(
                          '🇬🇧 "${voice.lastSpokenEnglish}"',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.charcoal),
                        ),
                      if (voice.lastSpokenTamil.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          '🇮🇳 "${voice.lastSpokenTamil}"',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.route?.stops ?? [];
    final currentLat = _animatedLat != 0 ? _animatedLat : _currentBus.currentLatitude;
    final currentLng = _animatedLng != 0 ? _animatedLng : _currentBus.currentLongitude;
    final currentProg = _animatedProgress != 0 ? _animatedProgress : _currentBus.currentProgress;
    final busPosition = ll.LatLng(currentLat, currentLng);

    // Stop polyline points
    final List<ll.LatLng> polylinePoints = stops.map((s) => ll.LatLng(s.latitude, s.longitude)).toList();

    // Targeted ETA and distance remaining specifically to user's selected destination
    final destLower = widget.destinationStop.toLowerCase().trim();
    StopModel destStop;
    try {
      destStop = stops.firstWhere(
        (s) =>
            s.shortName.toLowerCase().contains(destLower) ||
            destLower.contains(s.shortName.toLowerCase()) ||
            s.name.toLowerCase().contains(destLower) ||
            destLower.contains(s.name.toLowerCase()),
      );
    } catch (_) {
      destStop = stops.isNotEmpty
          ? stops.last
          : StopModel(
              id: 'stop_dest_fallback',
              name: widget.destinationStop,
              shortName: widget.destinationStop,
              sequence: 99,
              latitude: 11.0168,
              longitude: 76.9678,
              isMajorJunction: true,
            );
    }

    final originLower = widget.boardingStop.toLowerCase().trim();
    StopModel originStop;
    try {
      originStop = stops.firstWhere(
        (s) =>
            s.shortName.toLowerCase().contains(originLower) ||
            originLower.contains(s.shortName.toLowerCase()) ||
            s.name.toLowerCase().contains(originLower) ||
            originLower.contains(s.name.toLowerCase()),
      );
    } catch (_) {
      originStop = stops.isNotEmpty ? stops.first : destStop;
    }

    // Active targeted stop for live ETA and announcements (defaults to passenger's pickup stop)
    final activeTargetStopName = _targetedStopName ?? widget.boardingStop;
    final targetLower = activeTargetStopName.toLowerCase().trim();
    StopModel targetedStop;
    try {
      targetedStop = stops.firstWhere(
        (s) =>
            s.shortName.toLowerCase().contains(targetLower) ||
            targetLower.contains(s.shortName.toLowerCase()) ||
            s.name.toLowerCase().contains(targetLower) ||
            targetLower.contains(s.name.toLowerCase()),
      );
    } catch (_) {
      targetedStop = originStop;
    }

    // Direct physical distance from bus's live coordinates to targeted stop
    final targetDirectDistKm = _calcDistanceKm(
      currentLat,
      currentLng,
      targetedStop.latitude,
      targetedStop.longitude,
    );
    final targetRoadDistKm = targetDirectDistKm * 1.18;

    // Realistic accurate ETA based on live bus speed
    final speed = _currentBus.speedKmH > 10 ? _currentBus.speedKmH.toDouble() : 25.0;
    int targetedEta = ((targetRoadDistKm / speed) * 60).round();
    if (targetRoadDistKm < 0.25) {
      targetedEta = 1; // Arriving now at stop
    } else if (targetedEta < 1) {
      targetedEta = 1;
    }

    final targetedDistString = targetRoadDistKm < 0.25 ? 'Arriving now' : '${targetRoadDistKm.toStringAsFixed(1)} km';

    // Trip progress towards final destination
    final destRoadDistKm = _calcDistanceKm(
      currentLat,
      currentLng,
      destStop.latitude,
      destStop.longitude,
    ) * 1.18;

    final totalTripKm = _calcDistanceKm(
      originStop.latitude,
      originStop.longitude,
      destStop.latitude,
      destStop.longitude,
    ) * 1.18;

    double tripProgress = _currentBus.currentProgress;
    if (totalTripKm > 0.4) {
      final coveredKm = (totalTripKm - destRoadDistKm).clamp(0.0, totalTripKm);
      tripProgress = (coveredKm / totalTripKm).clamp(0.05, 0.95);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _currentBus.busNumber,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _currentBus.isGovernment ? const Color(0xFFE0E7FF) : const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _currentBus.isGovernment ? 'GOVT' : 'PVT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: _currentBus.isGovernment ? const Color(0xFF3730A3) : const Color(0xFF6B21A8),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${_currentBus.operatorName} • ${widget.boardingStop} → ${widget.destinationStop}',
              style: const TextStyle(fontSize: 11, color: AppTheme.muted),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Toggle Google Maps / Schematic Canvas
          IconButton(
            icon: Icon(
              _useGoogleMaps ? Icons.map : Icons.alt_route,
              color: AppTheme.emerald,
            ),
            tooltip: _useGoogleMaps ? 'Switch to Schematic Route View' : 'Switch to Google Maps View',
            onPressed: () {
              setState(() {
                _useGoogleMaps = !_useGoogleMaps;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _useGoogleMaps
                        ? 'Switched to Google Maps Live Real-World View'
                        : 'Switched to Schematic Transit Canvas View',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),

          // Google Maps Layer Toggle (Streets / Satellite / Terrain)
          if (_useGoogleMaps)
            PopupMenuButton<GoogleMapLayerType>(
              icon: const Icon(Icons.layers_outlined, color: AppTheme.emerald),
              tooltip: 'Google Maps Layer Type',
              onSelected: (layer) {
                setState(() => _selectedLayer = layer);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: GoogleMapLayerType.streets,
                  child: Row(
                    children: [
                      Icon(Icons.map, size: 18, color: AppTheme.emerald),
                      SizedBox(width: 10),
                      Text('Google Streets Map'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: GoogleMapLayerType.satellite,
                  child: Row(
                    children: [
                      Icon(Icons.satellite_alt, size: 18, color: AppTheme.emerald),
                      SizedBox(width: 10),
                      Text('Google Satellite View'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: GoogleMapLayerType.terrain,
                  child: Row(
                    children: [
                      Icon(Icons.terrain, size: 18, color: AppTheme.emerald),
                      SizedBox(width: 10),
                      Text('Google Terrain Map'),
                    ],
                  ),
                ),
              ],
            ),

          // Crowd reporting button
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Report Crowd',
            onPressed: _showCrowdReportModal,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Map Layer: Real Google Maps Tile View OR Schematic Canvas
          Positioned.fill(
            child: _useGoogleMaps
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: busPosition,
                      initialZoom: 13.8,
                      minZoom: 10.0,
                      maxZoom: 19.0,
                      onPositionChanged: (pos, hasGesture) {
                        if (hasGesture && _followBus) {
                          setState(() => _followBus = false);
                        }
                      },
                    ),
                    children: [
                      // Google Maps Tiles Layer (Streets, Satellite, or Terrain)
                      TileLayer(
                        urlTemplate: _googleTileUrl,
                        userAgentPackageName: 'com.trava.trava',
                        maxZoom: 19,
                      ),

                      // Route 95 Polyline along Coimbatore roads
                      if (polylinePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              color: AppTheme.emerald,
                              strokeWidth: 6.0,
                              borderColor: Colors.white,
                              borderStrokeWidth: 2.0,
                            ),
                          ],
                        ),

                      // Stop Station Markers Layer
                      MarkerLayer(
                        markers: [
                          // Stops along the route with Boarding/Destination/Target highlights
                          ...stops.map((s) {
                            final originLower = widget.boardingStop.toLowerCase();
                            final destLower = widget.destinationStop.toLowerCase();
                            final sShortLower = s.shortName.toLowerCase();
                            final sNameLower = s.name.toLowerCase();

                            final isOrigin = sShortLower.contains(originLower) ||
                                originLower.contains(sShortLower) ||
                                sNameLower.contains(originLower);
                            final isDest = sShortLower.contains(destLower) ||
                                destLower.contains(sShortLower) ||
                                sNameLower.contains(destLower);
                            final isTarget = sShortLower == activeTargetStopName.toLowerCase() ||
                                sNameLower == activeTargetStopName.toLowerCase();
                            final isMajor = s.isMajorJunction;

                            Color badgeColor = Colors.white;
                            Color borderColor = isMajor ? AppTheme.emeraldDark : AppTheme.emerald;
                            Color textColor = isMajor ? AppTheme.emeraldDark : AppTheme.charcoal;
                            String prefix = '';

                            if (isTarget) {
                              badgeColor = const Color(0xFFE0F2FE);
                              borderColor = const Color(0xFF0284C7);
                              textColor = const Color(0xFF0369A1);
                              prefix = '🎯 ';
                            } else if (isOrigin) {
                              badgeColor = const Color(0xFFDCFCE7);
                              borderColor = const Color(0xFF16A34A);
                              textColor = const Color(0xFF15803D);
                              prefix = '🟢 ';
                            } else if (isDest) {
                              badgeColor = const Color(0xFFFEF3C7);
                              borderColor = const Color(0xFFD97706);
                              textColor = const Color(0xFFB45309);
                              prefix = '🏁 ';
                            }

                            return Marker(
                              point: ll.LatLng(s.latitude, s.longitude),
                              width: (isOrigin || isDest || isTarget) ? 135 : 110,
                              height: 54,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _targetedStopName = s.shortName);
                                  _triggerVoiceAnnouncement(targetedEta);
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                                        ],
                                        border: Border.all(
                                          color: borderColor,
                                          width: (isOrigin || isDest || isTarget) ? 2.2 : 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        '$prefix${s.shortName}',
                                        style: TextStyle(
                                          fontSize: (isOrigin || isDest || isTarget) ? 10.5 : 10,
                                          fontWeight: (isOrigin || isDest || isMajor || isTarget) ? FontWeight.w900 : FontWeight.w700,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: (isOrigin || isDest || isTarget) ? 12 : 10,
                                      height: (isOrigin || isDest || isTarget) ? 12 : 10,
                                      decoration: BoxDecoration(
                                        color: isTarget
                                            ? const Color(0xFF0284C7)
                                            : (isOrigin
                                                ? const Color(0xFF16A34A)
                                                : (isDest
                                                    ? const Color(0xFFD97706)
                                                    : (isMajor ? AppTheme.amber : Colors.white))),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: borderColor, width: 2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          // Live Moving Bus Marker
                          Marker(
                            point: busPosition,
                            width: 64,
                            height: 64,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Pulsing radar wave
                                    Container(
                                      width: 32 + (_pulseController.value * 28),
                                      height: 32 + (_pulseController.value * 28),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.amber.withOpacity((1.0 - _pulseController.value) * 0.5),
                                      ),
                                    ),

                                    // Rotated bus icon
                                    Transform.rotate(
                                      angle: _currentBus.bearing * (math.pi / 180),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppTheme.amber,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2.5),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text('🚌', style: TextStyle(fontSize: 18)),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _TransitMapPainter(
                          stops: stops,
                          progress: currentProg,
                          bearing: _currentBus.bearing.toDouble(),
                          pulseValue: _pulseController.value,
                        ),
                      );
                    },
                  ),
          ),

          // 2. Top Badges & Map Mode Pill
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Demo Mode Pill
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                      ],
                      border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.liveGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            AppConstants.demoBadgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.emerald,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Map Engine Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _useGoogleMaps ? Icons.public : Icons.route,
                        size: 14,
                        color: AppTheme.emerald,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _useGoogleMaps
                            ? (_selectedLayer == GoogleMapLayerType.satellite ? 'SATELLITE' : 'GOOGLE MAPS')
                            : 'SCHEMATIC',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Re-center FAB on Google Maps (Adapts smoothly to minimized/expanded stats)
          if (_useGoogleMaps)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              right: 16,
              top: _isStatsMinimized ? null : 64,
              bottom: _isStatsMinimized ? 146 : null,
              child: FloatingActionButton.small(
                heroTag: 'recenterBusFab',
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.emerald,
                tooltip: 'Center on Live Bus',
                onPressed: _recenterBus,
                child: const Icon(Icons.my_location),
              ),
            ),

          // Voice Announcement FAB on Live Map (Visible when stats are minimized for quick audio)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            right: 16,
            bottom: _isStatsMinimized ? 88 : -80,
            child: FloatingActionButton.extended(
              heroTag: 'voiceAnnouncementFab',
              backgroundColor: AppTheme.emeraldDark,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.volume_up, size: 18),
              label: const Text('Voice ETA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              onPressed: () => _triggerVoiceAnnouncement(targetedEta),
            ),
          ),

          // 3. Bottom ETA & Journey Progress Card (Minimizable to reveal full map)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isStatsMinimized
                  ? _buildMinimizedStatsBar(
                      key: const ValueKey('minimized_stats'),
                      targetedEta: targetedEta,
                      activeTargetStopName: activeTargetStopName,
                      targetedDistString: targetedDistString,
                    )
                  : _buildExpandedStatsCard(
                      key: const ValueKey('expanded_stats'),
                      targetedEta: targetedEta,
                      activeTargetStopName: activeTargetStopName,
                      targetedDistString: targetedDistString,
                      tripProgress: tripProgress,
                      stops: stops,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact 60px bottom bar when minimized to show full map clearly
  Widget _buildMinimizedStatsBar({
    Key? key,
    required int targetedEta,
    required String activeTargetStopName,
    required String targetedDistString,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _isStatsMinimized = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Bus Icon badge with subtle live indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_bus, color: AppTheme.emeraldDark, size: 20),
                ),
                const SizedBox(width: 10),

                // ETA & destination preview
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$targetedEta mins',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.emeraldDark,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3.5,
                            height: 3.5,
                            decoration: const BoxDecoration(
                              color: AppTheme.muted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '$targetedDistString to $activeTargetStopName',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF78350F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Arriving ~ ${_formatArrivalTime(targetedEta)} • ${_currentBus.speedKmH} km/h • ${_currentBus.busNumber}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Tap to view full stats button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.emerald.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.keyboard_arrow_up, size: 16, color: Colors.white),
                      SizedBox(width: 2),
                      Text(
                        'Stats',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Full expanded bottom card with drag handle and explicit small minimize button
  Widget _buildExpandedStatsCard({
    Key? key,
    required int targetedEta,
    required String activeTargetStopName,
    required String targetedDistString,
    required double tripProgress,
    required List<StopModel> stops,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.58,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Drag Handle & Small Minimize Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 72), // Balances the minimize button width
                  // Center drag pill handle
                  GestureDetector(
                    onTap: () => setState(() => _isStatsMinimized = true),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Small sleek Minimize Button to reveal map
                  InkWell(
                    onTap: () => setState(() => _isStatsMinimized = true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.charcoal),
                          SizedBox(width: 2),
                          Text(
                            'Minimize',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.charcoal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. ETA & Speed Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED ARRIVAL · ${activeTargetStopName.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.muted,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$targetedEta',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.emeraldDark,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'mins',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Arriving ~ ${_formatArrivalTime(targetedEta)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Speed and remaining km to selected destination
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$targetedDistString to $activeTargetStopName',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF78350F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Speed: ${_currentBus.speedKmH} km/h',
                        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Operator & Registration Pill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _currentBus.isGovernment ? const Color(0xFFE0E7FF) : const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _currentBus.isGovernment ? '🏛️ TNSTC Government Bus' : '🏢 ${_currentBus.operatorName}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _currentBus.isGovernment ? const Color(0xFF3730A3) : const Color(0xFF6B21A8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_currentBus.vehicleReg} · ${_currentBus.serviceType}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Live Voice Announcement Card (English & Tamil)
              _buildVoiceAnnouncementCard(targetedEta, activeTargetStopName, stops),
              const SizedBox(height: 8),

              // Stop Progress Milestones with Start & Destination labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🟢 ', style: TextStyle(fontSize: 10)),
                        Flexible(
                          child: Text(
                            widget.boardingStop,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(tripProgress * 100).toInt()}% towards destination',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.emerald),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏁 ', style: TextStyle(fontSize: 10)),
                        Flexible(
                          child: Text(
                            widget.destinationStop,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: tripProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.emerald),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop, size: 16, color: AppTheme.emerald),
                      const SizedBox(width: 4),
                      Text(
                        'To: ${widget.destinationStop}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: _showCrowdReportModal,
                    icon: const Icon(Icons.people_outline, size: 16, color: AppTheme.emerald),
                    label: const Text('Report Crowd', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.emerald)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.emerald),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _TransitMapPainter extends CustomPainter {
  final List<StopModel> stops;
  final double progress;
  final double bearing;
  final double pulseValue;

  _TransitMapPainter({
    required this.stops,
    required this.progress,
    required this.bearing,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.6)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<Offset> points = [];
    final double startX = 60;
    final double endX = size.width - 60;
    final double centerY = size.height * 0.44;

    final numPoints = stops.isNotEmpty ? stops.length : 6;
    for (int i = 0; i < numPoints; i++) {
      final t = i / (numPoints - 1);
      final px = startX + (endX - startX) * t;
      final py = centerY + math.sin(t * math.pi * 1.5) * 70;
      points.add(Offset(px, py));
    }

    // 1. Draw Polyline Route
    final routePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, routePaint);

    final activePaint = Paint()
      ..color = AppTheme.emerald
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final activePath = Path();
    activePath.moveTo(points[0].dx, points[0].dy);

    final currentTargetIndex = (progress * (points.length - 1)).clamp(0.0, (points.length - 1).toDouble());
    final fullSegments = currentTargetIndex.floor();
    final segFraction = currentTargetIndex - fullSegments;

    for (int i = 1; i <= fullSegments && i < points.length; i++) {
      activePath.lineTo(points[i].dx, points[i].dy);
    }
    if (fullSegments < points.length - 1) {
      final p1 = points[fullSegments];
      final p2 = points[fullSegments + 1];
      activePath.lineTo(p1.dx + (p2.dx - p1.dx) * segFraction, p1.dy + (p2.dy - p1.dy) * segFraction);
    }
    canvas.drawPath(activePath, activePaint);

    // 2. Draw Stop Stations
    final stopNames = stops.isNotEmpty
        ? stops.map((s) => s.shortName).toList()
        : ['Gandhipuram', 'Lakshmi Mills', 'Nava India', 'Peelamedu', 'Fun Mall', 'Singanallur'];

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isMajor = i == 0 || i == points.length - 1;

      final stationOuter = Paint()..color = Colors.white;
      canvas.drawCircle(pt, isMajor ? 10 : 7, stationOuter);

      final stationBorder = Paint()
        ..color = isMajor ? AppTheme.emeraldDark : AppTheme.emerald
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(pt, isMajor ? 10 : 7, stationBorder);

      final textSpan = TextSpan(
        text: i < stopNames.length ? stopNames[i] : 'Stop $i',
        style: TextStyle(
          color: AppTheme.charcoal,
          fontSize: isMajor ? 11 : 10,
          fontWeight: isMajor ? FontWeight.w800 : FontWeight.w600,
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelY = (i % 2 == 0) ? pt.dy - 24 : pt.dy + 12;
      textPainter.paint(canvas, Offset(pt.dx - textPainter.width / 2, labelY));
    }

    // 3. Draw Live Bus Marker with Pulsing Radar
    Offset busOffset;
    if (fullSegments < points.length - 1) {
      final p1 = points[fullSegments];
      final p2 = points[fullSegments + 1];
      busOffset = Offset(p1.dx + (p2.dx - p1.dx) * segFraction, p1.dy + (p2.dy - p1.dy) * segFraction);
    } else {
      busOffset = points.last;
    }

    final radarPaint = Paint()
      ..color = AppTheme.amber.withOpacity((1.0 - pulseValue) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(busOffset, 16 + (pulseValue * 18), radarPaint);

    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.2);
    canvas.drawCircle(busOffset.translate(0, 4), 16, shadowPaint);

    final markerPaint = Paint()..color = AppTheme.amber;
    canvas.drawCircle(busOffset, 16, markerPaint);

    final markerBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(busOffset, 16, markerBorder);

    final iconSpan = const TextSpan(
      text: '🚌',
      style: TextStyle(fontSize: 16),
    );
    final iconPainter = TextPainter(
      text: iconSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, Offset(busOffset.dx - iconPainter.width / 2, busOffset.dy - iconPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TransitMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.bearing != bearing;
  }
}
