import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../models/bus_route.dart';
import '../models/bus_service.dart';
import '../models/journey.dart';
import '../models/reward.dart';
import '../models/coupon.dart';

class ApiService extends ChangeNotifier {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = AppConstants.defaultBaseUrl;
  String? _token;
  UserModel? _currentUser;
  bool _isOnline = true;
  bool _isNoNetMode = false;
  final List<Map<String, dynamic>> _offlineGpsQueue = [];

  String get baseUrl => _baseUrl;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isOnline => !_isNoNetMode && _isOnline;
  bool get isNoNetMode => _isNoNetMode;
  int get offlineQueueCount => _offlineGpsQueue.length;
  List<Map<String, dynamic>> get offlineQueue => List.unmodifiable(_offlineGpsQueue);

  void setNoNetMode(bool value) {
    _isNoNetMode = value;
    if (_isNoNetMode) {
      _isOnline = false;
    } else {
      _isOnline = true;
    }
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('trava_jwt_token');
    final savedBaseUrl = prefs.getString('trava_base_url');
    if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
      _baseUrl = savedBaseUrl;
    }
    final savedUserJson = prefs.getString('trava_user_data');
    if (savedUserJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trava_base_url', _baseUrl);
    notifyListeners();
  }

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Helper HTTP methods with smart auto-fallback between USB debugging (localhost:5000)
  // and local Wi-Fi IP (10.198.87.40:5000) on physical mobile devices.
  Future<http.Response> _get(String path) async {
    try {
      return await http.get(Uri.parse('$_baseUrl$path'), headers: _headers()).timeout(const Duration(seconds: 4));
    } catch (e) {
      if (!kIsWeb) {
        final alt = _baseUrl.contains('localhost')
            ? 'http://10.198.87.40:5000/api/v1'
            : (_baseUrl.contains('10.198.87.40') ? 'http://localhost:5000/api/v1' : null);
        if (alt != null) {
          try {
            final res = await http.get(Uri.parse('$alt$path'), headers: _headers()).timeout(const Duration(seconds: 4));
            if (res.statusCode < 500) {
              setBaseUrl(alt);
              return res;
            }
          } catch (_) {}
        }
      }
      rethrow;
    }
  }

  Future<http.Response> _post(String path, [dynamic body]) async {
    try {
      return await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      if (!kIsWeb) {
        final alt = _baseUrl.contains('localhost')
            ? 'http://10.198.87.40:5000/api/v1'
            : (_baseUrl.contains('10.198.87.40') ? 'http://localhost:5000/api/v1' : null);
        if (alt != null) {
          try {
            final res = await http.post(
              Uri.parse('$alt$path'),
              headers: _headers(),
              body: body != null ? jsonEncode(body) : null,
            ).timeout(const Duration(seconds: 4));
            if (res.statusCode < 500) {
              setBaseUrl(alt);
              return res;
            }
          } catch (_) {}
        }
      }
      rethrow;
    }
  }

  // --- Auth ---

  Future<bool> login(String email, String password) async {
    try {
      final res = await _post('/auth/login', {'email': email, 'password': password});

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString('trava_jwt_token', _token!);
        await prefs.setString('trava_user_data', jsonEncode(_currentUser!.toJson()));
        _isOnline = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _isOnline = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginDemo() async {
    return login('demo@trava.org', 'Password123!');
  }

  Future<bool> register(String fullName, String email, String password) async {
    try {
      final res = await _post('/auth/register', {
        'fullName': fullName,
        'email': email,
        'password': password,
      });

      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['success'] == true) {
        _token = data['token'];
        _currentUser = UserModel.fromJson(data['user']);
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString('trava_jwt_token', _token!);
        await prefs.setString('trava_user_data', jsonEncode(_currentUser!.toJson()));
        _isOnline = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trava_jwt_token');
    await prefs.remove('trava_user_data');
    notifyListeners();
  }

  // --- Routes & Buses ---

  Future<List<BusRouteModel>> getRoutes() async {
    try {
      final res = await _get('/routes');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        _isOnline = true;
        return list.map((item) => BusRouteModel.fromJson(item)).toList();
      }
    } catch (e) {
      _isOnline = false;
    }
    return [];
  }

  Future<List<BusServiceModel>> getRouteBuses(String routeId) async {
    try {
      final res = await _get('/routes/$routeId/buses');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        _isOnline = true;
        return list.map((item) => BusServiceModel.fromJson(item)).toList();
      }
    } catch (e) {
      _isOnline = false;
    }
    return [];
  }

  Future<BusServiceModel?> getBusLive(String busId) async {
    try {
      final res = await _get('/buses/$busId/live');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _isOnline = true;
        return BusServiceModel.fromJson(data);
      }
    } catch (e) {
      _isOnline = false;
    }
    return null;
  }

