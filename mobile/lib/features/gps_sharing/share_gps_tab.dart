import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_route.dart';
import '../../models/bus_service.dart';
import '../../models/journey.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../common/language_selector_sheet.dart';
import '../verification/camera_check_screen.dart';
import 'active_sharing_screen.dart';

class ShareGpsTab extends StatefulWidget {
  final VoidCallback onJourneyCompleted;
  const ShareGpsTab({super.key, required this.onJourneyCompleted});

  @override
  State<ShareGpsTab> createState() => _ShareGpsTabState();
}

class _ShareGpsTabState extends State<ShareGpsTab> {
  final ApiService _api = ApiService();
  final LanguageService _langService = LanguageService();

  String _selectedCity = 'Coimbatore';
  String _selectedRouteId = 'route_95';
  String _selectedBusId = 'bus_95_a';
  String _selectedBoardingStopId = 'stop_gandhipuram';
  String _selectedDestinationStopId = 'stop_singanallur';

  List<BusRouteModel> _routes = [];
  List<BusServiceModel> _buses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final routes = await _api.getRoutes();
    final routeId = _selectedRouteId;
    final buses = await _api.getRouteBuses(routeId);

    if (mounted) {
      setState(() {
        _routes = routes;
        _buses = buses;
        if (buses.isNotEmpty) {
          _selectedBusId = buses.first.id;
        }
        final currentRoute = routes.firstWhere((r) => r.id == routeId, orElse: () => routes.first);
        if (currentRoute.stops.isNotEmpty) {
          _selectedBoardingStopId = currentRoute.stops.first.id;
          _selectedDestinationStopId = currentRoute.stops.last.id;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onRouteChanged(String newRouteId) async {
    setState(() {
      _selectedRouteId = newRouteId;
      _isLoading = true;
    });
    final buses = await _api.getRouteBuses(newRouteId);
    final currentRoute = _routes.firstWhere((r) => r.id == newRouteId, orElse: () => _routes.first);
    if (mounted) {
      setState(() {
        _buses = buses;
        if (buses.isNotEmpty) {
          _selectedBusId = buses.first.id;
        }
        if (currentRoute.stops.isNotEmpty) {
          _selectedBoardingStopId = currentRoute.stops.first.id;
          _selectedDestinationStopId = currentRoute.stops.last.id;
        }
        _isLoading = false;
      });
    }
  }

  bool _isStartingDemoJourney = false;

  void _proceedToCameraCheck() {
    final route = _routes.firstWhere((r) => r.id == _selectedRouteId, orElse: () => _routes.first);
    final bus = _buses.firstWhere((b) => b.id == _selectedBusId, orElse: () => _buses.first);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraCheckScreen(
          routeId: _selectedRouteId,
          busId: _selectedBusId,
          busName: bus.busNumber,
          boardingStopId: _selectedBoardingStopId,
          destinationStopId: _selectedDestinationStopId,
          route: route,
          onJourneyCompleted: widget.onJourneyCompleted,
        ),
      ),
    );
  }

  Future<void> _verifyUsingDemoCredentials() async {
    setState(() => _isStartingDemoJourney = true);

    try {
      final route = _routes.firstWhere((r) => r.id == _selectedRouteId, orElse: () => _routes.first);
      final bus = _buses.firstWhere((b) => b.id == _selectedBusId, orElse: () => _buses.first);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.verified, color: AppTheme.amberLight),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo credentials verified! Connecting live GPS...',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF0F4C3A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final journey = await _api.startJourney(
        routeId: _selectedRouteId,
        busId: _selectedBusId,
        boardingStopId: _selectedBoardingStopId,
        destinationStopId: _selectedDestinationStopId,
        mockVerification: true,
      );

      if (!mounted) return;

      final boardingStop = route.stops.firstWhere(
        (s) => s.id == _selectedBoardingStopId,
        orElse: () => route.stops.isNotEmpty
            ? route.stops.first
            : StopModel(
                id: 'stop_1',
                name: 'Gandhipuram',
                shortName: 'Gandhipuram',
                sequence: 1,
                latitude: 11.016844,
                longitude: 76.967812,
                isMajorJunction: true,
              ),
      );
      final destStop = route.stops.firstWhere(
        (s) => s.id == _selectedDestinationStopId,
        orElse: () => route.stops.isNotEmpty
            ? route.stops.last
            : StopModel(
                id: 'stop_2',
                name: 'Singanallur',
                shortName: 'Singanallur',
                sequence: 2,
                latitude: 10.998055,
                longitude: 77.032011,
                isMajorJunction: true,
              ),
      );

      final activeJourney = journey ??
          JourneyModel(
            id: 'jrn_demo_${DateTime.now().millisecondsSinceEpoch}',
            userId: 'usr_demo_coimbatore_01',
            routeId: _selectedRouteId,
            busId: _selectedBusId,
            busNumber: bus.busNumber,
            boardingStopId: _selectedBoardingStopId,
            boardingStopName: boardingStop.name,
            destinationStopId: _selectedDestinationStopId,
            destinationStopName: destStop.name,
            status: 'ACTIVE',
            startTime: DateTime.now().toIso8601String(),
            distanceKm: 0.0,
            pointsAwarded: 0,
            gpsPointsCount: 1,
          );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActiveSharingScreen(
            journey: activeJourney,
            route: route,
            onJourneyCompleted: widget.onJourneyCompleted,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error starting demo journey: $e');
    } finally {
      if (mounted) {
        setState(() => _isStartingDemoJourney = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = _routes.firstWhere(
      (r) => r.id == _selectedRouteId,
      orElse: () => _routes.isNotEmpty
          ? _routes.first
          : BusRouteModel(
              id: 'route_95',
              routeNumber: '95',
              name: 'Gandhipuram ↔ Singanallur',
              city: 'Coimbatore',
              origin: 'Gandhipuram',
              destination: 'Singanallur',
              distanceKm: 10,
              estimatedDurationMinutes: 30,
              direction: 'OUTBOUND',
              stops: const [],
            ),
    );

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text(_langService.tr('nav_share_gps'), style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: const [
          QuickLanguagePill(),
          SizedBox(width: 14),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.emerald))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Feature Introduction Banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F4C3A), Color(0xFF166A51)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.emerald.withOpacity(0.2),
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
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.volunteer_activism, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _langService.tr('community_bus_tracking_title'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _langService.tr('share_journey_desc'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _langService.tr('share_gps_rewards_desc'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Privacy & Voluntary sharing card
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
                  const SizedBox(height: 24),

                  // Journey Configuration Card
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

                        // Route Selection
                        _buildFieldLabel(_langService.tr('transit_route')),
                        DropdownButtonFormField<String>(
                          value: _routes.any((r) => r.id == _selectedRouteId)
                              ? _selectedRouteId
                              : (_routes.isNotEmpty ? _routes.first.id : null),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _routes.map((r) {
                            return DropdownMenuItem(
                              value: r.id,
                              child: Text(
                                '${_langService.tr('route_prefix')} ${r.routeNumber}: ${_langService.translateRoute(r.name)}',
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

                        // Bus Selection
                        _buildFieldLabel(_langService.tr('which_bus')),
                        DropdownButtonFormField<String>(
                          value: _buses.any((b) => b.id == _selectedBusId)
                              ? _selectedBusId
                              : (_buses.isNotEmpty ? _buses.first.id : null),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: _buses.map((bus) {
                            return DropdownMenuItem(
                              value: bus.id,
                              child: Text(
                                '${_langService.translateBus(bus.busNumber)} (${bus.vehicleReg})',
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
                          value: currentRoute.stops.any((s) => s.id == _selectedBoardingStopId)
                              ? _selectedBoardingStopId
                              : (currentRoute.stops.isNotEmpty ? currentRoute.stops.first.id : null),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: currentRoute.stops.map((stop) {
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
                          value: currentRoute.stops.any((s) => s.id == _selectedDestinationStopId)
                              ? _selectedDestinationStopId
                              : (currentRoute.stops.isNotEmpty ? currentRoute.stops.last.id : null),
                          isExpanded: true,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: currentRoute.stops.map((stop) {
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Verify Using Demo Credentials Button (Instant Community Sharing)
                  ElevatedButton.icon(
                    onPressed: _isStartingDemoJourney ? null : _verifyUsingDemoCredentials,
                    icon: _isStartingDemoJourney
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(Icons.verified_user, color: Colors.white),
                    label: Text(
                      _isStartingDemoJourney
                          ? _langService.tr('starting_demo_sharing')
                          : _langService.tr('verify_demo_credentials'),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.3),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 3,
                      shadowColor: AppTheme.emerald.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Camera Photo Verification Button
                  OutlinedButton.icon(
                    onPressed: _proceedToCameraCheck,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(_langService.tr('verify_photo_btn')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppTheme.emerald, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      foregroundColor: AppTheme.emeraldDark,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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
