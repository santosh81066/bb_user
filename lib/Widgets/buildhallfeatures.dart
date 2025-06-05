import 'package:flutter/material.dart';
import 'package:bb_user/models/get_properties_model.dart';
import '../Screens/halllocation.dart';

class EnhancedHallFeatures extends StatefulWidget {
  final Hall hall;

  const EnhancedHallFeatures(this.hall, {super.key});

  @override
  State<EnhancedHallFeatures> createState() => _EnhancedHallFeaturesState();
}

class _EnhancedHallFeaturesState extends State<EnhancedHallFeatures> {
  int _selectedTab = 0;
  final PageController _pageController = PageController();

  // Tab configuration
  static const _tabs = [
    {'title': 'Overview', 'icon': Icons.info_outline},
    {'title': 'Amenities', 'icon': Icons.star_outline},
    {'title': 'Policies', 'icon': Icons.policy_outlined},
    {'title': 'Safety', 'icon': Icons.security_outlined},
    {'title': 'Costs', 'icon': Icons.attach_money_outlined},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Media query helper methods
  bool _isSmallScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width < 600 || size.height < 800;
  }

  bool _isMediumScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width >= 600 && size.width < 900;
  }


  bool _isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  double _getResponsivePadding(BuildContext context) {
    if (_isSmallScreen(context)) return 12.0;
    if (_isMediumScreen(context)) return 16.0;
    return 20.0;
  }

  double _getResponsiveFontSize(BuildContext context, double baseSize) {
    if (_isSmallScreen(context)) return baseSize * 0.9;
    if (_isMediumScreen(context)) return baseSize;
    return baseSize * 1.1;
  }

  int _getGridCrossAxisCount(BuildContext context) {
    if (_isSmallScreen(context)) return 2;
    if (_isMediumScreen(context)) return 3;
    return 4;
  }

  double _getContainerHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (_isSmallScreen(context)) return screenHeight * 0.5;
    if (_isMediumScreen(context)) return screenHeight * 0.55;
    return 450;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        SizedBox(height: _getResponsivePadding(context)),
        _buildTabNavigation(context),
        SizedBox(height: _getResponsivePadding(context)),
        _buildLocationWidget(context),
        SizedBox(height: _getResponsivePadding(context)),
        _buildContentPages(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final padding = _getResponsivePadding(context);
    final titleSize = _getResponsiveFontSize(context, 22);
    final subtitleSize = _getResponsiveFontSize(context, 14);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: _isSmallScreen(context) ? 16 : 20,
        horizontal: _isSmallScreen(context) ? 16 : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_isSmallScreen(context) ? 16 : 20),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_isSmallScreen(context) ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(_isSmallScreen(context) ? 8 : 12),
            ),
            child: Icon(Icons.home_work_outlined, color: Colors.white, size: _isSmallScreen(context) ? 24 : 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hall Features', style: TextStyle(color: Colors.white, fontSize: titleSize, fontWeight: FontWeight.bold)),
              Text('Discover amazing amenities', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: subtitleSize)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationWidget(BuildContext context) {
    return HallLocationWidget(
      propertyName: widget.hall.name ?? 'Hall',
      address: (ModalRoute.of(context)?.settings.arguments as Map)['property'].address,
    );
  }

  Widget _buildTabNavigation(BuildContext context) {
    final fontSize = _getResponsiveFontSize(context, 10);

    return Container(
      padding: EdgeInsets.all(_isSmallScreen(context) ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: _isSmallScreen(context) && _isLandscape(context)
          ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.asMap().entries.map((e) =>
              _buildTabButton(context, e.value['title']! as String, e.key, e.value['icon']! as IconData, fontSize)
          ).toList(),
        ),
      )
          : Row(
        children: _tabs.asMap().entries.map((e) =>
            _buildTabButton(context, e.value['title']! as String, e.key, e.value['icon']! as IconData, fontSize)
        ).toList(),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String title, int index, IconData icon, double fontSize) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: _isSmallScreen(context) ? 8 : 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.deepPurple, size: _isSmallScreen(context) ? 18 : 20),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: fontSize)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentPages(BuildContext context) {
    final padding = _getResponsivePadding(context);
    final containerHeight = _getContainerHeight(context);

    return Container(
      height: containerHeight,
      margin: EdgeInsets.symmetric(horizontal: padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedTab = index),
        children: [
          _buildOverviewPage(context),
          _buildAmenitiesPage(context),
          _buildPoliciesPage(context),
          _buildSafetyPage(context),
          _buildCostsPage(context),
        ],
      ),
    );
  }

  Widget _buildOverviewPage(BuildContext context) {
    final hall = widget.hall;
    final overviewItems = [
      {'title': 'Capacity', 'value': '${hall.capacity ?? 0}', 'icon': Icons.people_outline, 'color': Colors.blue},
      {'title': 'Parking', 'value': '${hall.parkingCapacity ?? 0}', 'icon': Icons.local_parking_outlined, 'color': Colors.green},
      {'title': 'Floating', 'value': '${hall.floatingCapacity ?? 0}', 'icon': Icons.person_outline, 'color': Colors.orange},
      {'title': 'Staff Count', 'value': '${(hall.cleaningStaff ?? 0) + (hall.securityCount ?? 0)}', 'icon': Icons.supervised_user_circle_outlined, 'color': Colors.purple},
    ];

    final padding = _getResponsivePadding(context);
    final crossAxisCount = _getGridCrossAxisCount(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Hall Overview', Icons.info_outline),
          SizedBox(height: padding),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            childAspectRatio: _isSmallScreen(context) ? 1.2 : 1.3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: overviewItems.map((item) => _buildOverviewCard(
              context,
              item['title']! as String,
              item['value']! as String,
              item['icon']! as IconData,
              item['color']! as Color,
            )).toList(),
          ),
          SizedBox(height: padding),
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.shade50, Colors.red.shade100]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.restaurant_outlined, color: Colors.red.shade700, size: _isSmallScreen(context) ? 20 : 24),
                SizedBox(width: _isSmallScreen(context) ? 8 : 12),
                Expanded(
                  child: Text(
                    'Food Type: ${hall.foodtype ?? 'Not specified'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                      fontSize: _getResponsiveFontSize(context, 16),
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

  Widget _buildAmenitiesPage(BuildContext context) {
    final hall = widget.hall;
    final amenities = [
      {'name': 'CCTV', 'available': hall.cctv == true, 'icon': Icons.videocam_outlined},
      {'name': 'Fire Alarm', 'available': hall.fireAlarm == true, 'icon': Icons.local_fire_department_outlined},
      {'name': 'Sound System', 'available': hall.soundSystem == true, 'icon': Icons.volume_up_outlined},
      {'name': 'WiFi', 'available': hall.wifiAvailable == true, 'icon': Icons.wifi_outlined},
      {'name': 'Projector', 'available': hall.projectorAvailable == true, 'icon': Icons.video_label_outlined},
      {'name': 'Microphone', 'available': hall.microphoneAvailable == true, 'icon': Icons.mic_outlined},
    ];

    final padding = _getResponsivePadding(context);
    final crossAxisCount = _getGridCrossAxisCount(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Available Amenities', Icons.star_outline),
          SizedBox(height: padding),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: _isSmallScreen(context) ? 1.2 : 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: amenities.length,
            itemBuilder: (context, i) => _buildAmenityCard(
              context,
              amenities[i]['name'] as String,
              amenities[i]['available'] as bool,
              amenities[i]['icon'] as IconData,
            ),
          ),
          if (hall.soundSystemDetails?.isNotEmpty == true)
            _buildDetailCard(context, 'Sound System Details', hall.soundSystemDetails!, Icons.music_note_outlined),
          if (hall.lightingSystemDetails?.isNotEmpty == true)
            _buildDetailCard(context, 'Lighting System Details', hall.lightingSystemDetails!, Icons.lightbulb_outline),
        ],
      ),
    );
  }

  Widget _buildPoliciesPage(BuildContext context) {
    final hall = widget.hall;
    final policies = [
      {'name': 'Valet Parking', 'allowed': hall.valetParking == true, 'icon': Icons.local_parking_outlined},
      {'name': 'Outside Food', 'allowed': hall.outsideFood == true, 'icon': Icons.fastfood_outlined},
      {'name': 'Alcohol', 'allowed': hall.allowAlcohol == true, 'icon': Icons.local_bar_outlined},
      {'name': 'Outside Decorators', 'allowed': hall.allowOutsideDecorators == true, 'icon': Icons.celebration_outlined},
      {'name': 'Outside DJ', 'allowed': hall.allowOutsideDj == true, 'icon': Icons.music_note_outlined},
    ];

    final padding = _getResponsivePadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Hall Policies', Icons.policy_outlined),
          SizedBox(height: padding),
          Column(
            children: policies.map((policy) => _buildPolicyCard(
              context,
              policy['name'] as String,
              policy['allowed'] as bool,
              policy['icon'] as IconData,
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyPage(BuildContext context) {
    final hall = widget.hall;
    final safetyItems = [
      {'title': 'Emergency Exits', 'value': '${hall.emergencyExits ?? 0}', 'icon': Icons.exit_to_app_outlined, 'color': Colors.red},
      {'title': 'Security Personnel', 'value': '${hall.securityCount ?? 0}', 'icon': Icons.security_outlined, 'color': Colors.blue},
      {'title': 'Security Level', 'value': hall.securityLevel ?? 'Basic', 'icon': Icons.shield_outlined, 'color': Colors.green},
      {'title': 'Cleaning Staff', 'value': '${hall.cleaningStaff ?? 0}', 'icon': Icons.cleaning_services_outlined, 'color': Colors.purple},
    ];

    final padding = _getResponsivePadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Safety & Security', Icons.security_outlined),
          SizedBox(height: padding),
          Column(
            children: safetyItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMetricCard(
                context,
                item['title'] as String,
                item['value'] as String,
                item['icon'] as IconData,
                item['color'] as Color,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCostsPage(BuildContext context) {
    final hall = widget.hall;
    final costs = [
      {'name': 'Cleaning Cost', 'cost': hall.cleaningCost ?? 0, 'icon': Icons.cleaning_services_outlined, 'color': Colors.blue},
      {'name': 'Security Cost', 'cost': hall.securityCost ?? 0, 'icon': Icons.security_outlined, 'color': Colors.green},
      {'name': 'Decoration Cost', 'cost': hall.decorCost ?? 0, 'icon': Icons.brush_outlined, 'color': Colors.orange},
      {'name': 'Additional Services', 'cost': hall.additionalServicesCost ?? 0, 'icon': Icons.miscellaneous_services_outlined, 'color': Colors.purple},
    ];

    final totalCost = costs.fold<int>(0, (sum, cost) => sum + (cost['cost'] as int));
    final padding = _getResponsivePadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Additional Costs', Icons.attach_money),
          SizedBox(height: padding),
          Column(
            children: [
              ...costs.map((cost) => _buildCostCard(context, cost)),
              _buildTotalCostCard(context, totalCost),
            ],
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final fontSize = _getResponsiveFontSize(context, 18);
    final iconSize = _isSmallScreen(context) ? 18.0 : 20.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.deepPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.deepPurple, size: iconSize),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
      ],
    );
  }

  Widget _buildOverviewCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final valueSize = _getResponsiveFontSize(context, 24);
    final titleSize = _getResponsiveFontSize(context, 14);
    final iconSize = _isSmallScreen(context) ? 28.0 : 32.0;

    return Container(
      padding: EdgeInsets.all(_isSmallScreen(context) ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: valueSize, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: titleSize, color: Colors.grey.shade600, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAmenityCard(BuildContext context, String name, bool available, IconData icon) {
    final color = available ? Colors.green : Colors.red;
    final iconSize = _isSmallScreen(context) ? 28.0 : 32.0;
    final textSize = _getResponsiveFontSize(context, 14);

    return Container(
      padding: EdgeInsets.all(_isSmallScreen(context) ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.shade50, color.shade100]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: color.shade700),
          const SizedBox(height: 8),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: color.shade800, fontSize: textSize), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.shade200, borderRadius: BorderRadius.circular(12)),
            child: Text(available ? 'Available' : 'Not Available', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.shade800)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, String name, bool allowed, IconData icon) {
    final color = allowed ? Colors.green : Colors.orange;
    final fontSize = _getResponsiveFontSize(context, 16);
    final padding = _getResponsivePadding(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.shade200)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.shade200, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color.shade700, size: _isSmallScreen(context) ? 20 : 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
                Text(allowed ? 'Allowed' : 'Not Allowed', style: TextStyle(color: color.shade700, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Icon(allowed ? Icons.check_circle : Icons.cancel, color: color.shade600, size: _isSmallScreen(context) ? 24 : 28),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final titleSize = _getResponsiveFontSize(context, 16);
    final valueSize = _getResponsiveFontSize(context, 18);
    final padding = _getResponsivePadding(context);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: _isSmallScreen(context) ? 20 : 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: titleSize)),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: valueSize)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostCard(BuildContext context, Map<String, dynamic> cost) {
    final color = cost['color'] as Color;
    final fontSize = _getResponsiveFontSize(context, 16);
    final padding = _getResponsivePadding(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Icon(cost['icon'] as IconData, color: color, size: _isSmallScreen(context) ? 18 : 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(cost['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize))),
          Text('₹${cost['cost']}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: fontSize)),
        ],
      ),
    );
  }

  Widget _buildTotalCostCard(BuildContext context, int totalCost) {
    final titleSize = _getResponsiveFontSize(context, 18);
    final valueSize = _getResponsiveFontSize(context, 20);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(_getResponsivePadding(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.calculate_outlined, color: Colors.white, size: _isSmallScreen(context) ? 20 : 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text('Total Additional Cost', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: titleSize))),
          Text('₹$totalCost', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: valueSize)),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, String title, String details, IconData icon) {
    final titleSize = _getResponsiveFontSize(context, 16);
    final padding = _getResponsivePadding(context);

    return Container(
      margin: EdgeInsets.only(top: padding),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: _isSmallScreen(context) ? 20 : 24),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: titleSize)),
            ],
          ),
          const SizedBox(height: 8),
          Text(details, style: TextStyle(color: Colors.blue.shade700, height: 1.4, fontSize: _getResponsiveFontSize(context, 14))),
        ],
      ),
    );
  }
}