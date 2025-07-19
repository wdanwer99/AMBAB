import 'dart:ui';
import 'package:agriplant/pages/home_page.dart';
import 'package:agriplant/pages/explore_page.dart'; // Add this import
import 'package:agriplant/pages/admin_page.dart'; // Add this import
import 'package:agriplant/pages/vendor_dashboard_page.dart'; // Add this import
import 'package:agriplant/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'package:agriplant/pages/CustomTextField.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Add animation controller
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  static const kAlwaysCompleteAnimation = AlwaysStoppedAnimation<double>(1.0);
  static const kAlwaysCompleteOffsetAnimation = AlwaysStoppedAnimation<Offset>(Offset.zero);
  
  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));
    
    // Start the animation
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateFields() {
    setState(() {
      _emailError =
          _emailController.text.isEmpty || !_emailController.text.contains('@')
              ? 'Please enter a valid email address'
              : null;
      _passwordError = _passwordController.text.isEmpty ||
              _passwordController.text.length < 6
          ? 'Password must be at least 6 characters long'
          : null;
    });

    if (_emailError != null || _passwordError != null) {
      return 'Please fix the errors above';
    }
    return null;
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _login() async {
    final validationMessage = _validateFields();
    if (validationMessage != null) {
      _showValidationMessage(validationMessage);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SupabaseService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      final user = response.user;
      if (user != null) {
        final userData = await SupabaseService.getUser(user.id);
        final role = userData?['role'] ?? 'user';
        
        if (role == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        } else if (role == 'vendor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const VendorDashboardPage(),
            ),
          );
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPage(),
            ),
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        _showValidationMessage('Incorrect email or password');
      } else {
        _showValidationMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Background image with blur effect
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/seeds.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black54,
                  BlendMode.darken,
                ),
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with animation
                    FadeTransition(
                      opacity: _fadeAnimation ?? kAlwaysCompleteAnimation,
                      child: SlideTransition(
                        position: _slideAnimation ?? kAlwaysCompleteOffsetAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title with animation
                    FadeTransition(
                      opacity: _fadeAnimation ?? kAlwaysCompleteAnimation,
                      child: SlideTransition(
                        position: _slideAnimation ?? kAlwaysCompleteOffsetAnimation,
                        child: Text(
                          "Welcome Back!",
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Card for form with animation
                    FadeTransition(
                      opacity: _fadeAnimation ?? kAlwaysCompleteAnimation,
                      child: SlideTransition(
                        position: _slideAnimation ?? kAlwaysCompleteOffsetAnimation,
                        child: Container(
                          width: size.width > 600 ? 500 : double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  hint: "Enter your email",
                                  label: "Email",
                                  controller: _emailController,
                                  errorText: _emailError,
                                  prefixIcon: Icons.email,
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  hint: "Enter your password",
                                  label: "Password",
                                  controller: _passwordController,
                                  isPassword: true,
                                  errorText: _passwordError,
                                  prefixIcon: Icons.lock,
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: theme.primaryColor,
                                    ),
                                    onPressed: _isLoading ? null : _login,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : const Text(
                                            "Login",
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Don't have an account? "),
                                    GestureDetector(
                                      onTap: () => goToSignup(context),
                                      child: Text(
                                        "Signup",
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  goToSignup(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
}