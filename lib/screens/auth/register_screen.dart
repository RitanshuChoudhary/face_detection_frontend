import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/loading_overlay.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'teacher'; // 'teacher' or 'student'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Registration successful! Please login.'),
            ],
          ),
          backgroundColor: AppConstants.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(authProvider.errorMessage ?? 'Registration failed')),
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
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: authProvider.isLoading,
        message: 'Creating secure account...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Face Track',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Register your credentials to start',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppConstants.textMuted : AppConstants.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
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
                          label: 'Full Name',
                          hint: 'Professor Smith',
                          prefixIcon: Icons.person_outline,
                          controller: _nameController,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter your full name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomInput(
                          label: 'Email Address',
                          hint: 'smith@school.com',
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
                            if (v == null || v.isEmpty) return 'Please enter a password';
                            if (v.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Role selection dropdown/radio
                        const Text(
                          'Your Portal Role',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Teacher')),
                                selected: _selectedRole == 'teacher',
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == 'teacher' ? Colors.white : Colors.grey,
                                ),
                                selectedColor: AppConstants.primary,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedRole = 'teacher');
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Student')),
                                selected: _selectedRole == 'student',
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedRole == 'student' ? Colors.white : Colors.grey,
                                ),
                                selectedColor: AppConstants.primary,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedRole = 'student');
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        CustomButton(
                          text: 'Register',
                          onPressed: _submitRegistration,
                          isLoading: authProvider.isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      color: AppConstants.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
