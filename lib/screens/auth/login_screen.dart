



import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../../widgets/social_footer.dart';
import '../../main.dart'; // Import for AppColors
import '../../widgets/order_receipt_checker.dart';
import 'package:mehal_gebeya/theme/app_colors.dart'; // Added import for AppColors


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (userCredential != null && userCredential.user != null && mounted) {
        // Update last login timestamp in Firestore
        await FirebaseService.updateUserLastLogin(userCredential.user!.uid);
        
        // Save login state and user info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', userCredential.user!.email ?? '');
        await prefs.setString('user_id', userCredential.user!.uid);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful! Welcome to MeHal Gebeya'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Clear the form
          _emailController.clear();
          _passwordController.clear();

          // Navigate after showing the message
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed. Please try again.';
        
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No account found with this email. Please register first.';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password. Please try again.';
          // Clear only password field on wrong password
          _passwordController.clear();
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many failed attempts. Please try again later.';
          // Clear both fields on too many attempts
          _emailController.clear();
          _passwordController.clear();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: e.toString().contains('user-not-found')
                ? SnackBarAction(
                    label: 'Register',
                    textColor: Colors.white,
                    onPressed: () {
                      // Clear fields before navigating
                      _emailController.clear();
                      _passwordController.clear();
                      Navigator.pushNamed(context, '/register');
                    },
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseService.signInWithGoogle();

      if (userCredential != null && userCredential.user != null && mounted) {
        // Update last login timestamp in Firestore
        await FirebaseService.updateUserLastLogin(userCredential.user!.uid);
        
        // Save login state and user info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_email', userCredential.user!.email ?? '');
        await prefs.setString('user_id', userCredential.user!.uid);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google sign-in successful! Welcome to MeHal Gebeya'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Clear any existing form data
          _emailController.clear();
          _passwordController.clear();

          // Navigate after showing the message
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Google sign-in failed. Please try again.';
        
        if (e.toString().contains('network-request-failed')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('sign_in_canceled')) {
          errorMessage = 'Sign-in cancelled.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside input fields
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: 'M',
                          style: TextStyle(color: AppColors.primary),
                        ),
                        TextSpan(
                          text: 'e',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textPrimary
                              : AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: 'H',
                          style: TextStyle(color: AppColors.warningColor),
                        ),
                        TextSpan(
                          text: 'al ',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textPrimary
                              : AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: 'G',
                          style: TextStyle(color: AppColors.error),
                        ),
                        TextSpan(
                          text: 'ebeya',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textPrimary
                              : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.email, color: AppColors.primary),
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signInWithEmail(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                            labelStyle: TextStyle(color: AppColors.textSecondary),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
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
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signInWithEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/logo/google.png',
                      height: 24,
                    ),
                    label: Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const SocialFooter(),
                  const SizedBox(height: 32),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 