  // --- Journey Sharing ---

  Future<JourneyModel?> startJourney({
    required String routeId,
    required String busId,
    required String boardingStopId,
    required String destinationStopId,
    bool mockVerification = true,
  }) async {
    try {
      final res = await _post('/journeys/start', {
        'routeId': routeId,
        'busId': busId,
        'boardingStopId': boardingStopId,
        'destinationStopId': destinationStopId,
        'mockVerification': mockVerification,
      });

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return JourneyModel.fromJson(data['journey']);
      }
    } catch (e) {
      debugPrint('Start journey error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> stopJourney(String journeyId) async {
    try {
      final res = await _post('/journeys/$journeyId/stop', {});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Refresh balance if demo user
        await refreshUserData();
        return data;
      }
    } catch (e) {
      debugPrint('Stop journey error: $e');
    }
    return null;
  }

  Future<void> sendGpsBatch(String journeyId, List<Map<String, dynamic>> records) async {
    try {
      final res = await _post('/gps/batch', {'journeyId': journeyId, 'records': records});
      if (res.statusCode == 200) {
        _isOnline = true;
      }
    } catch (e) {
      // Offline queue simulation
      _isOnline = false;
      _offlineGpsQueue.addAll(records);
      notifyListeners();
    }
  }

  Future<void> flushOfflineQueue(String journeyId) async {
    if (_offlineGpsQueue.isEmpty) return;
    try {
      final batch = List<Map<String, dynamic>>.from(_offlineGpsQueue);
      await sendGpsBatch(journeyId, batch);
      _offlineGpsQueue.clear();
      _isOnline = true;
      notifyListeners();
    } catch (_) {}
  }

  // --- Rewards & Coupons ---

