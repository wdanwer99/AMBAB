import 'dart:developer';
import 'package:agriplant/pages/CustomButton.dart';
import 'package:agriplant/pages/CustomTextField.dart';
import 'package:agriplant/pages/auth_service.dart';
import 'package:agriplant/pages/home_page.dart';
import 'package:agriplant/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupPage> {
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _location = TextEditingController();
  final _phone = TextEditingController();

  String? _nameError;
  String? _locationError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    super.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _location.dispose();
    _phone.dispose();
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
    });

    // if (_nameError != null ||
    //     _locationError != null ||
    //     _phoneError != null ||
    //     _emailError != null ||
    //     _passwordError != null ||
    //     _confirmPasswordError != null) {
    //   return 'Please fix the errors above';
    // }
    // return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const Spacer(),
            const Text("Signup",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500)),
            const SizedBox(
              height: 50,
            ),
            CustomTextField(
              hint: "Enter Name",
              label: "Name",
              controller: _name,
            ),
            if (_nameError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_nameError!, style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter location",
              label: "Location",
              controller: _location,
            ),
            if (_locationError != null)
              Align(
                alignment: Alignment.centerLeft,
                child:
                    Text(_locationError!, style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Your Phone number",
              label: "Phone",
              controller: _phone,
            ),
            if (_phoneError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_phoneError!, style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Email",
              label: "Email",
              controller: _email,
            ),
            if (_emailError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_emailError!, style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "Enter Password",
              label: "Password",
              isPassword: true,
              controller: _password,
            ),
            if (_passwordError != null)
              Align(
                alignment: Alignment.centerLeft,
                child:
                    Text(_passwordError!, style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            CustomTextField(
              hint: "confirm Password",
              label: "Confirm Password",
              isPassword: true,
              controller: _confirmPassword,
            ),
            if (_confirmPasswordError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_confirmPasswordError!,
                    style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 30),
            CustomButton(
              label: "Signup",
              onPressed: _signup,
            ),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Already have an account? "),
              InkWell(
                onTap: () => goToLogin(context),
                child:
                    const Text("Login", style: TextStyle(color: Colors.green)),
              )
            ]),
            const Spacer()
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

  _signup() async {
    final validationMessage = _validateFields();
    if (validationMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationMessage)),
      );
      return;
    }

    try {
      final user = await _auth.createUserWithEmailAndPassword(
          _email.text, _password.text);
      if (user != null) {
        await addUserDetails(user.uid, _name.text, _email.text, _location.text,
            int.parse(_phone.text));
        log("User Created Successfully");
        goToHome(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future addUserDetails(
      String uid, String name, String email, String location, int phone) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'location': location,
      'phone': phone,
      'role': 'user',
    });
  }
}
