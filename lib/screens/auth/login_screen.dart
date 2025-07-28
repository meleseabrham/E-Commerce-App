



import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../../widgets/social_footer.dart';
import '../../main.dart'; // Import for AppColors
import '../../widgets/order_receipt_checker.dart';
import 'package:mehal_gebeya/theme/app_colors.dart'; // Added import for AppColors
import 'package:mehal_gebeya/screens/auth/forgot_password_screen.dart'; // Added import for ForgotPasswordScreen
import 'package:mehal_gebeya/screens/auth/registration_screen.dart'; // Added import for RegistrationScreen
import 'package:mehal_gebeya/providers/cart_provider.dart'; // Added import for CartProvider
import 'package:provider/provider.dart'; // Added import for Provider


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
  FocusScope.of(context).unfocus();

  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (response.user != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', response.user!.email ?? '');
      await prefs.setString('user_id', response.user!.id);

      _emailController.clear();
      _passwordController.clear();

      // Load user cart after login
      if (mounted) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        await cartProvider.loadUserCart();
      }

      // Redirect to payment if needed
      final userId = response.user!.id;
      final userProfile = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (userProfile != null && userProfile['is_admin'] == true) {
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {'showLoginSuccess': true},
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'showLoginSuccess': true},
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed.'),
          backgroundColor: Colors.red,
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
    } else if (errorStr.contains('invalid_credentials')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid email and password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  // TODO: Implement Supabase social login if needed. Removed Google login button and _signInWithGoogle reference.

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
                    TextButton(
                      onPressed: () {
                         Navigator.of(context).pop(); 
                       showDialog(
                         context: context,
                         builder: (context) => Dialog(
                           insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                           child: SizedBox(
                             
                             height: 500,
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
                           Navigator.of(context).pop(); // Close the login dialog first
                           showDialog(
                             context: context,
                             builder: (context) => Dialog(
                               insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                               child: SizedBox(
                               
                                 height: 500,
                                 child: RegistrationScreen(),
                               ),
                             ),
                           );
                         },
                         child: Text('Register', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                       ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Image.network(
                        'https://lpndjssicpcnssmngqln.supabase.co/storage/v1/object/sign/mehalgebeya/assets/logo/google.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yMjMyMzlhYy1jM2IwLTQ5ZDEtYmQzYS0wYzg4NWMwNDkxZmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJtZWhhbGdlYmV5YS9hc3NldHMvbG9nby9nb29nbGUucG5nIiwiaWF0IjoxNzUyNzYwMDU1LCJleHAiOjE3ODQyOTYwNTV9.5_zHriiLO0wjWJlraRuFwab1phtyNWBZACTI-UEgxL0',
                        height: 24,
                        width: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/logo/google.png',
                          height: 24,
                          width: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                      label: const Text('Continue with Google', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        side: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      onPressed: () async {
                        try {
                          await Supabase.instance.client.auth.signInWithOAuth(
                            OAuthProvider.google,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Google sign-in failed: $e')),
                          );
                        }
                      },
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