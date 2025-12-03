import 'package:flutter/material.dart';
import 'timer_screen.dart';
import 'subjects_screen.dart';
import 'stats_screen.dart';
import 'profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    TimerScreen(),
    SubjectsScreen(),
    StatsScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyTracker'),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  currentIndex: _selectedIndex,
  selectedItemColor: Colors.blue,      // selected tab
  unselectedItemColor: Colors.grey,    // other tabs
  backgroundColor: Colors.white,       // bar background
  showUnselectedLabels: true,
  onTap: (index) {
    setState(() => _selectedIndex = index);
  },
  items: const [
    BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timer"),
    BottomNavigationBarItem(icon: Icon(Icons.book), label: "Subjects"),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Statistics"),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
  ],
),

    );
  }
}
