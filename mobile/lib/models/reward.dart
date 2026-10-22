class LedgerEntryModel {
  final String id;
  final String type;
  final int points;
  final int balanceAfter;
  final String description;
  final String createdAt;

  LedgerEntryModel({
    required this.id,
    required this.type,
    required this.points,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return LedgerEntryModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      points: json['points'] ?? 0,
      balanceAfter: json['balanceAfter'] ?? 0,
      description: json['description'] ?? '',
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }
}

class ScratchCardModel {
  final String id;
  final String status;
  final int targetPoints;
  final int currentPoints;
  final String unlockReason;
  final bool isGuaranteedReward;
  final Map<String, dynamic>? reward;

  ScratchCardModel({
    required this.id,
    required this.status,
    required this.targetPoints,
    required this.currentPoints,
    required this.unlockReason,
    required this.isGuaranteedReward,
    this.reward,
  });

  factory ScratchCardModel.fromJson(Map<String, dynamic> json) {
    return ScratchCardModel(
      id: json['id'] ?? '',
      status: json['status'] ?? 'LOCKED',
      targetPoints: json['targetPoints'] ?? 100,
      currentPoints: json['currentPoints'] ?? 0,
      unlockReason: json['unlockReason'] ?? '',
      isGuaranteedReward: json['isGuaranteedReward'] ?? true,
      reward: json['reward'] as Map<String, dynamic>?,
    );
  }
}
