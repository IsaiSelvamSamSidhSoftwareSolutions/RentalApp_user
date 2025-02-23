import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vendor_app_user/authentication/signup.dart';
class OtpVerificationScreen extends StatefulWidget {
  final String email; // ✅ Get email from SignupScreen

  const OtpVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool isLoading = false;
  List<String> otp = List.filled(6, ""); // List to store each OTP digit
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  final List<TextEditingController> controllers = List.generate(6, (index) => TextEditingController());

  Future<void> verifyOtp() async {
    final String enteredOtp = otp.join(); // Combine OTP digits into a single string

    if (enteredOtp.length != 6) {
      showSnackbar("Please enter a valid 6-digit OTP.", Colors.red);
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/auth/user/verifyEmail");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": widget.email, "otp": enteredOtp}), // ✅ Using email from constructor
    );

    setState(() => isLoading = false);

    // ✅ Print API response in the console for debugging
    print("API Status Code: ${response.statusCode}");
    print("API Response Body: ${response.body}");

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      showSnackbar("Thanks! OTP Verified", Colors.green);

      // Navigate to Complete Profile
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/complete_profile');
      });
    } else {
      showSnackbar(responseBody["message"] ?? "OTP is invalid or has expired", Colors.red);
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

  void _onOtpDigitChange(String value, int index) {
    setState(() {
      otp[index] = value;
    });

    // Move focus to the next box if a digit is entered
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(focusNodes[index + 1]);
    }

    // Move focus to the previous box if a digit is deleted
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(focusNodes[index - 1]);
    }
  }

  @override
  void dispose() {
    for (var node in focusNodes) {
      node.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
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
                    "Verify OTP",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Enter the OTP sent to ${widget.email}", // ✅ Display email from constructor
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                          (index) => Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: controllers[index],
                          focusNode: focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            border: InputBorder.none,
                          ),
                          onChanged: (value) => _onOtpDigitChange(value, index),
                        ),
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
                      onPressed: verifyOtp,
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
                  SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                      child: Text(
                        "Didn't receive OTP? Resend",
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
