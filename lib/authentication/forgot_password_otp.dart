import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ResetPasswordScreen.dart';

class ForgotPasswordOTPScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordOTPScreen({Key? key, required this.email}) : super(key: key);

  @override
  _ForgotPasswordOTPScreenState createState() => _ForgotPasswordOTPScreenState();
}

class _ForgotPasswordOTPScreenState extends State<ForgotPasswordOTPScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyOTP() async {
    final String otp = otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      showSnackbar("Please enter a valid 6-digit OTP.", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    final Uri url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/auth/user/verifyEmail");
    final Map<String, String> headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> body = {
      "email": widget.email,
      "otp": otp
    };

    try {
      final response = await http.post(url, headers: headers, body: jsonEncode(body));

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        showSnackbar("Password reset successfully!", Colors.green);
        Future.delayed(Duration(seconds: 2), () {
          Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        String errorMessage = responseBody["message"] ?? "Failed to reset password. Please try again.";

        print("API Response Error: ${response.body}"); // Print full response in console
        showSnackbar(errorMessage, Colors.red);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("API Exception: $e"); // Print detailed error
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
      appBar: AppBar(
        title: Text(
          "Enter OTP",
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
                "Enter OTP",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We sent a 6-digit OTP to ${widget.email}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 40),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: "OTP",
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
                  onPressed: isLoading ? null : verifyOTP,
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Verify OTP",
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
