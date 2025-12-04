import 'package:flutter/material.dart';
import 'timer_screen.dart';
import 'subjects_screen.dart';
import 'stats_screen.dart';
import 'profile_page.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.selectedIndex,
    required this.onTabChange,
  });

  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  final int selectedIndex;               
  final ValueChanged<int> onTabChange;   

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const TimerScreen(),
      SubjectsScreen(),
      const StatsScreen(),
      ProfilePage(                    // 👈 OVDE prosledimo
        onToggleTheme: onToggleTheme,
        isDarkMode: isDarkMode,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyTracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              NotificationService().showInstantNotification(
                title: 'Personal notification',
                body: 'If you see this, you should start learning!',
              );
            },
          ),
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        showUnselectedLabels: true,
        onTap: onTabChange,   // više nema setState ovde
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timer"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Subjects"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Statistics"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
