



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
import 'package:mehal_gebeya/screens/auth/forgot_password_screen.dart'; // Added import for ForgotPasswordScreen
import 'package:mehal_gebeya/screens/auth/registration_screen.dart'; // Added import for RegistrationScreen


class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

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

          // Call onLoginSuccess if provided
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!();
            return;
          }

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

          // Call onLoginSuccess if provided
          if (widget.onLoginSuccess != null) {
            widget.onLoginSuccess!();
            return;
          }

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
                      onPressed: _isLoading ? null : _signInWithEmail,
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
                              'Login',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                        ),
                        elevation: 0,
                      ),
                      icon: Image.asset('assets/logo/google.png', height: 24),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _isLoading ? null : _signInWithGoogle,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                       showDialog(
                         context: context,
                         builder: (context) => Dialog(
                           insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                           child: SizedBox(
                             width: 400,
                             child: ForgotPasswordScreen(),
                           ),
                         ),
                       );
                      },
                      child: Text('Forgot Password?', style: TextStyle(color: AppColors.highlight)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                       GestureDetector(
                         onTap: () {
                           showDialog(
                             context: context,
                             builder: (context) => Dialog(
                               insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                               child: SizedBox(
                                 width: 400,
                                 child: RegistrationScreen(),
                               ),
                             ),
                           );
                         },
                         child: Text('Register', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
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
} 