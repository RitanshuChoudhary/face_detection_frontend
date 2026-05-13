import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/loading_overlay.dart';
import '../admin/dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.currentUser;
      if (user != null) {
        Widget destination;
        if (user.role == 'admin' || user.role == 'teacher') {
          destination = const DashboardScreen();
        } else {
          destination = const StudentDashboardScreen();
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => destination,
            transitionsBuilder: (context, anim, secAnim, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: anim, child: child),
              );
            },
          ),
        );
      }
    } else {
      // Display failure notice
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(authProvider.errorMessage ?? 'Authentication failed')),
            ],
          ),
          backgroundColor: AppConstants.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: LoadingOverlay(
        isLoading: authProvider.isLoading,
        message: 'Verifying your identity...',
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [AppConstants.darkBackground, const Color(0xFF1E1E2F)]
                    : [AppConstants.primaryLight.withOpacity(0.4), AppConstants.background],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                
                // Welcome header section
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_person_outlined,
                      color: AppConstants.primary,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppConstants.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Sign in to your Face Track portal',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppConstants.textMuted : AppConstants.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Form details
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomInput(
                            label: 'Email Address',
                            hint: 'teacher@school.com',
                            prefixIcon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Please enter your email';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CustomInput(
                            label: 'Password',
                            hint: '••••••',
                            prefixIcon: Icons.vpn_key_outlined,
                            controller: _passwordController,
                            isPassword: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter your password';
                              if (v.length < 6) return 'Password must contain at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          CustomButton(
                            text: 'Login',
                            onPressed: _submitLogin,
                            isLoading: authProvider.isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Navigation to register
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: isDark ? AppConstants.textMuted : AppConstants.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Register Here',
                          style: TextStyle(
                            color: AppConstants.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
