import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme.dart';
import '../../models/bus_route.dart';
import '../../models/bus_service.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../common/language_selector_sheet.dart';
import 'bus_map_screen.dart';
import '../../services/voice_service.dart';

class TrackBusTab extends StatefulWidget {
  const TrackBusTab({super.key});

  @override
  State<TrackBusTab> createState() => _TrackBusTabState();
}

class _TrackBusTabState extends State<TrackBusTab> {
  final ApiService _api = ApiService();
  final LanguageService _langService = LanguageService();
  Timer? _refreshTimer;

  final String _selectedCity = 'Coimbatore';
  String _selectedOrigin = 'Gandhipuram';
  String _selectedDestination = 'Singanallur';

  List<BusRouteModel> _routes = [];
  Map<String, List<BusServiceModel>> _routeBusesMap = {};
  List<BusRouteModel> _matchedRoutes = [];
  bool _isLoading = true;
  BusServiceModel? _selectedBus;

  // Curated list of popular Coimbatore stops
  final List<String> _fallbackStops = [
    'Gandhipuram',
    'Lakshmi Mills',
    'Nava India',
    'Peelamedu',
    'Fun Mall Area',
    'Singanallur',
    'Railway Station',
    'Collectorate',
    'Town Hall',
    'Ukkadam',
    'Ganapathy',
    'Prozone Mall',
    'CHIL SEZ',
    'Saravanampatti',
    'Ramanathapuram',
    'Sungam',
    'Valankulam Lake',
    'RS Puram',
    'Lawley Road',
    'TNAU',
    'Vadavalli',
  ];

  List<String> get _availableStops {
    final Set<String> stops = {};
    for (final r in _routes) {
      for (final s in r.stops) {
        stops.add(s.shortName);
      }
    }
    if (stops.isEmpty) return _fallbackStops;
    return stops.toList();
  }

