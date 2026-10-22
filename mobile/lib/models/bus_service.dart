class BusServiceModel {
  final String id;
  final String busNumber;
  final String vehicleReg;
  final String routeId;
  final String direction;
  final String crowdStatus;
  final String trackingStatus;
  final String locationFreshness;
  final bool isSimulated;
  final double currentProgress;
  final int speedKmH;
  final String currentStopId;
  final String nextStopId;
  final double currentLatitude;
  final double currentLongitude;
  final int bearing;
  final int etaMinutes;
  final double distanceRemainingKm;
  final String? activeContributorId;
  final String? activeContributorLabel;
  final String operatorName;
  final String operatorType;
  final String serviceType;

  BusServiceModel({
    required this.id,
    required this.busNumber,
    required this.vehicleReg,
    required this.routeId,
    required this.direction,
    required this.crowdStatus,
    required this.trackingStatus,
    required this.locationFreshness,
    required this.isSimulated,
    required this.currentProgress,
    required this.speedKmH,
    required this.currentStopId,
    required this.nextStopId,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.bearing,
    required this.etaMinutes,
    required this.distanceRemainingKm,
    this.activeContributorId,
    this.activeContributorLabel,
    this.operatorName = 'TNSTC - Coimbatore Division',
    this.operatorType = 'GOVERNMENT',
    this.serviceType = 'City Service',
  });

  bool get isGovernment => operatorType == 'GOVERNMENT';
  bool get isPrivate => operatorType == 'PRIVATE';

  BusServiceModel copyWith({
    String? id,
    String? busNumber,
    String? vehicleReg,
    String? routeId,
    String? direction,
    String? crowdStatus,
    String? trackingStatus,
    String? locationFreshness,
    bool? isSimulated,
    double? currentProgress,
    int? speedKmH,
    String? currentStopId,
    String? nextStopId,
    double? currentLatitude,
    double? currentLongitude,
    int? bearing,
    int? etaMinutes,
    double? distanceRemainingKm,
    String? activeContributorId,
    String? activeContributorLabel,
    String? operatorName,
    String? operatorType,
    String? serviceType,
  }) {
    return BusServiceModel(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      vehicleReg: vehicleReg ?? this.vehicleReg,
      routeId: routeId ?? this.routeId,
      direction: direction ?? this.direction,
      crowdStatus: crowdStatus ?? this.crowdStatus,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      locationFreshness: locationFreshness ?? this.locationFreshness,
      isSimulated: isSimulated ?? this.isSimulated,
      currentProgress: currentProgress ?? this.currentProgress,
      speedKmH: speedKmH ?? this.speedKmH,
      currentStopId: currentStopId ?? this.currentStopId,
      nextStopId: nextStopId ?? this.nextStopId,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      bearing: bearing ?? this.bearing,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      activeContributorId: activeContributorId ?? this.activeContributorId,
      activeContributorLabel: activeContributorLabel ?? this.activeContributorLabel,
      operatorName: operatorName ?? this.operatorName,
      operatorType: operatorType ?? this.operatorType,
      serviceType: serviceType ?? this.serviceType,
    );
  }

  factory BusServiceModel.fromJson(Map<String, dynamic> json) {
    return BusServiceModel(
      id: json['id'] ?? json['busId'] ?? '',
      busNumber: json['busNumber'] ?? 'Bus',
      vehicleReg: json['vehicleReg'] ?? '',
      routeId: json['routeId'] ?? '',
      direction: json['direction'] ?? 'OUTBOUND',
      crowdStatus: json['crowdStatus'] ?? 'SEATS_AVAILABLE',
      trackingStatus: json['trackingStatus'] ?? 'SIMULATED',
      locationFreshness: json['locationFreshness'] ?? 'LIVE',
      isSimulated: json['isSimulated'] ?? true,
      currentProgress: (json['currentProgress'] as num?)?.toDouble() ??
          (json['progress'] as num?)?.toDouble() ??
          0.0,
      speedKmH: json['speedKmH'] ?? 30,
      currentStopId: json['currentStopId'] ?? '',
      nextStopId: json['nextStopId'] ?? '',
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble() ??
          _defaultLat(json['routeId']?.toString() ?? '', json['id']?.toString() ?? ''),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble() ??
          _defaultLng(json['routeId']?.toString() ?? '', json['id']?.toString() ?? ''),
      bearing: json['bearing'] ?? 0,
      etaMinutes: () {
        final raw = (json['etaMinutes'] as num?)?.toInt() ?? 0;
        return raw >= 12 ? raw : 14;
      }(),
      distanceRemainingKm: () {
        final dist = (json['distanceRemainingKm'] as num?)?.toDouble() ?? 0.0;
        return dist >= 2.0 ? dist : 3.5;
      }(),
      activeContributorId: json['activeContributorId'],
      activeContributorLabel: json['activeContributorLabel'],
      operatorName: json['operatorName'] ?? 'TNSTC - Coimbatore Division',
      operatorType: json['operatorType'] ?? 'GOVERNMENT',
      serviceType: json['serviceType'] ?? 'City Service',
    );
  }

  static double _defaultLat(String routeId, String busId) {
    final r = routeId.toLowerCase();
    final b = busId.toLowerCase();
    if (r.contains('70') || b.contains('70')) return 10.9980;
    if (r.contains('20c') || b.contains('20c') || r.contains('20') || b.contains('20')) return 11.0500;
    if (r.contains('10a') || b.contains('10a') || r.contains('10') || b.contains('10')) return 11.0145;
    if (r.contains('111') || b.contains('111')) return 10.9950;
    return 11.0168;
  }

  static double _defaultLng(String routeId, String busId) {
    final r = routeId.toLowerCase();
    final b = busId.toLowerCase();
    if (r.contains('70') || b.contains('70')) return 77.0320;
    if (r.contains('20c') || b.contains('20c') || r.contains('20') || b.contains('20')) return 76.9850;
    if (r.contains('10a') || b.contains('10a') || r.contains('10') || b.contains('10')) return 76.9300;
    if (r.contains('111') || b.contains('111')) return 76.9620;
    return 76.9678;
  }
}
