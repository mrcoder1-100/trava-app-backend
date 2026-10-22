import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/bus_route.dart';
import '../../models/journey.dart';
import '../../services/api_service.dart';
import '../gps_sharing/active_sharing_screen.dart';

class CameraCheckScreen extends StatefulWidget {
  final String routeId;
  final String busId;
  final String busName;
  final String boardingStopId;
  final String destinationStopId;
  final BusRouteModel? route;
  final VoidCallback onJourneyCompleted;

  const CameraCheckScreen({
    super.key,
    required this.routeId,
    required this.busId,
    required this.busName,
    required this.boardingStopId,
    required this.destinationStopId,
    this.route,
    required this.onJourneyCompleted,
  });

  @override
  State<CameraCheckScreen> createState() => _CameraCheckScreenState();
}

class _CameraCheckScreenState extends State<CameraCheckScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  late AnimationController _laserController;
  Timer? _scanTimer;

  bool _photoCaptured = false;
  String _photoSource = 'CAMERA'; // 'CAMERA' or 'GALLERY'
  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _scanStatusText = 'Initializing scanner...';
  bool _isNotValid = false;
  bool _isStartingDemo = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  /// Triggers 4.5 second scan analysis that ALWAYS results in "Not Valid"
  void _triggerPhotoScan(String source) {
    if (_isScanning) return;

    setState(() {
      _photoCaptured = true;
      _photoSource = source;
      _isScanning = true;
      _scanProgress = 0.05;
      _scanStatusText = source == 'GALLERY'
          ? 'Scanning uploaded photo optical features...'
          : 'Scanning camera viewfinder capture...';
      _isNotValid = false;
    });

    _laserController.repeat(reverse: true);

    const int totalDurationMs = 4500; // 4.5 seconds scan time
    const int tickIntervalMs = 150;
    int elapsedMs = 0;

    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: tickIntervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      elapsedMs += tickIntervalMs;
      final progress = (elapsedMs / totalDurationMs).clamp(0.0, 1.0);

      String currentStatus = 'Scanning image features...';
      if (progress < 0.28) {
        currentStatus = 'Analyzing lighting, contrast & optical depth...';
      } else if (progress < 0.58) {
        currentStatus = 'Evaluating bus interior geometry & seat layout...';
      } else if (progress < 0.85) {
        currentStatus = 'Detecting passenger occupancy & ticket stamps...';
      } else {
        currentStatus = 'Running verification confidence model...';
      }

      setState(() {
        _scanProgress = progress;
        _scanStatusText = currentStatus;
      });

      if (elapsedMs >= totalDurationMs) {
        timer.cancel();
        _laserController.stop();

        setState(() {
          _isScanning = false;
          _isNotValid = true;
        });

        // Display the "Not Valid" prompt
        _showNotValidDialog();
      }
    });
  }

  void _showNotValidDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDC2626), width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 44),
                  ),
                ),
                const SizedBox(height: 16),

                // Not Valid Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NOT VALID',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'Photo Check: Not Valid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  _photoSource == 'GALLERY'
                      ? 'The uploaded photo could not be verified as an authentic bus interior or valid ticket. GPS sharing cannot be initiated with this image.'
                      : 'The captured image does not match verified Coimbatore bus interior patterns or active passenger tickets. GPS sharing is restricted to verified on-board passengers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade300,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // AI Detection Metrics Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      _buildMetricRow('Bus Interior Match', '14% (Req: 85%)', false),
                      const Divider(color: Colors.white12, height: 12),
                      _buildMetricRow('Ticket Stamp Detected', 'None Found', false),
                      const Divider(color: Colors.white12, height: 12),
                      _buildMetricRow('GPS Sharing Access', 'Blocked', false),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action 1: Verify Using Demo Credentials
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isStartingDemo
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                            _verifyUsingDemoCredentials();
                          },
                    icon: const Icon(Icons.verified_user, color: Colors.white),
                    label: const Text(
                      'Verify Using Demo Credentials',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Action 2: Try Another Photo
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      setState(() {
                        _photoCaptured = false;
                        _isNotValid = false;
                        _scanProgress = 0.0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Try Another Photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, String value, bool isOk) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: isOk ? AppTheme.emeraldLight : const Color(0xFFF87171),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _verifyUsingDemoCredentials() async {
    setState(() => _isStartingDemo = true);

    try {
      final route = widget.route;
      final stops = route?.stops ?? [];
      final boardingStop = stops.firstWhere(
        (s) => s.id == widget.boardingStopId,
        orElse: () => stops.isNotEmpty
            ? stops.first
            : StopModel(id: 'stop_1', name: 'Gandhipuram', shortName: 'Gandhipuram', sequence: 1, latitude: 11.016844, longitude: 76.967812, isMajorJunction: true),
      );
      final destStop = stops.firstWhere(
        (s) => s.id == widget.destinationStopId,
        orElse: () => stops.isNotEmpty
            ? stops.last
            : StopModel(id: 'stop_2', name: 'Singanallur', shortName: 'Singanallur', sequence: 2, latitude: 10.998055, longitude: 77.032011, isMajorJunction: true),
      );

      final journey = await _api.startJourney(
        routeId: widget.routeId,
        busId: widget.busId,
        boardingStopId: widget.boardingStopId,
        destinationStopId: widget.destinationStopId,
        mockVerification: true,
      );

      if (!mounted) return;

      final activeJourney = journey ??
          JourneyModel(
            id: 'jrn_demo_${DateTime.now().millisecondsSinceEpoch}',
            userId: 'usr_demo_coimbatore_01',
            routeId: widget.routeId,
            busId: widget.busId,
            busNumber: widget.busName,
            boardingStopId: widget.boardingStopId,
            boardingStopName: boardingStop.name,
            destinationStopId: widget.destinationStopId,
            destinationStopName: destStop.name,
            status: 'ACTIVE',
            startTime: DateTime.now().toIso8601String(),
            distanceKm: 0.0,
            pointsAwarded: 0,
            gpsPointsCount: 1,
          );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ActiveSharingScreen(
            journey: activeJourney,
            route: widget.route,
            onJourneyCompleted: widget.onJourneyCompleted,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error starting demo journey: $e');
    } finally {
      if (mounted) setState(() => _isStartingDemo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Camera Verification', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: _verifyUsingDemoCredentials,
            icon: const Icon(Icons.bolt, color: AppTheme.amber, size: 18),
            label: const Text(
              'Demo Bypass',
              style: TextStyle(color: AppTheme.amber, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instruction Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Camera check verifies bus interior or ticket to guarantee live transit data integrity.',
                      style: TextStyle(color: Colors.grey.shade300, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),

            // Live Camera Viewfinder & Scanner
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viewfinder Frame
                  Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isNotValid
                            ? const Color(0xFFEF4444)
                            : (_isScanning ? AppTheme.amber : Colors.white.withOpacity(0.2)),
                        width: _isScanning || _isNotValid ? 2.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _photoCaptured ? Icons.image_outlined : Icons.directions_bus_outlined,
                            size: 80,
                            color: _isNotValid
                                ? Colors.red.withOpacity(0.4)
                                : Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _photoCaptured
                                ? (_photoSource == 'GALLERY' ? 'UPLOADED PHOTO LOADED' : 'CAMERA PHOTO CAPTURED')
                                : 'LIVE CAMERA VIEWFINDER',
                            style: TextStyle(
                              color: _isNotValid
                                  ? const Color(0xFFF87171)
                                  : Colors.white.withOpacity(0.6),
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          if (_isNotValid) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'NOT VALID',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Viewfinder Corner Guides
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isNotValid
                            ? const Color(0xFFDC2626)
                            : (_isScanning ? AppTheme.amber : AppTheme.amber),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        if (!_isScanning && !_photoCaptured)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.center_focus_strong, color: AppTheme.amber, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  'Align Bus Interior / Ticket',
                                  style: TextStyle(color: AppTheme.amber, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),

                        // Moving Laser Scanner Beam
                        if (_isScanning)
                          AnimatedBuilder(
                            animation: _laserController,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserController.value * 230,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF38BDF8).withOpacity(0.8),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  // Mode Tag Pill
                  Positioned(
                    top: 36,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isNotValid ? Colors.red : AppTheme.amber,
                        ),
                      ),
                      child: Text(
                        _isNotValid
                            ? 'CHECK RESULT: NOT VALID'
                            : AppConstants.mockVerificationBadgeText,
                        style: TextStyle(
                          color: _isNotValid ? const Color(0xFFF87171) : AppTheme.amber,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Scanning Progress Overlay
                  if (_isScanning)
                    Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                color: Color(0xFF38BDF8),
                                strokeWidth: 3.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'ANALYZING (4-5s)',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _scanStatusText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _scanProgress,
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_scanProgress * 100).toInt()}% completed',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: Colors.black,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Upload Photo from Gallery
                      IconButton(
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                        tooltip: 'Upload photo from device',
                        onPressed: _isScanning ? null : () => _triggerPhotoScan('GALLERY'),
                      ),

                      // Large Shutter Button (Capture from Camera)
                      GestureDetector(
                        onTap: _isScanning ? null : () => _triggerPhotoScan('CAMERA'),
                        child: Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.amber,
                            ),
                            child: const Center(
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 30),
                            ),
                          ),
                        ),
                      ),

                      // Direct Demo Credentials Verification
                      IconButton(
                        icon: const Icon(Icons.verified_user, color: AppTheme.emeraldLight, size: 28),
                        tooltip: 'Verify Using Demo Credentials',
                        onPressed: _isScanning ? null : _verifyUsingDemoCredentials,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap shutter to take photo, or upload icon on left',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
