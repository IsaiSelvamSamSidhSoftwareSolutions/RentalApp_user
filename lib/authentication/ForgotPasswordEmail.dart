import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ResetPasswordScreen.dart';
import 'forgot_password_otp.dart';
class ForgotPasswordEmailScreen extends StatefulWidget {
  @override
  _ForgotPasswordEmailScreenState createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  Future<void> sendOTP() async {
    final String email = emailController.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      showSnackbar("Please enter a valid email address.", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // API call to request OTP
      final url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/auth/user/forgotpassword");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      setState(() => isLoading = false);

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseBody["status"] == "success") {
          showSnackbar("OTP sent to your email!", Colors.green);

          // ✅ Navigate to ResetPasswordScreen instead of ForgotPasswordOTPScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: email), // ✅ Now going to ResetPasswordScreen
            ),
          );

        } else {
          showSnackbar(responseBody["message"] ?? "Failed to send OTP.", Colors.red);
        }
      } else if (response.statusCode == 404) {
        showSnackbar("There is no user with this email.", Colors.red);
      } else {
        showSnackbar("Failed to send OTP. Please try again.", Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
      showSnackbar("An error occurred: $e", Colors.red);
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
      appBar: AppBar(
        title: Text(
          "Forgot Password",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                "Enter Your Email",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We'll send a 6-digit OTP to your email.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
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
                  onPressed: sendOTP,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Send OTP",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}