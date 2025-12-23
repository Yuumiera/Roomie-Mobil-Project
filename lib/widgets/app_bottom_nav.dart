import 'package:flutter/material.dart';
import '../services/unread_service.dart';

/// Reusable bottom navigation bar widget for the app
/// Shows Messages, Home, and Profile tabs
/// 
/// Parameters:
/// - currentIndex: 0 for Messages, 1 for Home, 2 for Profile
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    // Don't navigate if already on this tab
    if (index == currentIndex) return;
    
    // Handle navigation based on selected tab
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/messages');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UnreadService.instance,
      builder: (context, _) {
        final unreadCount = UnreadService.instance.totalUnread;
        
        return BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Badge(
                label: unreadCount > 0 ? Text('$unreadCount') : null,
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.message_outlined),
              ),
              activeIcon: Badge(
                label: unreadCount > 0 ? Text('$unreadCount') : null,
                isLabelVisible: unreadCount > 0,
                child: const Icon(Icons.message),
              ),
              label: 'Messages',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: currentIndex,
          selectedItemColor: const Color(0xFF8B4513), // Brown from sign-in page
          unselectedItemColor: Colors.grey,
          onTap: (index) => _onItemTapped(context, index),
          backgroundColor: Colors.white,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        );
      },
    );
  }
}
