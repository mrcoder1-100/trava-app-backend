import 'package:flutter/material.dart';

class CouponModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final int discountAmount;
  final String merchantName;
  final String location;
  final String status;
  final String category; // 'BAKERY', 'RESTAURANT', 'SUPERMARKET', 'GYM'
  final String assignedAt;
  final String? expiresAt;
  final String? redeemedAt;

  CouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    required this.merchantName,
    required this.location,
    required this.status,
    required this.category,
    required this.assignedAt,
    this.expiresAt,
    this.redeemedAt,
  });

  bool get isRedeemed => status == 'REDEEMED' || redeemedAt != null;
  bool get isActive => status == 'ACTIVE' && !isRedeemed;

  String get categoryLabel {
    switch (category.toUpperCase()) {
      case 'RESTAURANT':
        return 'Restaurant';
      case 'SUPERMARKET':
        return 'Supermarket';
      case 'GYM':
        return 'Gym & Fitness';
      default:
        return 'Bakery & Sweets';
    }
  }

  String get categoryEmoji {
    switch (category.toUpperCase()) {
      case 'RESTAURANT':
        return '🍽️';
      case 'SUPERMARKET':
        return '🛒';
      case 'GYM':
        return '🏋️';
      default:
        return '🥐';
    }
  }

  IconData get categoryIcon {
    switch (category.toUpperCase()) {
      case 'RESTAURANT':
        return Icons.restaurant;
      case 'SUPERMARKET':
        return Icons.shopping_basket_outlined;
      case 'GYM':
        return Icons.fitness_center;
      default:
        return Icons.bakery_dining_outlined;
    }
  }

  Color get categoryColor {
    switch (category.toUpperCase()) {
      case 'RESTAURANT':
        return const Color(0xFFEA580C); // Warm Orange
      case 'SUPERMARKET':
        return const Color(0xFF0284C7); // Sky Blue
      case 'GYM':
        return const Color(0xFF7C3AED); // Vibrant Purple
      default:
        return const Color(0xFFD97706); // Amber Gold
    }
  }

  Color get categoryBgColor {
    switch (category.toUpperCase()) {
      case 'RESTAURANT':
        return const Color(0xFFFFF7ED);
      case 'SUPERMARKET':
        return const Color(0xFFF0F9FF);
      case 'GYM':
        return const Color(0xFFF5F3FF);
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  static String _deriveCategory(String? explicitCategory, String title, String merchant, String code) {
    if (explicitCategory != null && explicitCategory.isNotEmpty) {
      return explicitCategory.toUpperCase();
    }
    final s = '$title $merchant $code'.toLowerCase();
    if (s.contains('gym') || s.contains('fit') || s.contains('workout')) return 'GYM';
    if (s.contains('mart') || s.contains('nilgiri') || s.contains('pazham') || s.contains('supermarket') || s.contains('grocery')) return 'SUPERMARKET';
    if (s.contains('rest') || s.contains('hotel') || s.contains('bhavan') || s.contains('biryani') || s.contains('roast') || s.contains('meals') || s.contains('dining') || s.contains('a2b')) return 'RESTAURANT';
    return 'BAKERY';
  }

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] ?? 'Reward Coupon';
    final merchantName = json['merchantName'] ?? 'Annapoorna Bakery';
    final code = json['code'] ?? '';
    final category = _deriveCategory(json['category']?.toString(), title, merchantName, code);

    return CouponModel(
      id: json['id'] ?? '',
      code: code,
      title: title,
      description: json['description'] ?? '',
      discountAmount: json['discountAmount'] ?? 50,
      merchantName: merchantName,
      location: json['location'] ?? 'Gandhipuram, Coimbatore',
      status: json['status'] ?? 'ACTIVE',
      category: category,
      assignedAt: json['assignedAt'] ?? DateTime.now().toIso8601String(),
      expiresAt: json['expiresAt'],
      redeemedAt: json['redeemedAt'],
    );
  }
}
