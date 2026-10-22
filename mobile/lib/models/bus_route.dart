class StopModel {
  final String id;
  final String name;
  final String shortName;
  final int sequence;
  final double latitude;
  final double longitude;
  final bool isMajorJunction;

  StopModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.sequence,
    required this.latitude,
    required this.longitude,
    required this.isMajorJunction,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? json['name'] ?? '',
      sequence: json['sequence'] ?? 1,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isMajorJunction: json['isMajorJunction'] ?? false,
    );
  }
}

class BusRouteModel {
  final String id;
  final String routeNumber;
  final String name;
  final String city;
  final String origin;
  final String destination;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final List<StopModel> stops;
  final String direction;

  BusRouteModel({
    required this.id,
    required this.routeNumber,
    required this.name,
    required this.city,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.stops,
    required this.direction,
  });

  factory BusRouteModel.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'] as List? ?? [];
    return BusRouteModel(
      id: json['id'] ?? '',
      routeNumber: json['routeNumber'] ?? '',
      name: json['name'] ?? '',
      city: json['city'] ?? 'Coimbatore',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMinutes: json['estimatedDurationMinutes'] ?? 0,
      stops: rawStops.map((s) => StopModel.fromJson(s)).toList(),
      direction: json['direction'] ?? 'OUTBOUND',
    );
  }
}
