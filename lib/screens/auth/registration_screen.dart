import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_footer.dart';
import '../../main.dart'; // Import for AppColors
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import 'package:mehal_gebeya/theme/app_colors.dart'; // Added import for AppColors

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 6,
              shadowColor: AppColors.shadow,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(text: 'M', style: TextStyle(color: AppColors.primary)),
                            TextSpan(text: 'e', style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(text: 'H', style: TextStyle(color: AppColors.warningColor)),
                            TextSpan(text: 'al ', style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(text: 'G', style: TextStyle(color: AppColors.error)),
                            TextSpan(text: 'ebeya', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () {
                             Navigator.of(context).pop(); 
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                child: SizedBox(
                         
                                  height: 500,
                                  child: LoginScreen(),
                                ),
                              ),
                            );
                          },
                          child: Text('Login', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        // Insert user metadata into 'users' table
        await Supabase.instance.client.from('users').insert({
          'id': response.user!.id,
          'email': response.user!.email,
          'created_at': DateTime.now().toIso8601String(),
          'is_admin': false,
        });
        // After registration, go to login page
        if (mounted) {
          Navigator.of(context).pop(); // Close registration dialog if open
          showDialog(
            context: context,
            builder: (context) => Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: SizedBox(
                height: 500,
                child: LoginScreen(),
              ),
            ),
          );
        }
        return;
      } else if (response.user == null && response.session == null) {
        // Email confirmation required
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration successful! Please check your email to confirm your account.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('No address associated')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No internet connection.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (errorStr.contains('email already in use')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This email is already registered. Please use a different email.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (errorStr.contains('invalid_email')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter a valid email address.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
} 