  final List<Map<String, String>> _popularCorridors = [
    {'origin': 'Gandhipuram', 'dest': 'Singanallur', 'label': 'Route 95 · Peelamedu'},
    {'origin': 'Gandhipuram', 'dest': 'Ukkadam', 'label': 'Route 111 · Railway Stn'},
    {'origin': 'Gandhipuram', 'dest': 'Saravanampatti', 'label': 'Route 20C · IT Corridor'},
    {'origin': 'Singanallur', 'dest': 'Ukkadam', 'label': 'Route 70 · Sungam Ring'},
    {'origin': 'Gandhipuram', 'dest': 'Vadavalli', 'label': 'Route 10A · RS Puram'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRoutesAndBuses();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshLiveBusesOnly();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLiveBusesOnly() async {
    if (!mounted || _routes.isEmpty) return;
    try {
      final targetRoutes = _matchedRoutes.isNotEmpty ? _matchedRoutes : _routes;
      final Map<String, List<BusServiceModel>> updatedMap = Map.from(_routeBusesMap);
      for (final route in targetRoutes) {
        final buses = await _api.getRouteBuses(route.id);
        if (buses.isNotEmpty) {
          updatedMap[route.id] = buses;
        }
      }
      if (mounted) {
        setState(() {
          _routeBusesMap = updatedMap;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchRoutesAndBuses() async {
    setState(() => _isLoading = true);
    final routes = await _api.getRoutes();
    final Map<String, List<BusServiceModel>> busesMap = {};

    for (final route in routes) {
      final buses = await _api.getRouteBuses(route.id);
      busesMap[route.id] = buses;
    }

    if (mounted) {
      setState(() {
        _routes = routes;
        _routeBusesMap = busesMap;
        _isLoading = false;
        _executeSearch();
      });
    }
  }

  void _executeSearch() {
    setState(() {
      // Filter routes that connect origin and destination
      _matchedRoutes = _routes.where((route) {
        final stopNames = route.stops.map((s) => s.shortName.toLowerCase()).toList();
        final originLower = _selectedOrigin.toLowerCase();
        final destLower = _selectedDestination.toLowerCase();

        final hasOrigin = stopNames.any((name) => name.contains(originLower) || originLower.contains(name));
        final hasDest = stopNames.any((name) => name.contains(destLower) || destLower.contains(name));

        // Both stops must be on this route
        return hasOrigin && hasDest;
      }).toList();
    });
  }

  void _swapStops() {
    setState(() {
      final temp = _selectedOrigin;
      _selectedOrigin = _selectedDestination;
      _selectedDestination = temp;
    });
    _executeSearch();
  }

  void _selectCorridor(String origin, String dest) {
    setState(() {
      _selectedOrigin = origin;
      _selectedDestination = dest;
    });
    _executeSearch();
  }

  void _openMap(BusServiceModel bus, BusRouteModel route) {
    // If we have a fresher snapshot in _routeBusesMap, pass that directly
    final freshBuses = _routeBusesMap[route.id] ?? [];
    final freshBus = freshBuses.firstWhere((b) => b.id == bus.id, orElse: () => bus);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusMapScreen(
          bus: freshBus,
          route: route,
          boardingStop: _selectedOrigin,
          destinationStop: _selectedDestination,
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

  @override
  Widget build(BuildContext context) {
    final stopsList = _availableStops;
    // Ensure selected stops exist in available stops
    if (!stopsList.contains(_selectedOrigin) && stopsList.isNotEmpty) {
      _selectedOrigin = stopsList.first;
    }
    if (!stopsList.contains(_selectedDestination) && stopsList.isNotEmpty) {
      _selectedDestination = stopsList.length > 1 ? stopsList[1] : stopsList.first;
    }

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text(
          _langService.tr('nav_track_bus'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          const QuickLanguagePill(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Routes & Buses',
            onPressed: _fetchRoutesAndBuses,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.emerald))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // City & Demo Mode Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_city, size: 18, color: AppTheme.emerald),
                            const SizedBox(width: 8),
                            Text(
                              '${_langService.tr('city_label')}: ${_langService.translateStop(_selectedCity)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.emeraldDark),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                          ),
                          child: Text(
                            _langService.tr('badge_demo_mode'),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stop Selection Card (Origin, Swap, Destination)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Starting Stop
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.trip_origin, color: AppTheme.emerald, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _langService.tr('starting_point_label'),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 0.5),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedOrigin,
                                      isExpanded: true,
                                      items: stopsList.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(_langService.translateStop(s), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedOrigin = val);
                                          _executeSearch();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Middle Divider with Swap Button
                        Row(
                          children: [
                            const Expanded(child: Divider(height: 1, color: AppTheme.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: InkWell(
                                onTap: _swapStops,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.offWhite,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: const Icon(Icons.swap_vert, size: 18, color: AppTheme.emerald),
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(height: 1, color: AppTheme.border)),
                          ],
                        ),

                        // Destination Stop
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.amber.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on, color: AppTheme.amber, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _langService.tr('destination_point_label'),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 0.5),
                                  ),
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDestination,
                                      isExpanded: true,
                                      items: stopsList.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(_langService.translateStop(s), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedDestination = val);
                                          _executeSearch();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dedicated Search Button under Start and End Points
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _executeSearch,
                      icon: const Icon(Icons.search, size: 20),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _langService.tr('search_available_routes_btn'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Popular Corridor Chips
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _langService.tr('popular_coimbatore_corridors'),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _popularCorridors.map((c) {
                            final isCurrent = _selectedOrigin == c['origin'] && _selectedDestination == c['dest'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(_langService.translateCorridorLabel(c['label']!)),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent ? Colors.white : AppTheme.charcoal,
                                ),
                                backgroundColor: isCurrent ? AppTheme.emerald : Colors.white,
                                side: BorderSide(
                                  color: isCurrent ? AppTheme.emerald : AppTheme.border,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onPressed: () => _selectCorridor(c['origin']!, c['dest']!),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Route Search Results Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.alt_route, size: 18, color: AppTheme.emerald),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _matchedRoutes.isEmpty
                                      ? _langService.tr('no_direct_routes_found')
                                      : '${_langService.tr('available_routes')} (${_matchedRoutes.length})',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.liveGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _langService.tr('live_simulation'),
                          style: const TextStyle(color: AppTheme.liveGreen, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_langService.translateStop(_selectedOrigin)} → ${_langService.translateStop(_selectedDestination)}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),

                  // If matched routes found, render each route with its buses
                  if (_matchedRoutes.isNotEmpty)
                    ..._matchedRoutes.map((route) => _buildRouteSection(route))
                  else
                    _buildNoDirectRoutesCard(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildRouteSection(BusRouteModel route) {
    final buses = _routeBusesMap[route.id] ?? [];
    final govtCount = buses.where((b) => b.isGovernment).length;
    final privCount = buses.where((b) => b.isPrivate).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.emerald.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emerald.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Route Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Route Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_langService.tr('route_prefix')} ${route.routeNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    // Distance & Duration
                    Text(
                      '${route.distanceKm} km · ~${route.estimatedDurationMinutes} ${_langService.tr('mins_unit')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.emeraldDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _langService.translateRoute(route.name),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                // Operator Breakdown Tag
                Row(
                  children: [
                    const Icon(Icons.directions_bus, size: 14, color: AppTheme.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${buses.length} ${_langService.tr('active_buses_count')} ($govtCount ${_langService.tr('govt_label')} · $privCount ${_langService.tr('private_label')})',
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Buses list for this route
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (buses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Text(
                        _langService.tr('no_buses_running'),
                        style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...buses.map((bus) => _buildBusCard(bus, route)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusServiceModel bus, BusRouteModel route) {
    final isSelected = _selectedBus?.id == bus.id;

    Color crowdColor = AppTheme.liveGreen;
    String crowdLabel = _langService.tr('seats_available');
    if (bus.crowdStatus == 'PACKED') {
      crowdColor = Colors.red;
      crowdLabel = _langService.tr('packed');
    } else if (bus.crowdStatus == 'EMPTY') {
      crowdColor = Colors.blue;
      crowdLabel = _langService.tr('empty');
    }

    final isGovt = bus.isGovernment;

    // Accurate ETA to passenger's selected boarding / pickup stop
    int displayEta = 5;
    if (route.stops.isNotEmpty) {
      final originLower = _selectedOrigin.toLowerCase().trim();
      final oStop = route.stops.firstWhere(
        (s) =>
            s.shortName.toLowerCase().contains(originLower) ||
            originLower.contains(s.shortName.toLowerCase()) ||
            s.name.toLowerCase().contains(originLower) ||
            originLower.contains(s.name.toLowerCase()),
        orElse: () => route.stops.first,
      );
      final oDistKm = _calcDistanceKm(
        bus.currentLatitude,
        bus.currentLongitude,
        oStop.latitude,
        oStop.longitude,
      ) * 1.18;
      final speed = bus.speedKmH > 10 ? bus.speedKmH.toDouble() : 25.0;
      final calc = ((oDistKm / speed) * 60).round();
      if (oDistKm < 0.25) {
        displayEta = 1;
      } else {
        displayEta = calc < 1 ? 1 : calc;
      }
    } else {
      displayEta = bus.etaMinutes > 0 ? bus.etaMinutes : 5;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.emerald : AppTheme.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppTheme.emerald.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _selectedBus = bus);
          _openMap(bus, route);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operator Badge & Bus Number Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Operator Pill
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isGovt ? const Color(0xFFE0E7FF) : const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isGovt ? const Color(0xFF6366F1).withValues(alpha: 0.3) : const Color(0xFFA855F7).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isGovt ? '🏛️ ' : '🏢 ',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Flexible(
                            child: Text(
                              isGovt ? 'TNSTC Govt' : bus.operatorName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isGovt ? const Color(0xFF3730A3) : const Color(0xFF6B21A8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Audio Announcement Button (Announces Arrival at Pickup Stop)
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          VoiceService().announceBusArrival(
                            busNumber: bus.busNumber,
                            pickupStop: _selectedOrigin,
                            destinationStop: _selectedDestination,
                            etaMinutes: displayEta,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Text('🔊 ', style: TextStyle(fontSize: 16)),
                                  Expanded(
                                    child: Text(
                                      'Voice: ${bus.busNumber} arriving at $_selectedOrigin in $displayEta mins',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.emeraldDark,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3EF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_up, size: 13, color: AppTheme.emerald),
                              SizedBox(width: 4),
                              Text('Audio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.emerald)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Live ETA Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 13, color: Color(0xFF78350F)),
                            const SizedBox(width: 4),
                            Text(
                              '$displayEta ${_langService.tr('min_eta')}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bus Name & Vehicle Reg
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isGovt ? AppTheme.emerald.withOpacity(0.1) : const Color(0xFF9333EA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: isGovt ? AppTheme.emerald : const Color(0xFF9333EA),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _langService.translateBus(bus.busNumber),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              bus.vehicleReg,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '• ${bus.serviceType}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar along Route
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: bus.currentProgress.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isGovt ? AppTheme.emerald : const Color(0xFF9333EA),
                  ),
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 10),

              // Status Metrics Footer (Crowd, Speed, Open Map)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: crowdColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            crowdLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: crowdColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${bus.speedKmH} km/h',
                          style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _langService.tr('open_live_map'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isGovt ? AppTheme.emerald : const Color(0xFF9333EA),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: isGovt ? AppTheme.emerald : const Color(0xFF9333EA),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDirectRoutesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 40, color: AppTheme.amber),
          const SizedBox(height: 12),
          Text(
            _langService.tr('no_direct_route_connecting'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
          ),
          const SizedBox(height: 4),
          Text(
            '${_langService.translateStop(_selectedOrigin)} → ${_langService.translateStop(_selectedDestination)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.muted),
          ),
          const SizedBox(height: 10),
          Text(
            _langService.tr('pro_tip_routes'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _matchedRoutes = List.from(_routes);
              });
            },
            icon: const Icon(Icons.view_list, size: 16),
            label: Text(_langService.tr('show_all_routes_btn')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
