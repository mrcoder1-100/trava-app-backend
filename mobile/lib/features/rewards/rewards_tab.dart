import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/coupon.dart';
import '../../models/reward.dart';
import '../../services/api_service.dart';
import '../../services/language_service.dart';
import '../common/language_selector_sheet.dart';

class RewardsTab extends StatefulWidget {
  const RewardsTab({super.key});

  @override
  State<RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<RewardsTab> {
  final ApiService _api = ApiService();
  final LanguageService _langService = LanguageService();

  int _pointsBalance = 50;
  int _targetPoints = 100;
  double _progress = 0.5;

  List<LedgerEntryModel> _ledger = [];
  List<CouponModel> _coupons = [];
  bool _isLoading = true;
  String _selectedCategory = 'ALL';

  // Scratch card reveal state
  bool _isCardRevealed = false;
  final List<Offset> _scratchPoints = [];

  @override
  void initState() {
    super.initState();
    _loadRewardsData();
  }

  Future<void> _loadRewardsData() async {
    setState(() => _isLoading = true);

    final balanceData = await _api.getRewardsBalance();
    final ledger = await _api.getLedger();
    final coupons = await _api.getCoupons();

    if (mounted) {
      setState(() {
        _pointsBalance = balanceData['balance'] ?? 50;
        _targetPoints = balanceData['target'] ?? 100;
        _progress = (_pointsBalance / _targetPoints).clamp(0.0, 1.0);
        _ledger = ledger;
        _coupons = coupons;
        _isLoading = false;
      });
    }
  }

  void _onScratchUpdate(DragUpdateDetails details) {
    if (_isCardRevealed) return;
    setState(() {
      _scratchPoints.add(details.localPosition);
      // Once user scratches enough points (e.g. > 35 points), automatically reveal the guaranteed reward!
      if (_scratchPoints.length > 35) {
        _isCardRevealed = true;
        _api.revealScratchCard('sc_demo_01');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canScratch = _pointsBalance >= _targetPoints;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: Text(
          _langService.tr('nav_rewards'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          const QuickLanguagePill(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRewardsData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.emerald))
          : RefreshIndicator(
              onRefresh: _loadRewardsData,
              color: AppTheme.emerald,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Balance & Target Progress Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F4C3A), Color(0xFF166A51)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.emerald.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
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
                                child: Text(
                                  _langService.tr('total_community_balance'),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _langService.tr('guaranteed_rewards_badge'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$_pointsBalance',
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _langService.tr('points_label'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.amberLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Target Progress Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_langService.tr('next_reward_card_prefix')}: $_pointsBalance / $_targetPoints ${_langService.tr('pts')}',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(color: AppTheme.amberLight, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 10,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.amber),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Heading: Interactive Scratch Card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _langService.tr('guaranteed_reward_card_title'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (canScratch)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _langService.tr('ready_to_scratch_badge'),
                              style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w800, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _langService.tr('guaranteed_card_desc'),
                      style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 14),

                    // Interactive Scratch Canvas Card
                    _buildScratchCardWidget(canScratch),
                    const SizedBox(height: 24),

                    // Partner Category Filters (Bakery, Restaurant, Supermarket, Gym)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _langService.tr('partner_categories_header'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildCategoryFilters(),
                    const SizedBox(height: 20),

                    // Partner Merchant Webpage Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storefront, color: AppTheme.emerald, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _langService.tr('partner_portal_header'),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _langService.tr('partner_portal_desc'),
                                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available Coupons Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _langService.tr('your_coupons_header'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_filteredCoupons.length} ${_langService.tr('deals_suffix')}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.emeraldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_filteredCoupons.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.muted),
                              const SizedBox(height: 8),
                              Text(
                                _langService.tr('no_coupons_found'),
                                style: const TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._filteredCoupons.map((c) => _buildCouponCard(c)),

                    const SizedBox(height: 24),

                    // Points Ledger Section
                    Text(
                      _langService.tr('points_ledger_title'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.charcoal),
                    ),
                    const SizedBox(height: 12),

                    ..._ledger.map((entry) => _buildLedgerTile(entry)),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScratchCardWidget(bool canScratch) {
    if (!canScratch) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 40, color: AppTheme.muted),
              const SizedBox(height: 10),
              Text(
                _langService.tr('scratch_card_locked'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.charcoal),
              ),
              const SizedBox(height: 4),
              Text(
                _langService.tr('unlock_instructions_prefix'),
                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ],
          ),
        ),
      );
    }

    final activeCoupon = _coupons.firstWhere(
      (c) => c.isActive,
      orElse: () => _coupons.isNotEmpty
          ? _coupons.first
          : CouponModel(
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
    );

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Underneath: Guaranteed Reward Card Content
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: activeCoupon.categoryBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: activeCoupon.categoryColor.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(activeCoupon.categoryEmoji, style: const TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_langService.tr('guaranteed_reward_prefix')} ${activeCoupon.categoryLabel.toUpperCase()} ${_langService.tr('reward_suffix')}',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activeCoupon.merchantName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.charcoal),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeCoupon.description,
                          style: const TextStyle(fontSize: 12, color: AppTheme.muted, height: 1.2),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_langService.tr('code_prefix')} ${activeCoupon.code}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppTheme.emeraldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Foil Cover (If not revealed, allow user to drag and scratch away)
            if (!_isCardRevealed)
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: _onScratchUpdate,
                  child: CustomPaint(
                    painter: _ScratchFoilPainter(scratchPoints: _scratchPoints),
                  ),
                ),
              ),

            // Scratch Instructions Overlay
            if (!_isCardRevealed && _scratchPoints.isEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _langService.tr('swipe_to_scratch'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<CouponModel> get _filteredCoupons {
    if (_selectedCategory == 'ALL') return _coupons;
    return _coupons.where((c) => c.category.toUpperCase() == _selectedCategory).toList();
  }

  Widget _buildCategoryFilters() {
    final categories = [
      {'key': 'ALL', 'label': _langService.tr('all_partners'), 'emoji': '🎁'},
      {'key': 'BAKERY', 'label': _langService.tr('cat_bakeries'), 'emoji': '🥐'},
      {'key': 'RESTAURANT', 'label': _langService.tr('cat_restaurants'), 'emoji': '🍽️'},
      {'key': 'SUPERMARKET', 'label': _langService.tr('cat_supermarkets'), 'emoji': '🛒'},
      {'key': 'GYM', 'label': _langService.tr('cat_gym'), 'emoji': '🏋️'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                '${cat['emoji']} ${cat['label']}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppTheme.charcoal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.emerald,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppTheme.emerald : AppTheme.border,
                ),
              ),
              onSelected: (_) {
                setState(() => _selectedCategory = cat['key']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    final bool isRedeemed = coupon.isRedeemed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRedeemed ? const Color(0xFFFDE68A) : AppTheme.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isRedeemed ? const Color(0xFFFFFBEB) : coupon.categoryBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              coupon.categoryIcon,
              color: isRedeemed ? const Color(0xFFD97706) : coupon.categoryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        coupon.merchantName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRedeemed ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isRedeemed ? _langService.tr('already_used_badge') : _langService.tr('active_badge'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isRedeemed ? const Color(0xFF92400E) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: coupon.categoryBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${coupon.categoryEmoji} ${coupon.categoryLabel}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: coupon.categoryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        coupon.location,
                        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  coupon.description,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.confirmation_num_outlined, size: 14, color: AppTheme.emerald),
                        const SizedBox(width: 6),
                        Text(
                          '${_langService.tr('code_prefix')} ${coupon.code}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppTheme.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTile(LedgerEntryModel entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_circle_up, color: AppTheme.emerald, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_langService.tr('balance_pts_prefix')} ${entry.balanceAfter} ${_langService.tr('pts')}',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${entry.points}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppTheme.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScratchFoilPainter extends CustomPainter {
  final List<Offset> scratchPoints;
  _ScratchFoilPainter({required this.scratchPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // Silver / Gold foil background
    final foilPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8), Color(0xFFCBD5E1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), foilPaint);

    // Decorative sparkles on foil
    final sparklePaint = Paint()..color = Colors.white.withOpacity(0.4);
    for (int i = 0; i < 20; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 53) % size.height;
      canvas.drawCircle(Offset(x, y), 2, sparklePaint);
    }

    // Cut out scratched points using clear blend mode
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 44
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < scratchPoints.length - 1; i++) {
      canvas.drawLine(scratchPoints[i], scratchPoints[i + 1], clearPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScratchFoilPainter oldDelegate) {
    return oldDelegate.scratchPoints.length != scratchPoints.length;
  }
}
