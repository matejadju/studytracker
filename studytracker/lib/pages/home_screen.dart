import 'package:flutter/material.dart';

import 'timer_screen.dart';
import 'subjects_screen.dart';
import 'stats_screen.dart';
import 'profile_page.dart';
import 'progress_page.dart';
import 'ai_coach_page.dart';

import '../services/notification_service.dart';
import '../services/quote_service.dart';

class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const TimerScreen(),
      SubjectsScreen(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      ProgressPage(),
      StatsScreen(),
      ProfilePage(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Text(
            '🥠',
            style: TextStyle(fontSize: 24),
          ),
          tooltip: 'Daily motivation',
          onPressed: () => _showFortuneCookie(context),
        ),
        title: const Text('StudyTracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: widget.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Coach',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiCoachPage(),
                ),
              );
            },
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

      body: IndexedStack(
        index: widget.selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: widget.selectedIndex,
        showUnselectedLabels: true,
        onTap: widget.onTabChange,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timer"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Subjects"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: "Progress"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Statistics"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  void _showFortuneCookie(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const FortuneCookieDialog(),
    );
  }
}

/// ------------------------------------------------------
/// Widget za "otvaranje" fortune cookie
/// ------------------------------------------------------
class FortuneCookieDialog extends StatefulWidget {
  const FortuneCookieDialog({super.key});

  @override
  State<FortuneCookieDialog> createState() => _FortuneCookieDialogState();
}

class _FortuneCookieDialogState extends State<FortuneCookieDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _paperOpacity;
  late Animation<Offset> _paperSlide;

  String? _quote;
  String? _author;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _paperOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _paperSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _loadQuote();
  }

  Future<void> _loadQuote() async {
    try {
      final data = await QuoteService.getRandomQuote();
      if (!mounted) return;

      setState(() {
        _quote = data['quote'] ?? 'Keep going!';
        _author = data['author'] ?? 'Unknown';
        _loading = false;
      });

      _controller.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quote = 'Could not load your fortune. Try again later.';
        _author = '';
        _loading = false;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🥠', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 10),
                Text(
                  'Fortune Cookie',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: const [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Cracking your fortune...",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                if (!_loading)
                  SlideTransition(
                    position: _paperSlide,
                    child: FadeTransition(
                      opacity: _paperOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 22,
                              color: Colors.black.withOpacity(0.25),
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '"$_quote"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (_author != null && _author!.isNotEmpty)
                              Text(
                                '- $_author',
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
