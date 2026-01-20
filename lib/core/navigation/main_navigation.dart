import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/user/activity/presentation/pages/activity_page.dart';
import '../../features/user/payment/presentation/pages/payment_page.dart';
import '../../features/user/chat/presentation/pages/user_chat_list_page.dart';
import '../../features/user/profile/presentation/pages/user_profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Lazy load pages - only create when first accessed
  final Map<int, Widget> _cachedPages = {};

  Widget _getPage(int index) {
    if (!_cachedPages.containsKey(index)) {
      switch (index) {
        case 0:
          _cachedPages[index] = const HomePage();
          break;
        case 1:
          _cachedPages[index] = const UserActivityPage();
          break;
        case 2:
          _cachedPages[index] = const UserPaymentPage();
          break;
        case 3:
          _cachedPages[index] = const UserChatListPage();
          break;
        case 4:
          _cachedPages[index] = const UserProfilePage();
          break;
      }
    }
    return _cachedPages[index]!;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure current page is loaded
    _getPage(_currentIndex);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          5,
          (index) => _cachedPages.containsKey(index)
              ? _cachedPages[index]!
              : Container(), // Empty placeholder for unvisited pages
        ),
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
                _buildNavItem(1, 'assets/images/svg/activity.svg', 'Activity'),
                _buildNavItem(2, 'assets/images/svg/payments.svg', 'Payment'),
                _buildNavItem(3, 'assets/images/svg/chat.svg', 'Chat'),
                _buildNavItem(4, 'assets/images/svg/profile.svg', 'Account'),
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
}
