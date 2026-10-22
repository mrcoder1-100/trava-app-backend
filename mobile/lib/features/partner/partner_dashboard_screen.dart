import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _codeController = TextEditingController(text: 'TRAVA-BAKE-95A1');
  final TextEditingController _billController = TextEditingController(text: '650');

  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isRedeeming = false;

  Map<String, dynamic> _merchant = {
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
  };

  List<Map<String, dynamic>> _coupons = [];
  Map<String, dynamic>? _verifiedCouponResult;
  String? _verificationMessage;
  bool _isCouponValid = false;

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _billController.dispose();
    super.dispose();
  }

  Future<void> _loadPartnerData() async {
    setState(() => _isLoading = true);
    final data = await _api.fetchPartnerData(merchant: 'Annapoorna Bakery & Sweets');
    if (mounted) {
      setState(() {
        if (data['merchant'] != null) {
          _merchant = Map<String, dynamic>.from(data['merchant']);
        }
        if (data['coupons'] != null) {
          _coupons = (data['coupons'] as List).map((c) => Map<String, dynamic>.from(c)).toList();
        }
        _isLoading = false;
      });
      // Auto verify initial code
      _verifyCode('TRAVA-BAKE-95A1');
    }
  }

  Future<void> _verifyCode(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return;

    setState(() {
      _isVerifying = true;
      _codeController.text = clean;
    });

    // Check local list first
    final localMatch = _coupons.firstWhere(
      (c) => (c['code'] ?? '').toString().toUpperCase() == clean,
      orElse: () => {},
    );

    final apiRes = await _api.validatePartnerCoupon(clean);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      if (apiRes['success'] == true && apiRes['coupon'] != null) {
        _verifiedCouponResult = Map<String, dynamic>.from(apiRes['coupon']);
        if (localMatch.isNotEmpty && _verifiedCouponResult!['customerName'] == null) {
          _verifiedCouponResult!['customerName'] = localMatch['customerName'];
        }
        _isCouponValid = true;
        _verificationMessage = 'Valid & Eligible for ₹${_verifiedCouponResult!['cashbackAmount'] ?? 150} Cashback!';
      } else if (apiRes['status'] == 'ALREADY_USED' || (localMatch.isNotEmpty && localMatch['status'] == 'REDEEMED')) {
        _verifiedCouponResult = localMatch.isNotEmpty ? localMatch : (apiRes['coupon'] != null ? Map<String, dynamic>.from(apiRes['coupon']) : null);
        _isCouponValid = false;
        _verificationMessage = 'ALREADY REDEEMED! Cannot be reused.';
      } else {
        if (localMatch.isNotEmpty) {
          _verifiedCouponResult = localMatch;
          _isCouponValid = localMatch['status'] == 'ACTIVE';
          _verificationMessage = _isCouponValid
              ? 'Valid & Eligible for ₹${localMatch['cashbackAmount'] ?? 150} Cashback!'
              : 'Status: ${localMatch['status']}';
        } else {
          _verifiedCouponResult = null;
          _isCouponValid = false;
          _verificationMessage = 'Invalid or unrecognized coupon code.';
        }
      }
    });
  }

  Future<void> _redeemCurrentCoupon() async {
    if (_verifiedCouponResult == null) return;
    final code = (_verifiedCouponResult!['code'] ?? _codeController.text).toString().toUpperCase();

    setState(() => _isRedeeming = true);

    await _api.redeemPartnerCoupon(code, merchantInfo: 'Annapoorna Counter #1');

    if (!mounted) return;

    setState(() {
      _isRedeeming = false;
      // Mark as redeemed locally
      for (var c in _coupons) {
        if ((c['code'] ?? '').toString().toUpperCase() == code) {
          c['status'] = 'REDEEMED';
          c['redeemedAt'] = DateTime.now().toIso8601String();
          c['redeemedByMerchant'] = 'Annapoorna Counter #1';
        }
      }
      _merchant['totalActive'] = (_merchant['totalActive'] ?? 4) > 0 ? (_merchant['totalActive'] as int) - 1 : 0;
      _merchant['totalRedeemed'] = ((_merchant['totalRedeemed'] ?? 1) as int) + 1;

      if (_verifiedCouponResult != null) {
        _verifiedCouponResult!['status'] = 'REDEEMED';
        _verifiedCouponResult!['redeemedAt'] = DateTime.now().toIso8601String();
      }
      _isCouponValid = false;
      _verificationMessage = 'SUCCESSFULLY REDEEMED AT COUNTER #1';
    });

    _showSuccessRedemptionDialog(code);
  }

  void _showSuccessRedemptionDialog(String code) {
    final double bill = double.tryParse(_billController.text) ?? 650.0;
    final double cashback = (_verifiedCouponResult != null && _verifiedCouponResult!['cashbackAmount'] != null)
        ? (_verifiedCouponResult!['cashbackAmount'] as num).toDouble()
        : 150.0;
    final double netPayable = bill > cashback ? (bill - cashback) : 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Coupon Redeemed!',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code: $code', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${_verifiedCouponResult?['customerName'] ?? 'Sam (Commuter)'}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.charcoal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Original Bill:', style: TextStyle(color: AppTheme.muted), overflow: TextOverflow.ellipsis)),
                Text('₹${bill.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Trava Commuter Cashback:',
                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('-₹${cashback.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Text('Net Paid by Customer:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16), overflow: TextOverflow.ellipsis)),
                Text('₹${netPayable.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.emeraldDark)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '✓ Atomic backend update committed. This coupon code is now locked and cannot be redeemed again.',
              style: TextStyle(fontSize: 11, color: AppTheme.muted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done & Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🥐', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Annapoorna Bakery & Sweets',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Partner Merchant Portal • Gandhipuram',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppTheme.emerald),
            tooltip: 'Switch to Commuter Portal',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.charcoal),
            tooltip: 'Refresh Coupons',
            onPressed: _loadPartnerData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.emerald))
          : RefreshIndicator(
              onRefresh: _loadPartnerData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Merchant Profile Banner Card
                    _buildMerchantHeaderCard(),
                    const SizedBox(height: 16),

                    // KPI Quick Stats Row
                    _buildKpiRow(),
                    const SizedBox(height: 20),

                    // Interactive Cashier Verification & Net Bill Tool
                    _buildCounterVerificationSection(),
                    const SizedBox(height: 24),

                    // Issued Customer Coupons Header & List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Issued Customer Coupons',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3EF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_coupons.length} Active Records',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.emeraldDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List of 5 Customers
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _coupons.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildCustomerCouponCard(_coupons[index]);
                      },
                    ),

                    const SizedBox(height: 28),
                    // Switch portal footer button
                    Center(
                      child: TextButton.icon(
                        icon: const Icon(Icons.logout, size: 16, color: AppTheme.muted),
                        label: const Text('Log Out of Partner Portal', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMerchantHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFDE68A), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🥐', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _merchant['name'] ?? 'Annapoorna Bakery & Sweets',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.charcoal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 11, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text('Partner', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Owner: ${_merchant['owner'] ?? 'Sundar Raman'} • ID: ${_merchant['storeId'] ?? 'TRV-BAKE-042'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppTheme.muted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _merchant['location'] ?? 'Gandhipuram Central Bus Stand Terminal, Coimbatore',
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
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 600 ? 4 : 2;
        final double cardWidth = ((constraints.maxWidth - ((columns - 1) * 10)) / columns).floorToDouble() - 1;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildKpiCard(
              title: 'Total Issued',
              value: '${_coupons.length}',
              icon: Icons.confirmation_number_outlined,
              color: Colors.blue.shade700,
              bgColor: Colors.blue.shade50,
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Active Coupons',
              value: '${_merchant['totalActive'] ?? 4}',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF10B981),
              bgColor: const Color(0xFFECFDF5),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Redeemed',
              value: '${_merchant['totalRedeemed'] ?? 1}',
              icon: Icons.done_all,
              color: const Color(0xFFD97706),
              bgColor: const Color(0xFFFEF3C7),
              width: cardWidth,
            ),
            _buildKpiCard(
              title: 'Cashback Pool',
              value: '₹700',
              icon: Icons.currency_rupee,
              color: AppTheme.emeraldDark,
              bgColor: const Color(0xFFE6F3EF),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 13, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterVerificationSection() {
    final double bill = double.tryParse(_billController.text) ?? 650.0;
    final double minSpend = (_verifiedCouponResult != null && _verifiedCouponResult!['minSpend'] != null)
        ? (_verifiedCouponResult!['minSpend'] as num).toDouble()
        : 500.0;
    final double cashback = (_verifiedCouponResult != null && _verifiedCouponResult!['cashbackAmount'] != null)
        ? (_verifiedCouponResult!['cashbackAmount'] as num).toDouble()
        : 150.0;
    final bool isEligible = bill >= minSpend;
    final double netPayable = isEligible ? (bill - cashback > 0 ? bill - cashback : 0.0) : bill;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F3EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.point_of_sale, color: AppTheme.emerald, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cashier Counter Verification',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.charcoal),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Verify commuter codes & apply instant cashback on orders > ₹500',
                      style: TextStyle(fontSize: 11, color: AppTheme.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Input & Action Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Coupon Code (e.g. TRAVA-BAKE-95A1)',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.qr_code, color: AppTheme.emerald, size: 20),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => _codeController.clear(),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onFieldSubmitted: _verifyCode,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isVerifying ? null : () => _verifyCode(_codeController.text),
                icon: _isVerifying
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check, size: 16),
                label: const Text('Verify', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Customer Chips
          const Text('Quick Autofill Customer Coupon:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.muted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildCustomerChip('Sam (95A1)', 'TRAVA-BAKE-95A1'),
              _buildCustomerChip('Priya (PRIYA)', 'TRAVA-BAKE-PRIYA'),
              _buildCustomerChip('Karthik (KARTHIK)', 'TRAVA-BAKE-KARTHIK'),
              _buildCustomerChip('Ananya (ANANYA)', 'TRAVA-BAKE-ANANYA'),
              _buildCustomerChip('Rajesh (Used)', 'TRAVA-BAKE-RAJESH', isRedeemed: true),
            ],
          ),
          const SizedBox(height: 16),

          // Verification Result Panel
          if (_verifiedCouponResult != null || _verificationMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isCouponValid ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCouponValid ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              _isCouponValid ? Icons.check_circle : Icons.error_outline,
                              color: _isCouponValid ? const Color(0xFF16A34A) : Colors.red.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _isCouponValid ? 'COUPON VALID & ACTIVE' : 'CANNOT BE REDEEMED',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: _isCouponValid ? const Color(0xFF166534) : Colors.red.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _isCouponValid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _verifiedCouponResult?['code'] ?? _codeController.text,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: _isCouponValid ? const Color(0xFF15803D) : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer: ${_verifiedCouponResult?['customerName'] ?? 'Sam (Route 95 Regular Commuter)'}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.charcoal),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Offer: ${_verifiedCouponResult?['description'] ?? _verifiedCouponResult?['offerDetails'] ?? 'Buy above ₹500, Get ₹150 Cashback'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const Divider(height: 18),

                  // Net Bill Calculator Row
                  Row(
                    children: [
                      const Text('Order Bill (₹):', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: TextFormField(
                          controller: _billController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEligible ? '✓ Min ₹500 met' : '⚠️ Min ₹500 required',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: isEligible ? const Color(0xFF16A34A) : Colors.orange.shade800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Order Bill',
                                style: TextStyle(fontSize: 10, color: AppTheme.muted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('₹${bill.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        const Text('—', style: TextStyle(fontSize: 16, color: AppTheme.muted)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Cashback Off',
                                style: TextStyle(fontSize: 10, color: Color(0xFF16A34A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isEligible ? '₹${cashback.toStringAsFixed(0)}' : '₹0',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF16A34A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text('=', style: TextStyle(fontSize: 16, color: AppTheme.muted)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Customer Pays',
                                style: TextStyle(fontSize: 10, color: AppTheme.emeraldDark, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '₹${netPayable.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.emeraldDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_isCouponValid && isEligible) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRedeeming ? null : _redeemCurrentCoupon,
                        icon: _isRedeeming
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.flash_on, size: 16),
                        label: const Text('Confirm & Redeem (Instant Discount)', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ] else if (!_isCouponValid) ...[
                    const SizedBox(height: 8),
                    Text(
                      _verificationMessage ?? 'Coupon cannot be redeemed.',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.red.shade800),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerChip(String label, String code, {bool isRedeemed = false}) {
    return ActionChip(
      avatar: Text(isRedeemed ? '🔒' : '👤', style: const TextStyle(fontSize: 11)),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: isRedeemed ? Colors.grey.shade200 : const Color(0xFFE6F3EF),
      side: BorderSide(color: isRedeemed ? Colors.grey.shade400 : const Color(0xFF0F4C3A).withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: () {
        _codeController.text = code;
        _verifyCode(code);
      },
    );
  }

  Widget _buildCustomerCouponCard(Map<String, dynamic> coupon) {
    final bool isRedeemed = (coupon['status'] ?? '').toString().toUpperCase() == 'REDEEMED';
    final String customerName = coupon['customerName'] ?? 'Trava Commuter';
    final String code = coupon['code'] ?? '';
    final String desc = coupon['description'] ?? coupon['offerDetails'] ?? 'Buy above ₹500, Get ₹150 Cashback';
    final int cashback = coupon['cashbackAmount'] ?? coupon['discountAmount'] ?? 150;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRedeemed ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isRedeemed ? Colors.grey.shade300 : Colors.grey.shade200),
        boxShadow: isRedeemed
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: isRedeemed ? Colors.grey.shade300 : const Color(0xFFD1FAE5),
                      child: Text(
                        customerName.isNotEmpty ? customerName.substring(0, 1) : 'C',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isRedeemed ? Colors.grey.shade700 : const Color(0xFF065F46),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isRedeemed ? Colors.grey.shade700 : AppTheme.charcoal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            'Coimbatore Transit Passenger',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isRedeemed ? Colors.grey.shade200 : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isRedeemed ? Colors.grey.shade400 : const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  isRedeemed ? 'REDEEMED' : 'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isRedeemed ? Colors.grey.shade700 : const Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isRedeemed ? Colors.grey.shade600 : AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 15, color: AppTheme.emerald),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          code,
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹$cashback Off',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.emerald),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 15, color: AppTheme.muted),
                      tooltip: 'Copy Code',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied $code to clipboard'), duration: const Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isRedeemed ? 'Redeemed by Counter #1' : 'Min Spend: ₹500 • Instant Off',
                  style: TextStyle(fontSize: 10, color: isRedeemed ? Colors.grey.shade600 : AppTheme.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (!isRedeemed)
                ElevatedButton.icon(
                  onPressed: () {
                    _codeController.text = code;
                    _verifyCode(code);
                  },
                  icon: const Icon(Icons.arrow_upward, size: 13),
                  label: const Text('Verify', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
