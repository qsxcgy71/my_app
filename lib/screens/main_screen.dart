import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'activities_screen.dart';
import 'placeholder_screen.dart';
import '../styles/app_text_styles.dart';
import '../login_screen.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Show welcome message for new logins
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeMessage();
    });
  }

  void _showWelcomeMessage() {
    if (_authService.currentUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome back, ${_authService.currentUserDisplayName}!',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  final List<Widget> _screens = [
    const ProfileScreen(),
    const ActivitiesScreen(),
    const PlaceholderScreen(title: 'Information'),
  ];

  final List<String> _titles = [
    'My Profile',
    'Calendar',
    'Information',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Information',
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: AppTextStyles.titleLarge.copyWith(
            fontFamily: 'GenSenRounded',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.bodyMedium.copyWith(
            fontFamily: 'GenSenRounded',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                fontFamily: 'GenSenRounded',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              'Logout',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontFamily: 'GenSenRounded',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }
} 