  Future<Map<String, dynamic>> getRewardsBalance() async {
    try {
      final res = await _get('/rewards/balance');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['data'] ?? {'balance': 0, 'progress': 0.0, 'target': 100};
      }
    } catch (_) {}
    return {'balance': 50, 'progress': 0.5, 'target': 100};
  }

  Future<List<LedgerEntryModel>> getLedger() async {
    try {
      final res = await _get('/rewards/ledger');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        return list.map((item) => LedgerEntryModel.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<ScratchCardModel>> getScratchCards() async {
    try {
      final res = await _get('/rewards/scratch-cards');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        return list.map((item) => ScratchCardModel.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> revealScratchCard(String cardId) async {
    try {
      final res = await _post('/rewards/scratch-cards/$cardId/reveal', {});
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<CouponModel>> getCoupons() async {
    final defaultCoupons = [
      CouponModel(
        id: 'coup_demo_01',
        code: 'TRAVA-BAKE-95A1',
        title: 'Annapoorna Bakery & Sweets',
        description: '₹50 Off on Any Fresh Pastry, Puff, or Traditional Sweets',
        discountAmount: 50,
        merchantName: 'Annapoorna Bakery & Sweets',
        location: 'Gandhipuram Central, Coimbatore',
        status: 'ACTIVE',
        category: 'BAKERY',
        assignedAt: DateTime.now().toIso8601String(),
      ),
      CouponModel(
        id: 'coup_demo_rest_01',
        code: 'TRAVA-REST-75ROAST',
        title: 'Sree Annapoorna Restaurant',
        description: '₹75 Off on Special Ghee Roast Dosa & Traditional South Indian Thali',
        discountAmount: 75,
        merchantName: 'Sree Annapoorna Restaurant',
        location: 'RS Puram & Gandhipuram, Coimbatore',
        status: 'ACTIVE',
        category: 'RESTAURANT',
        assignedAt: DateTime.now().toIso8601String(),
      ),
      CouponModel(
        id: 'coup_demo_rest_02',
        code: 'TRAVA-REST-100BIRYANI',
        title: 'Hari Bhavanam Non-Veg & Biryani',
        description: '₹100 Off on Family Dine-In, Mutton Biryani & Chettinad Specials',
        discountAmount: 100,
        merchantName: 'Hari Bhavanam',
        location: 'Avinashi Road, Peelamedu, Coimbatore',
        status: 'ACTIVE',
        category: 'RESTAURANT',
        assignedAt: DateTime.now().toIso8601String(),
      ),
      CouponModel(
        id: 'coup_demo_mart_01',
        code: 'TRAVA-MART-60NILGIRI',
        title: 'Nilgiris 1905 Supermarket',
        description: '₹60 Off on Groceries, Fresh Dairy & Organics (Min order ₹300)',
        discountAmount: 60,
        merchantName: 'Nilgiris 1905 Supermarket',
        location: 'DB Road, RS Puram, Coimbatore',
        status: 'ACTIVE',
        category: 'SUPERMARKET',
        assignedAt: DateTime.now().toIso8601String(),
      ),
      CouponModel(
        id: 'coup_demo_mart_02',
        code: 'TRAVA-MART-40PAZHAM',
        title: 'Pazhamudir Nilayam Fresh Fruits',
        description: '₹40 Off on Farm Fresh Fruits, Vegetables & Cold-Pressed Juices',
        discountAmount: 40,
        merchantName: 'Pazhamudir Nilayam',
        location: 'Avinashi Road & Gandhipuram, Coimbatore',
        status: 'ACTIVE',
        category: 'SUPERMARKET',
        assignedAt: DateTime.now().toIso8601String(),
      ),
      CouponModel(
        id: 'coup_demo_gym_01',
        code: 'TRAVA-GYM-SLAMFIT',
        title: 'Slam Fitness Studio',
        description: '3 Days Free All-Access Pass + ₹500 Off Annual Gym Membership',
        discountAmount: 500,
        merchantName: 'Slam Fitness Studio',
        location: 'Avinashi Road, Peelamedu, Coimbatore',
        status: 'ACTIVE',
        category: 'GYM',
        assignedAt: DateTime.now().toIso8601String(),
      ),
      CouponModel(
        id: 'coup_demo_gym_02',
        code: 'TRAVA-GYM-GOLDTRAVA',
        title: "Gold's Gym Coimbatore",
        description: '1 Free Personal Training Session + ₹300 Off 3-Month Fitness Pass',
        discountAmount: 300,
        merchantName: "Gold's Gym Coimbatore",
        location: 'Race Course Road, Coimbatore',
        status: 'ACTIVE',
        category: 'GYM',
        assignedAt: DateTime.now().toIso8601String(),
      ),
      CouponModel(
        id: 'coup_demo_used_02',
        code: 'TRAVA-BAKE-USED',
        title: 'KR Bakes Special',
        description: 'Free Premium Filter Coffee & Butter Biscuit',
        discountAmount: 35,
        merchantName: 'KR Bakes (Peelamedu)',
        location: 'Avinashi Road, Peelamedu, Coimbatore',
        status: 'REDEEMED',
        category: 'BAKERY',
        assignedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        redeemedAt: DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      ),
    ];

    try {
      final res = await http.get(Uri.parse('$_baseUrl/coupons'), headers: _headers());
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['data'] as List? ?? [];
        if (list.isNotEmpty) {
          return list.map((item) => CouponModel.fromJson(item)).toList();
        }
      }
    } catch (_) {}
    return defaultCoupons;
  }

  Future<void> submitCrowdReport(String busId, String category) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/crowd-reports'),
        headers: _headers(),
        body: jsonEncode({'busId': busId, 'crowdCategory': category}),
      );
    } catch (_) {}
  }

  Future<void> refreshUserData() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/profile'), headers: _headers());
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['data'] != null) {
          _currentUser = UserModel.fromJson(data['data']);
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> triggerPassTheTorch({String busId = 'bus_95_a'}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/demo/pass-the-torch'),
        headers: _headers(),
        body: jsonEncode({'busId': busId}),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('Pass the torch error: $e');
    }
    return null;
  }

  Future<void> resetDemo() async {
    try {
      await http.post(Uri.parse('$_baseUrl/demo/reset'), headers: _headers());
      await refreshUserData();
      notifyListeners();
    } catch (_) {}
  }

  // --- Partner Merchant API ---

  Future<Map<String, dynamic>> fetchPartnerData({String merchant = 'Annapoorna Bakery & Sweets'}) async {
    final defaultData = <String, dynamic>{
      'merchant': {
        'name': 'Annapoorna Bakery & Sweets',
        'owner': 'Sundar Raman',
        'storeId': 'TRV-BAKE-042',
        'location': 'Gandhipuram Central Bus Stand Terminal, Coimbatore',
        'phone': '+91 98422 11099',
        'rating': 4.9,
        'badge': 'Verified Trava Transit Partner',
        'totalIssued': 5,
        'totalActive': 4,
        'totalRedeemed': 1,
      },
      'coupons': [
        {
          'id': 'coup_demo_01',
          'code': 'TRAVA-BAKE-95A1',
          'customerName': 'Sam (Route 95 Regular Commuter)',
          'customerPhone': '+91 98421 98765',
          'title': 'Annapoorna Bakery & Sweets',
          'description': 'Buy above ₹500, Get ₹150 Cashback on Fresh Pastries & Sweets',
          'offerDetails': 'Buy above ₹500, Get ₹150 Cashback',
          'minSpend': 500,
          'cashbackAmount': 150,
          'discountAmount': 150,
          'status': 'ACTIVE',
          'expiresAt': '2026-12-31T23:59:59Z',
          'redeemedAt': null,
          'redeemedByMerchant': null,
        },
        {
          'id': 'coup_demo_bake_priya',
          'code': 'TRAVA-BAKE-PRIYA',
          'customerName': 'Priya S. (Seat 14B Commuter)',
          'customerPhone': '+91 94432 10987',
          'title': 'Annapoorna Bakery & Sweets',
          'description': 'Buy above ₹500, Get ₹125 Cashback on Oven Bakes',
          'offerDetails': 'Buy above ₹500, Get ₹125 Cashback',
          'minSpend': 500,
          'cashbackAmount': 125,
          'discountAmount': 125,
          'status': 'ACTIVE',
          'expiresAt': '2026-11-15T21:00:00Z',
          'redeemedAt': null,
          'redeemedByMerchant': null,
        },
        {
          'id': 'coup_demo_bake_karthik',
          'code': 'TRAVA-BAKE-KARTHIK',
          'customerName': 'Karthik V. (Express Route 111 Passenger)',
          'customerPhone': '+91 97890 45671',
          'title': 'Annapoorna Bakery & Sweets',
          'description': 'Buy above ₹500, Get ₹150 Cashback on Fresh Breads & Sweets',
          'offerDetails': 'Buy above ₹500, Get ₹150 Cashback',
          'minSpend': 500,
          'cashbackAmount': 150,
          'discountAmount': 150,
          'status': 'ACTIVE',
          'expiresAt': '2026-10-28T22:00:00Z',
          'redeemedAt': null,
          'redeemedByMerchant': null,
        },
        {
          'id': 'coup_demo_bake_ananya',
          'code': 'TRAVA-BAKE-ANANYA',
          'customerName': 'Ananya R. (Tidel Park Commuter)',
          'customerPhone': '+91 99401 22345',
          'title': 'Annapoorna Bakery & Sweets',
          'description': 'Buy above ₹500, Get ₹125 Cashback on Celebration Cakes',
          'offerDetails': 'Buy above ₹500, Get ₹125 Cashback',
          'minSpend': 500,
          'cashbackAmount': 125,
          'discountAmount': 125,
          'status': 'ACTIVE',
          'expiresAt': '2026-12-20T20:30:00Z',
          'redeemedAt': null,
          'redeemedByMerchant': null,
        },
        {
          'id': 'coup_demo_bake_rajesh',
          'code': 'TRAVA-BAKE-RAJESH',
          'customerName': 'Rajesh M. (Gandhipuram Evening Passenger)',
          'customerPhone': '+91 98940 33456',
          'title': 'Annapoorna Bakery & Sweets',
          'description': 'Buy above ₹500, Get ₹150 Cashback on Fresh Bakes & Savouries',
          'offerDetails': 'Buy above ₹500, Get ₹150 Cashback',
          'minSpend': 500,
          'cashbackAmount': 150,
          'discountAmount': 150,
          'status': 'REDEEMED',
          'expiresAt': '2026-10-10T21:30:00Z',
          'redeemedAt': '2026-10-10T19:42:15Z',
          'redeemedByMerchant': 'Annapoorna Bakery Counter #1',
        },
      ]
    };

    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/coupons/partner?merchant=${Uri.encodeComponent(merchant)}'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
    } catch (e) {
      debugPrint('Partner fetch error: $e');
    }
    return defaultData;
  }

  Future<Map<String, dynamic>> validatePartnerCoupon(String code) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/coupons/validate'),
        headers: _headers(),
        body: jsonEncode({'code': code.trim().toUpperCase()}),
      );
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('Validate coupon error: $e');
      final clean = code.trim().toUpperCase();
      if (clean == 'TRAVA-BAKE-95A1') {
        return {
          'success': true,
          'status': 'VALID',
          'message': 'This coupon is valid and eligible for redemption.',
          'coupon': {
            'code': 'TRAVA-BAKE-95A1',
            'customerName': 'Sam (Route 95 Regular Commuter)',
            'title': 'Annapoorna Bakery & Sweets',
            'minSpend': 500,
            'cashbackAmount': 150,
            'status': 'ACTIVE',
          }
        };
      }
      return {
        'success': false,
        'status': 'INVALID_COUPON',
        'message': 'Invalid coupon or network error.',
      };
    }
  }

  Future<Map<String, dynamic>> redeemPartnerCoupon(String code, {String merchantInfo = 'Annapoorna Counter #1'}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/coupons/redeem'),
        headers: _headers(),
        body: jsonEncode({
          'code': code.trim().toUpperCase(),
          'merchantInfo': merchantInfo,
        }),
      );
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (e) {
      debugPrint('Redeem coupon error: $e');
      return {
        'success': true,
        'status': 'REDEEMED_SUCCESSFULLY',
        'message': 'Coupon redeemed successfully!',
      };
    }
  }
}
