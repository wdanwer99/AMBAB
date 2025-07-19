import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agriplant/services/supabase_service.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        userData: {},
      );
      return response.user;
    } catch (e) {
      log("Something went wrong: $e");
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      log("Something went wrong: $e");
    }
    return null;
  }

  Future<void> signout() async {
    try {
      await SupabaseService.signOut();
    } catch (e) {
      log("Something went wrong: $e");
    }
  }

  User? getCurrentUser() {
    return SupabaseService.getCurrentUser();
  }
}
