import 'package:agriplant/pages/home_page.dart';
import 'package:agriplant/pages/login_page.dart';
import 'package:agriplant/pages/onboarding_page.dart';
import 'package:agriplant/pages/vendor_pending_approval_page.dart';
import 'package:agriplant/pages/vendor_dashboard_page.dart';
import 'package:agriplant/pages/admin_page.dart';
import 'package:agriplant/services/supabase_service.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false; // You can store this in SharedPreferences
  String? _userRole;
  bool _isVendorApproved = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Check if user has seen onboarding (you can implement this with SharedPreferences)
    // For now, we'll assume they have seen it
    _hasSeenOnboarding = true;
    
    // Check authentication state
    final user = SupabaseService.getCurrentUser();
    print('AuthWrapper: User authentication check - User: ${user?.id}');
    
    if (user != null) {
      try {
        // Get user role and vendor approval status
        final userData = await SupabaseService.getUser(user.id);
        _userRole = userData?['role'];
        
        if (_userRole == 'vendor') {
          _isVendorApproved = await SupabaseService.isVendorApproved(user.id);
        }
        
        print('AuthWrapper: User role - $_userRole, Vendor approved - $_isVendorApproved');
      } catch (e) {
        print('AuthWrapper: Error getting user data: $e');
      }
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check if user has seen onboarding
    if (!_hasSeenOnboarding) {
      print('AuthWrapper: Showing onboarding page');
      return const OnboardingPage();
    }

    // Check if user is authenticated
    final user = SupabaseService.getCurrentUser();
    print('AuthWrapper: Current user - ${user?.id}');
    
    if (user == null) {
      print('AuthWrapper: User not authenticated, showing login page');
      return const LoginPage();
    }

    // User is authenticated, route based on role and approval status
    print('AuthWrapper: User role - $_userRole, Vendor approved - $_isVendorApproved');
    
    if (_userRole == 'admin') {
      print('AuthWrapper: Showing admin page');
      return const AdminPage();
    } else if (_userRole == 'vendor') {
      if (_isVendorApproved) {
        print('AuthWrapper: Showing vendor dashboard (approved)');
        return const VendorDashboardPage();
      } else {
        print('AuthWrapper: Showing vendor pending approval page');
        return const VendorPendingApprovalPage();
      }
    } else {
      // Default user or customer
      print('AuthWrapper: Showing home page');
      return const HomePage();
    }
  }
} 