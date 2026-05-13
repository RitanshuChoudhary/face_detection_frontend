import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'admin/dashboard_screen.dart';
import 'student/student_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for animation to finish and then perform token verification
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkAutoLogin();

    if (!mounted) return;

    if (isLoggedIn) {
      final user = authProvider.currentUser;
      if (user != null) {
        if (user.role == 'admin' || user.role == 'teacher') {
          _navigateTo(const DashboardScreen());
        } else {
          _navigateTo(const StudentDashboardScreen());
        }
      } else {
        _navigateTo(const LoginScreen());
      }
    } else {
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBackground : AppConstants.background,
      body: Stack(
        children: [
          // Background Gradient blobs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primary.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.accent.withOpacity(0.08),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Logo Badge
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppConstants.primary, AppConstants.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primary.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // App Name
                    Text(
                      'Face Track',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white : AppConstants.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'AI Attendance Tracking System',
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppConstants.textMuted : AppConstants.textLight,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Soft Loader
                    const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppConstants.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Text(
                'v1.0.0 • Powered by Deep Learning',
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textMuted.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
