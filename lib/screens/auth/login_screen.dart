



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
    final messenger = ScaffoldMessenger.of(context);
    final errorStr = e.toString();
    messenger.clearSnackBars();

    if (errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('No address associated')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No internet connection.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (errorStr.contains('invalid_credentials') || 
               errorStr.contains('Invalid login credentials') ||
               errorStr.contains('invalid-credential')) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Incorrect email and password. Please check and try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Login failed. Please try again later.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1E1E2C), const Color(0xFF11111D)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF0F2F5)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 32),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                  const SizedBox(height: 16),
                  _buildFooter(context),
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildGoogleButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Container(
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: AppColors.primary.withOpacity(0.1),
        //     shape: BoxShape.circle,
        //   ),
        //   child: Icon(Icons.lock_person_rounded, size: 40, color: AppColors.primary),
        // ),
        // const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            children: [
              TextSpan(text: 'M', style: TextStyle(color: AppColors.primary)),
              TextSpan(text: 'e', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              TextSpan(text: 'H', style: TextStyle(color: AppColors.warningColor)),
              TextSpan(text: 'al ', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
              TextSpan(text: 'G', style: TextStyle(color: AppColors.error)),
              TextSpan(text: 'ebeya', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to your account',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Enter your password',
            icon: Icons.key_rounded,
            isPassword: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: AppColors.primary.withOpacity(0.03),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 1.5),
        ),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isLoading ? null : _signInWithEmail,
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(24),
                child: const ForgotPasswordScreen(),
              ),
            );
          },
          child: Text('Forgot Password?', style: TextStyle(color: AppColors.highlight, fontWeight: FontWeight.w600)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("New here? ", style: TextStyle(color: Colors.grey)),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(24),
                    child: const RegistrationScreen(),
                  ),
                );
              },
              child: Text('Create Account', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, endIndent: 10)),
        Text('Secure Connect', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
        const Expanded(child: Divider(thickness: 1, indent: 10)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      icon: Image.network(
        'https://lpndjssicpcnssmngqln.supabase.co/storage/v1/object/sign/mehalgebeya/assets/logo/google.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yMjMyMzlhYy1jM2IwLTQ5ZDEtYmQzYS0wYzg4NWMwNDkxZmYiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJtZWhhbGdlYmV5YS9hc3NldHMvbG9nby9nb29nbGUucG5nIiwiaWF0IjoxNzUyNzYwMDU1LCJleHAiOjE3ODQyOTYwNTV9.5_zHriiLO0wjWJlraRuFwab1phtyNWBZACTI-UEgxL0',
        height: 20,
        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
      ),
      label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }
} 