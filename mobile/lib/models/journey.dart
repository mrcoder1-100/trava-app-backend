class JourneyModel {
  final String id;
  final String userId;
  final String routeId;
  final String busId;
  final String busNumber;
  final String boardingStopId;
  final String boardingStopName;
  final String destinationStopId;
  final String destinationStopName;
  final String status;
  final String startTime;
  final String? endTime;
  final double distanceKm;
  final int pointsAwarded;
  final int gpsPointsCount;

  JourneyModel({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.busId,
    required this.busNumber,
    required this.boardingStopId,
    required this.boardingStopName,
    required this.destinationStopId,
    required this.destinationStopName,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.pointsAwarded,
    required this.gpsPointsCount,
  });

  factory JourneyModel.fromJson(Map<String, dynamic> json) {
    return JourneyModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      routeId: json['routeId'] ?? '',
      busId: json['busId'] ?? '',
      busNumber: json['busNumber'] ?? 'Bus',
      boardingStopId: json['boardingStopId'] ?? '',
      boardingStopName: json['boardingStopName'] ?? '',
      destinationStopId: json['destinationStopId'] ?? '',
      destinationStopName: json['destinationStopName'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      startTime: json['startTime'] ?? DateTime.now().toIso8601String(),
      endTime: json['endTime'],
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      pointsAwarded: json['pointsAwarded'] ?? 0,
      gpsPointsCount: json['gpsPointsCount'] ?? 0,
    );
  }
}
