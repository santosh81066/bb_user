import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Screens/home.dart';
import '../Screens/managebooking.dart';
import '../Screens/settings.dart';
import '../Screens/venues.dart';

class ResponsiveNavigation extends StatefulWidget {
  const ResponsiveNavigation({Key? key}) : super(key: key);

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  int _selectedIndex = 0;

  // Page options
  final List<Widget> _pageOptions = [
    HomeScreen(),
    Venuscreen(),
    ManageBookingScreen(),
    SettingsScreen(),
  ];

  // Improved Navigation items data with better icon choices for a banquet booking app
  final List<NavigationItemData> _navItems = [
    NavigationItemData(
      icon: Icons.dashboard_rounded,              // Dashboard icon for home
      label: 'Home',
      activeColor: Color(0xFF6A5AE0),             // Primary purple
    ),
    NavigationItemData(
      icon: Icons.explore_rounded,             // Restaurant icon for venues
      label: 'Venues',
      activeColor: Color(0xFFF8742C),             // Orange
    ),
    NavigationItemData(
      icon: Icons.rate_review_rounded,        // Event available icon for bookings
      label: 'Bookings',
      activeColor: Color(0xFF00C48C),             // Green
    ),
    NavigationItemData(
      icon: Icons.account_circle_rounded,         // Account circle for profile
      label: 'Profile',
      activeColor: Color(0xFF3E76EC),             // Blue
    ),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    // Add haptic feedback on tap
    HapticFeedback.selectionClick();

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get MediaQuery information
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final orientation = mediaQuery.orientation;
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final padding = mediaQuery.padding;
    final viewInsets = mediaQuery.viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;

    // Calculate dimensions based on screen size
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    final isTablet = screenWidth > 768;
    final isLandscape = orientation == Orientation.landscape;

    // Skip bottom navigation when keyboard is open
    if (isKeyboardOpen) {
      return Scaffold(
        body: _pageOptions[_selectedIndex],
      );
    }

    // For landscape on phones, use side navigation
    if (isLandscape && !isTablet) {
      return Scaffold(
        body: Row(
          children: [
            _buildSideNavigation(context, isSmallScreen),
            Expanded(child: _pageOptions[_selectedIndex]),
          ],
        ),
      );
    }

    // Default: bottom navigation
    return Scaffold(
      body: _pageOptions[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigation(
          context,
          isSmallScreen: isSmallScreen,
          isLargeScreen: isLargeScreen,
          isTablet: isTablet,
          screenWidth: screenWidth,
          bottomPadding: padding.bottom
      ),
    );
  }

  // Side navigation for landscape mode
  Widget _buildSideNavigation(BuildContext context, bool isSmallScreen) {
    // Adjust width based on screen size
    final navWidth = isSmallScreen ? 60.0 : 70.0;

    return Container(
      width: navWidth,
      color: Theme.of(context).brightness == Brightness.dark
          ? Color(0xFF1F1F1F)
          : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            // App logo with banquet-related icon
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Color(0xFF6A5AE0).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.deck_rounded,  // Changed to a more banquet/event focused icon
                color: Color(0xFF6A5AE0),
              ),
            ),
            SizedBox(height: 20),
            // Navigation items
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 8), // Added padding to fix potential overflow
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = index == _selectedIndex;

                  return _buildSideNavItem(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => _onItemTapped(index),
                    isSmallScreen: isSmallScreen,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Individual side navigation item
  Widget _buildSideNavItem({
    required NavigationItemData item,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? item.activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          clipBehavior: Clip.none, // Prevent clipping issues
          children: [
            if (isSelected)
              Positioned(
                left: 0,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: item.activeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Use minimum space required
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected ? item.activeColor : Colors.grey,
                    size: isSelected ? 28 : 24,
                  ),
                  if (!isSmallScreen)
                    SizedBox(height: 4),
                  if (!isSmallScreen)
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? item.activeColor : Colors.grey,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom navigation bar with enhanced animations for better user feedback
  Widget _buildBottomNavigation(
      BuildContext context, {
        required bool isSmallScreen,
        required bool isLargeScreen,
        required bool isTablet,
        required double screenWidth,
        required double bottomPadding,
      }) {
    // Adjust height based on screen size and bottom padding (add buffer for overflow)
    final bottomNavHeight = isTablet ? 80.0 : (isSmallScreen ? 65.0 : 76.0);

    // Calculate total height including safe area padding
    final totalHeight = bottomNavHeight + bottomPadding;

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Color(0xFF1F1F1F)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, -5),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLargeScreen ? 25 : 20),
          topRight: Radius.circular(isLargeScreen ? 25 : 20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed to spaceEvenly for better distribution
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = index == _selectedIndex;

            // Calculate sizes based on screen width
            final itemWidth = (screenWidth / _navItems.length) - 4; // Slight reduction for safety
            final isCompactLayout = itemWidth < 70;
            final iconSize = isSelected
                ? (isTablet ? 32.0 : 26.0)
                : (isTablet ? 28.0 : 22.0);
            final fontSize = isTablet ? 14.0 : 11.0; // Slightly smaller text

            return InkWell(
              onTap: () => _onItemTapped(index),
              child: SizedBox(
                width: itemWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Use minimum space required
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated container for the icon
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      builder: (context, double value, child) {
                        return Container(
                          padding: EdgeInsets.all(isCompactLayout ? 6 : 8), // Reduced padding
                          decoration: BoxDecoration(
                            color: item.activeColor.withOpacity(0.1 * value),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: EdgeInsets.only(bottom: isCompactLayout ? 0 : (4 * value)), // Reduced margin
                          child: Icon(
                            item.icon,
                            color: Color.lerp(Colors.grey, item.activeColor, value),
                            size: iconSize,
                          ),
                        );
                      },
                    ),

                    // Label (hidden on very small screens)
                    if (!isCompactLayout || isTablet)
                      SizedBox(height: 2), // Reduced space
                    if (!isCompactLayout || isTablet)
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? item.activeColor : Colors.grey,
                          fontSize: fontSize,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class NavigationItemData {
  final IconData icon;
  final String label;
  final Color activeColor;

  NavigationItemData({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}