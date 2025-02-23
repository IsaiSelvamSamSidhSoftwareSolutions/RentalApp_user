
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'email_verification.dart';
class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  Future<void> signupUser() async {
    final String email = emailController.text.trim();

    if (passwordController.text != confirmPasswordController.text) {
      showSnackbar("Passwords do not match!", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse(
        "https://getsetbuild.samsidh.com/api/v1/auth/vendor/signup");
    final Map<String, String> headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> body = {
      "email": email,
      "password": passwordController.text.trim(),
      "passwordConfirm": confirmPasswordController.text.trim(),
    };

    try {
      final response = await http.post(
          url, headers: headers, body: jsonEncode(body));

      setState(() => isLoading = false);

      // ✅ Print full API response
      print("API Status Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody["status"] == "success") {
        showSnackbar("OTP sent to email successfully!", Colors.green);

        // ✅ Pass email to OTP screen
        Future.delayed(Duration(seconds: 1), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(email: email),
            ),
          );
        });
      } else {
        showSnackbar(responseBody["message"] ?? "Signup failed!", Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("API Exception: $e"); // ✅ Print error in case of failure
      showSnackbar("Something went wrong! Please try again.", Colors.red);
    }
  }
  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: widget,
                  ),
                ),
                children: [
                  SizedBox(height: 80),
                  Text(
                    "Create Account,",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Sign up to get started",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 40),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                      prefixIcon: Icon(Icons.email, color: Colors.grey.shade600),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: signupUser,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Sign Up",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        "Already have an account? Login",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}