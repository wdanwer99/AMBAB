import 'dart:developer';
import 'dart:ui';
import 'package:agriplant/pages/CustomButton.dart';
import 'package:agriplant/pages/CustomTextField.dart';
import 'package:agriplant/pages/auth_service.dart';
import 'package:agriplant/pages/home_page.dart';
import 'package:agriplant/pages/login_page.dart';
import 'package:agriplant/pages/vendor_dashboard_page.dart';
import 'package:agriplant/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  static const kAlwaysCompleteAnimation = AlwaysStoppedAnimation<double>(1.0);
  static const kAlwaysCompleteOffsetAnimation = AlwaysStoppedAnimation<Offset>(Offset.zero);

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();
  final _storeName = TextEditingController();
  final _storeDescription = TextEditingController();

  String? _nameError;
  String? _locationError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _storeNameError;
  String? _storeDescriptionError;

  bool _isVendor = false;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
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
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _location.dispose();
    _phone.dispose();
    _storeName.dispose();
    _storeDescription.dispose();
    super.dispose();
  }

  String? _validateFields() {
    setState(() {
      _nameError = _name.text.isEmpty ? 'Please enter your name' : null;
      _locationError =
          _location.text.isEmpty ? 'Please enter your location' : null;
      _phoneError = _phone.text.isEmpty || _phone.text.length < 10
          ? 'Please enter a valid phone number'
          : null;
      _emailError = _email.text.isEmpty || !_email.text.contains('@')
          ? 'Please enter a valid email address'
          : null;
      _passwordError = _password.text.isEmpty || _password.text.length < 6
          ? 'Password must be at least 6 characters long'
          : null;
      _confirmPasswordError = _password.text != _confirmPassword.text
          ? 'Passwords do not match'
          : null;
      if (_isVendor) {
        _storeNameError = _storeName.text.isEmpty ? 'Please enter store name' : null;
        _storeDescriptionError = _storeDescription.text.isEmpty ? 'Please enter store description' : null;
      } else {
        _storeNameError = null;
        _storeDescriptionError = null;
      }
    });
    if (_nameError != null ||
        _locationError != null ||
        _phoneError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null ||
        (_isVendor && (_storeNameError != null || _storeDescriptionError != null))) {
      return 'Please fix the errors above';
    }
    return null;
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _animationController?.reset();
      _animationController?.forward();
    } else {
      _signup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController?.reset();
      _animationController?.forward();
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
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_isVendor ? 'assets/tractor.jpg' : 'assets/seeds.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
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
                          "Create Your Account",
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
                    const SizedBox(height: 16),
                    // Stepper indicator
                    FadeTransition(
                      opacity: _fadeAnimation ?? kAlwaysCompleteAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < 3; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: i == _currentStep ? 30 : 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: i == _currentStep 
                                    ? theme.primaryColor 
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                        ],
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
                                // Step content
                                _buildCurrentStepContent(theme),
                                const SizedBox(height: 24),
                                // Navigation buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (_currentStep > 0)
                                      ElevatedButton.icon(
                                        onPressed: _previousStep,
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text("Back"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade200,
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    ElevatedButton.icon(
                                      onPressed: _isLoading ? null : _nextStep,
                                      icon: _isLoading 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward),
                                      label: Text(_currentStep == 2 ? "Sign Up" : "Next"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Login prompt
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Already have an account? "),
                                    GestureDetector(
                                      onTap: () => goToLogin(context),
                                      child: Text(
                                        "Login",
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

  Widget _buildCurrentStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Account Type",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildAccountTypeCard(
                    title: "Customer",
                    icon: Icons.person,
                    isSelected: !_isVendor,
                    onTap: () {
                      setState(() {
                        _isVendor = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAccountTypeCard(
                    title: "Vendor",
                    icon: Icons.store,
                    isSelected: _isVendor,
                    onTap: () {
                      setState(() {
                        _isVendor = true;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _isVendor 
                  ? "Create a vendor account to sell your agricultural products and services"
                  : "Create a customer account to purchase agricultural products and services",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                "Personal Information",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Name",
              label: "Name",
              controller: _name,
              errorText: _nameError,
              prefixIcon: Icons.person,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hint: "Enter Location",
              label: "Location",
              controller: _location,
              errorText: _locationError,
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hint: "Enter Your Phone number",
              label: "Phone",
              controller: _phone,
              errorText: _phoneError,
              prefixIcon: Icons.phone,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                _isVendor ? "Account & Store Details" : "Account Details",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Email",
              label: "Email",
              controller: _email,
              errorText: _emailError,
              prefixIcon: Icons.email,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hint: "Enter Password",
              label: "Password",
              isPassword: true,
              controller: _password,
              errorText: _passwordError,
              prefixIcon: Icons.lock,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              hint: "Confirm Password",
              label: "Confirm Password",
              isPassword: true,
              controller: _confirmPassword,
              errorText: _confirmPasswordError,
              prefixIcon: Icons.lock_outline,
            ),
            // Animated vendor fields
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isVendor
                  ? Column(
                      key: const ValueKey('vendorFields'),
                      children: [
                        const SizedBox(height: 16),
                        CustomTextField(
                          hint: "Enter Store Name",
                          label: "Store Name",
                          controller: _storeName,
                          errorText: _storeNameError,
                          prefixIcon: Icons.store,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hint: "Enter Store Description",
                          label: "Store Description",
                          controller: _storeDescription,
                          errorText: _storeDescriptionError,
                          prefixIcon: Icons.description,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAccountTypeCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green : Colors.grey.shade700,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  goToLogin(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );

  goToHome(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );

  goToVendorDashboard(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VendorDashboardPage()),
      );

  _signup() async {
    final validationMessage = _validateFields();
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage)),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      log("Starting signup process...");
      final user = await _auth.createUserWithEmailAndPassword(
          _email.text, _password.text);
      if (user != null) {
        log("User created with ID: ${user.id}");
        if (_isVendor) {
          log("Creating vendor profile...");
          try {
            await SupabaseService.createVendor(
              userId: user.id,
              name: _name.text,
              email: _email.text,
              location: _location.text,
              phone: int.parse(_phone.text),
              storeName: _storeName.text,
              storeDescription: _storeDescription.text,
            );
            log("Vendor profile created successfully");
          } catch (e) {
            log("Error creating vendor profile: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating vendor profile: $e')),
            );
            setState(() { _isLoading = false; });
            return;
          }
          log("Creating user record...");
          try {
            await SupabaseService.createUser(
              userId: user.id,
              name: _name.text,
              email: _email.text,
              location: _location.text,
              phone: int.parse(_phone.text),
              role: 'vendor',
            );
            log("User record created successfully");
          } catch (e) {
            log("Error creating user record: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating user record: $e')),
            );
            setState(() { _isLoading = false; });
            return;
          }
          log("Vendor Created Successfully");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vendor account created successfully! Please wait for admin approval.'),
              duration: Duration(seconds: 4),
            ),
          );
          goToHome(context);
        } else {
          log("Creating user record...");
          try {
            await SupabaseService.createUser(
              userId: user.id,
              name: _name.text,
              email: _email.text,
              location: _location.text,
              phone: int.parse(_phone.text),
              role: 'user',
            );
            log("User record created successfully");
          } catch (e) {
            log("Error creating user record: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error creating user record: $e')),
            );
            setState(() { _isLoading = false; });
            return;
          }
          log("User Created Successfully");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User account created successfully!')),
          );
          goToHome(context);
        }
      } else {
        log("User creation failed - user is null");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create user account')),
        );
      }
    } catch (e) {
      log("Signup error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}