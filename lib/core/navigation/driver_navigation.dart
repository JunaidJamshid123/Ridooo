import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../features/driver/home/presentation/pages/driver_home_page.dart';
import '../../features/driver/earnings/presentation/pages/earnings_page.dart';
import '../../features/driver/trips/presentation/pages/driver_rides_page.dart';
import '../../features/driver/chat/presentation/pages/driver_chat_list_page.dart';
import '../../features/driver/profile/presentation/pages/driver_profile_page.dart';

/// Bottom navigation for Driver app
class DriverNavigation extends StatefulWidget {
  final Widget? child;

  const DriverNavigation({super.key, this.child});

  @override
  State<DriverNavigation> createState() => _DriverNavigationState();
}

class _DriverNavigationState extends State<DriverNavigation> {
  int _currentIndex = 0;

  // Driver pages - using real data page instead of mock
  final List<Widget> _pages = const [
    DriverHomePage(),
    DriverRidesPage(),  // Changed from DriverTripsPage to use real Supabase data
    EarningsPage(),
    DriverChatListPage(),
    DriverProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: widget.child != null ? [widget.child!] : _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, 'assets/images/svg/home.svg', 'Home'),
                _buildNavItemPng(1, 'assets/images/png/road.png', 'Rides'),
                _buildNavItem(2, 'assets/images/svg/payments.svg', 'Payments'),
                _buildNavItem(3, 'assets/images/svg/chat.svg', 'Chats'),
                _buildNavItem(4, 'assets/images/svg/profile.svg', 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 26,
              height: 26,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.black : Colors.grey[400]!,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemPng(int index, String iconPath, String label) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 26,
              height: 26,
              color: isSelected ? Colors.black : Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.black : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
