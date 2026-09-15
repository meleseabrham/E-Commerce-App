import 'package:flutter/material.dart';
import 'package:mehal_gebeya/utils/app_notify.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_footer.dart';
import '../../main.dart'; // Import for AppColors
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../home/home_screen.dart';
import '../../utils/error_handler.dart';


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
                  _buildRegisterButton(),
                  const SizedBox(height: 20),
                  _buildDivider(),
                  const SizedBox(height: 16),
                  _buildGoogleButton(),
                  const SizedBox(height: 20),
                  _buildFooter(context),
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
        //     color: AppColors.secondary.withOpacity(0.1),
        //     shape: BoxShape.circle,
        //   ),
        //   child: Icon(Icons.person_add_rounded, size: 40, color: AppColors.secondary),
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
          'Create your account',
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
            isConfirm: false,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm your password',
            icon: Icons.key_rounded,
            isPassword: true,
            isConfirm: true,
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
    bool isConfirm = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && (isConfirm ? _obscureConfirmPassword : _obscurePassword),
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        suffixIcon: isPassword ? IconButton(
          icon: Icon((isConfirm ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility_off : Icons.visibility, size: 20),
          onPressed: () => setState(() {
            if (isConfirm) {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            } else {
              _obscurePassword = !_obscurePassword;
            }
          }),
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Required';
        if (isPassword && !isConfirm && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (isConfirm && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
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
        onPressed: _isLoading ? null : _register,
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, endIndent: 10)),
        Text('Or continue with', style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600)),
        const Expanded(child: Divider(thickness: 1, indent: 10)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      icon: Image.asset(
        'assets/logo/google.png',
        height: 22,
        width: 22,
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
            redirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback',
          );
        } catch (e) {
          AppNotify.error(context, 'Google sign-in failed: $e');
        }
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(24),
                child: const LoginScreen(),
              ),
            );
          },
          child: Text('Sign In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check 1: RPC or users table check for existing email before attempting signup
      try {
        final existing = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('email', email)
            .maybeSingle();
        if (existing != null) {
          if (mounted) {
            AppNotify.error(context, 'This email is already registered. Please sign in instead.');
          }
          return;
        }
      } catch (_) {
        // Table or RLS check skipped, proceed to signup check
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      // Check 2: Supabase returns user with empty identities if the email already exists
      if (user != null && (user.identities == null || user.identities!.isEmpty)) {
        if (mounted) {
          AppNotify.error(context, 'This email is already registered. Please sign in instead.');
        }
        return;
      }

      if (user != null) {
        // Upsert user into public.users (safe against trigger race conditions)
        try {
          await Supabase.instance.client.from('users').upsert({
            'id': user.id,
            'email': user.email ?? email,
            'created_at': DateTime.now().toIso8601String(),
            'is_admin': false,
          });
        } catch (_) {}

        if (session != null) {
          // Immediately authenticated without confirmation link!
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('user_email', user.email ?? email);
          await prefs.setString('user_id', user.id);

          if (mounted) {
            try {
              final cartProvider = Provider.of<CartProvider>(context, listen: false);
              await cartProvider.loadUserCart();
            } catch (_) {}

            Navigator.of(context).pop(); // Close registration dialog
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: {'showLoginSuccess': true},
            );
          }
          return;
        } else {
          // If Supabase project still requires email confirmation
          if (mounted) {
            AppNotify.success(
              context,
              'Account registered! Please check your email to confirm your account.',
            );
            Navigator.of(context).pop();
            showDialog(
              context: context,
              builder: (context) => Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: const SizedBox(
                  height: 500,
                  child: LoginScreen(),
                ),
              ),
            );
          }
          return;
        }
      } else if (mounted) {
        AppNotify.error(context, 'Registration failed. Please try again.');
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('already registered') ||
          errorStr.contains('already exists') ||
          errorStr.contains('user_already_exists')) {
        if (mounted) {
          AppNotify.error(context, 'This email is already registered. Please sign in instead.');
        }
      } else {
        if (mounted) AppNotify.error(context, ErrorHandler.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
} 