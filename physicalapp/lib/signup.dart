import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || password.isEmpty) {
      _showMessage('Please fill all fields');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': name,
          'password': password,
          'third_party_id': null
        }),
      );

      if (response.statusCode == 201) {
        _showMessage('Sign up successful!');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        final body = jsonDecode(response.body);
        _showMessage(body['message'] ?? 'Sign up failed');
      }
    } catch (e) {
      _showMessage('Network error: $e');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildField(controller: _nameController, label: 'username'),
                    _buildField(controller: _passwordController, label: 'password', obscure: true),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Register'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.black), // 文字顏色
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87), // 標籤文字
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black45), // 預設底線
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black), // 聚焦底線
          ),
        ),
      ),
    );
  }
}
