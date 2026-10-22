import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/bus_route.dart';
import '../../models/journey.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';

class ActiveSharingScreen extends StatefulWidget {
  final JourneyModel journey;
  final BusRouteModel? route;
  final VoidCallback onJourneyCompleted;
  final bool isDemoCredentialsVerification;

  const ActiveSharingScreen({
    super.key,
    required this.journey,
    this.route,
    required this.onJourneyCompleted,
    this.isDemoCredentialsVerification = true,
  });

  @override
  State<ActiveSharingScreen> createState() => _ActiveSharingScreenState();
}

class _ActiveSharingScreenState extends State<ActiveSharingScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final LanguageService _langService = LanguageService();
  Timer? _gpsTimer;
  Timer? _locationCheckTimer;
  late AnimationController _pulseController;

  int _gpsPointsSent = 4;
  double _simulatedDistanceKm = 0.45;
  int _secondsElapsed = 0;
  bool _isStopping = false;
  bool _isLocationBlocked = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // If entered via demo credentials, allow in for 3 to 4 seconds, then check location
    if (widget.isDemoCredentialsVerification) {
      _locationCheckTimer = Timer(const Duration(milliseconds: 3500), () {
        if (!mounted) return;
        _triggerLocationMismatchAlert();
      });
    }

    // Send GPS coordinates batches every 3 seconds along the actual route corridor
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _isLocationBlocked) return;
      setState(() {
        _secondsElapsed += 3;
        _gpsPointsSent += 1;
        // In 3 seconds at ~26 km/h city speed, distance covered is ~0.022 km
        _simulatedDistanceKm += 0.022;
      });

      // Calculate GPS coordinates along the route stops between boarding and destination
      final stops = widget.route?.stops ?? [];
      int startIndex = stops.indexWhere((s) => s.id == widget.journey.boardingStopId);
      int destIndex = stops.indexWhere((s) => s.id == widget.journey.destinationStopId);
      if (startIndex < 0) startIndex = 0;
      if (destIndex < 0 || destIndex <= startIndex) {
        destIndex = stops.isNotEmpty ? stops.length - 1 : 0;
      }

      final segmentStops = (startIndex <= destIndex && stops.isNotEmpty)
          ? stops.sublist(startIndex, destIndex + 1)
          : stops;

      double curLat = 11.0168;
      double curLng = 76.9678;

      if (segmentStops.length >= 2) {
        // Authentic transit pacing: 26 km/h along the corridor
        final double totalSecondsForSegment = (segmentStops.length - 1) * 360.0; // ~6 mins per major stop
        final double progress = totalSecondsForSegment > 0
            ? (_secondsElapsed / totalSecondsForSegment).clamp(0.0, 1.0)
            : 0.0;
        final double segmentPos = progress * (segmentStops.length - 1);
        final int segIndex = segmentPos.floor().clamp(0, segmentStops.length - 2);
        final double segFraction = segmentPos - segIndex;

        final s1 = segmentStops[segIndex];
        final s2 = segmentStops[segIndex + 1];
        curLat = s1.latitude + (s2.latitude - s1.latitude) * segFraction;
        curLng = s1.longitude + (s2.longitude - s1.longitude) * segFraction;
      } else if (segmentStops.isNotEmpty) {
        curLat = segmentStops.first.latitude;
        curLng = segmentStops.first.longitude;
      }

      // Stream GPS batch to backend
      _api.sendGpsBatch(widget.journey.id, [
        {
          'latitude': curLat,
          'longitude': curLng,
          'accuracy': 6.5,
          'timestamp': DateTime.now().toIso8601String(),
        }
      ]);
    });
  }

  void _triggerLocationMismatchAlert() {
    _gpsTimer?.cancel();
    _pulseController.stop();

    setState(() {
      _isLocationBlocked = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDC2626), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.location_off_rounded, color: Color(0xFFDC2626), size: 42),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _langService.tr('location_not_valid'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _langService.tr('location_check_failed'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _langService.tr('location_mismatch_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade200,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(_langService.tr('route_corridor'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.route != null && widget.route!.origin.isNotEmpty
                              ? '${widget.route!.origin} ↔ ${widget.route!.destination}'
                              : _langService.translateRoute(widget.route?.name ?? 'Coimbatore Transit'),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(_langService.tr('current_device_location'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _langService.tr('out_of_transit_bounds'),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(color: Color(0xFFF87171), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(_langService.tr('gps_stream_status'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _langService.tr('terminated_status'),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(color: Color(0xFFF87171), fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  _langService.tr('return_to_routes'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _locationCheckTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleStopJourney() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_langService.tr('complete_bus_journey_title')),
        content: Text(_langService.tr('complete_bus_journey_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_langService.tr('continue_sharing_btn')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_langService.tr('stop_claim_points_btn')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isStopping = true);
    _gpsTimer?.cancel();

    final result = await _api.stopJourney(widget.journey.id);

    if (!mounted) return;

    setState(() => _isStopping = false);

    if (result != null && result['success'] == true) {
      final pointsResult = result['pointsResult'];
      final pointsAwarded = pointsResult?['pointsAwarded'] ?? 50;
      final newBalance = pointsResult?['currentBalance'] ?? 100;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.stars, color: AppTheme.amber, size: 28),
              const SizedBox(width: 10),
              Text(_langService.tr('points_awarded_title')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '+$pointsAwarded ${_langService.tr('points_earned_label')}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.emerald,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_langService.tr('total_balance_label')} $newBalance ${_langService.tr('pts')}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard, color: Color(0xFF78350F)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _langService.tr('target_reached_scratch'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Back to main
                widget.onJourneyCompleted(); // Switch to Rewards Tab!
              },
              child: Text(_langService.tr('open_rewards_scratch_btn')),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to complete journey. Please check connection.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text(_langService.tr('sharing_live_gps'), style: const TextStyle(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Transmission Card with Pulsing Radar
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLocationBlocked
                        ? const [Color(0xFF7F1D1D), Color(0xFF450A0A)]
                        : const [Color(0xFF0F4C3A), Color(0xFF0A3327)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (_isLocationBlocked ? Colors.red : AppTheme.emerald).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Radar Animation or Blocked Icon
                    _isLocationBlocked
                        ? Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFDC2626),
                            ),
                            child: const Center(
                              child: Icon(Icons.location_off_rounded, color: Colors.white, size: 38),
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 80 + (_pulseController.value * 30),
                                    height: 80 + (_pulseController.value * 30),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.amber.withOpacity((1.0 - _pulseController.value) * 0.4),
                                    ),
                                  ),
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.amber,
                                    ),
                                    child: const Icon(Icons.satellite_alt, color: Colors.white, size: 36),
                                  ),
                                ],
                              );
                            },
                          ),
                    const SizedBox(height: 20),

                    Text(
                      _isLocationBlocked
                          ? _langService.tr('location_not_valid')
                          : _langService.tr('contribution_broadcast_active'),
                      style: TextStyle(
                        color: _isLocationBlocked ? const Color(0xFFFCA5A5) : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLocationBlocked
                          ? _langService.tr('location_mismatch_desc')
                          : _langService.tr('active_transmitting_sub'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Telemetry Grid
              Row(
                children: [
                  Expanded(
                    child: _telemetryCard(
                      _langService.tr('label_distance'),
                      '${_simulatedDistanceKm.toStringAsFixed(2)} ${_langService.tr('km')}',
                      _langService.tr('label_min_distance'),
                      Icons.route,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _telemetryCard(
                      _langService.tr('label_gps_records'),
                      '$_gpsPointsSent ${_langService.tr('label_sent')}',
                      _langService.tr('label_accuracy'),
                      Icons.gps_fixed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _telemetryCard(
                      _langService.tr('label_points'),
                      '+50 ${_langService.tr('pts')}',
                      _langService.tr('label_guaranteed'),
                      Icons.stars,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Journey Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _langService.translateBus(widget.journey.busNumber),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.liveGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _langService.tr('verified_on_bus'),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.liveGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        const Icon(Icons.trip_origin, size: 16, color: AppTheme.emerald),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _langService.translateStop(widget.journey.boardingStopName),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 7),
                      child: SizedBox(
                        height: 16,
                        child: VerticalDivider(color: AppTheme.muted, thickness: 1.5),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: AppTheme.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _langService.translateStop(widget.journey.destinationStopName),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Stop Sharing or Return to Routes Button
              ElevatedButton.icon(
                onPressed: _isLocationBlocked
                    ? () => Navigator.of(context).pop()
                    : (_isStopping ? null : _handleStopJourney),
                icon: Icon(_isLocationBlocked ? Icons.arrow_back : Icons.stop_circle_outlined, size: 22),
                label: _isStopping
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_isLocationBlocked ? _langService.tr('return_to_routes') : _langService.tr('stop_claim_points_btn')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telemetryCard(String label, String value, String subtext, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.emerald),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.muted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.charcoal)),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 10, color: AppTheme.muted)),
        ],
      ),
    );
  }
}
