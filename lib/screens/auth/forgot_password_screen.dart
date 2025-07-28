import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_footer.dart';
import '../../theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await Supabase.instance.client.auth.resetPasswordForEmail(_emailController.text.trim());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link has been sent to your email. Please check your inbox.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Wait for 2 seconds to show the success message before popping
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } catch (e) {
        String errorMsg = 'Failed to send reset link. Please try again.';
        if (e.toString().contains('user-not-found')) {
          errorMsg = 'No account found with this email address.';
        } else if (e.toString().contains('invalid-email')) {
          errorMsg = 'Please enter a valid email address.';
        } else if (e.toString().contains('network-request-failed')) {
          errorMsg = 'Network error. Please check your internet connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
                          const SizedBox(height: 40),
                          const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 54),
                          const Text(
                            'Enter your email address and we\'ll send you a link to reset your password.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 34),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 34),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                 backgroundColor: AppColors.secondary,
                                side: BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: _isLoading ? null : _resetPassword,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Send Reset Link',
                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                    ),
                            ),
                          ),
                        ],
                      ),
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