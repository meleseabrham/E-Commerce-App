import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import 'package:mehal_gebeya/theme/app_colors.dart'; // Added import for AppColors


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                // Logo or App Name
                Center(
                  child: RichText(
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
                ),
                SizedBox(height: 40),
                // Title
                Text(
                  isLogin ? 'Welcome Back!' : 'Create Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        // Name field for registration
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                      ],
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                      SizedBox(height: 16),
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
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
                      SizedBox(height: 16),
                      if (!isLogin) ...[
                        // Confirm Password field for registration
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: true,
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
                        SizedBox(height: 16),
                      ],
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  isLogin ? 'Login' : 'Register',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Forgot Password Button
                      if (isLogin)
                        TextButton(
                          onPressed: () => _showForgotPasswordDialog(context),
                          child: Text('Forgot Password?'),
                        ),
                      // Toggle between Login and Register
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                          });
                        },
                        child: Text(
                          isLogin
                              ? 'Don\'t have an account? Register'
                              : 'Already have an account? Login',
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
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      if (isLogin) {
        // TODO: Implement actual login logic
        // For demo, we'll just store the email in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _emailController.text);
        await prefs.setBool('is_logged_in', true);
      } else {
        // TODO: Implement actual registration logic
        // For demo, we'll just store the email in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_email', _emailController.text);
        await prefs.setString('user_name', _nameController.text);
        await prefs.setBool('is_logged_in', true);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to reset your password'),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual password reset logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset link sent to your email'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            },
            child: Text('Reset Password'),
          ),
        ],
      ),
    );
  }
} 