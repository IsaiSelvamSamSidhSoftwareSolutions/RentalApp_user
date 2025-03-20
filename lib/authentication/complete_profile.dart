import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mime/mime.dart';

class CompleteProfileScreen extends StatefulWidget {
  @override
  _CompleteProfileScreenState createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressLine1Controller = TextEditingController();
  final TextEditingController addressLine2Controller = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController additionalRemarksController = TextEditingController();
  final TextEditingController addressTypeController = TextEditingController();
  final TextEditingController addressAliasController = TextEditingController();

  bool termsAccepted = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final GetStorage storage = GetStorage();
  bool isLoading = false;
  bool _isApiCallInProgress = false; // To prevent multiple API calls

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final fileExtension = pickedFile.path.split('.').last.toLowerCase();
        final mimeType = lookupMimeType(pickedFile.path);

        if (fileExtension != 'jpg' && fileExtension != 'jpeg' && mimeType != 'image/jpeg') {
          showSnackbar("Only JPG and JPEG images are allowed!", Colors.red);
          return;
        }

        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      showSnackbar("Failed to pick image!", Colors.red);
    }
  }

  Future<void> completeProfile() async {
    if (_isApiCallInProgress) return; // Prevent multiple API calls
    if (!termsAccepted || _image == null || firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty || phoneController.text.isEmpty ||
        addressLine1Controller.text.isEmpty || cityController.text.isEmpty ||
        stateController.text.isEmpty || countryController.text.isEmpty ||
        pincodeController.text.isEmpty || addressTypeController.text.isEmpty ||
        addressAliasController.text.isEmpty) {
      showSnackbar("Please fill in all required fields!", Colors.red);
      return;
    }

    setState(() {
      isLoading = true;
      _isApiCallInProgress = true;
    });

    final String token = storage.read("jwt") ?? "";
    final url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/auth/user/complete-profile");

    // Debug: Print image details
    print("Image Path: ${_image!.path}");
    print("File Size: ${_image!.lengthSync()} bytes");
    print("MIME Type: ${lookupMimeType(_image!.path)}");

    // Create a multipart request
    var request = http.MultipartRequest("PUT", url)
      ..headers["Authorization"] = "Bearer $token"
      ..fields["firstName"] = firstNameController.text.trim()
      ..fields["lastName"] = lastNameController.text.trim()
      ..fields["phoneNumber"] = phoneController.text.trim()
      ..fields["addresses[0][type]"] = addressTypeController.text.trim()
      ..fields["addresses[0][alias]"] = addressAliasController.text.trim()
      ..fields["addresses[0][addressLine1]"] = addressLine1Controller.text.trim()
      ..fields["addresses[0][addressLine2]"] = addressLine2Controller.text.trim()
      ..fields["addresses[0][city]"] = cityController.text.trim()
      ..fields["addresses[0][state]"] = stateController.text.trim()
      ..fields["addresses[0][country]"] = countryController.text.trim()
      ..fields["addresses[0][pincode]"] = pincodeController.text.trim()
      ..fields["termsAndConditions"] = "true";

    // Add the image file to the request
    if (_image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "avatar", // Key for the file upload
          _image!.path, // File path
        ),
      );
    }

    // Debug: Print request files
    print("Request Files: ${request.files}");

    try {
      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseBody = jsonDecode(responseData);

      setState(() {
        isLoading = false;
        _isApiCallInProgress = false;
      });

      // Debug: Print API response
      print("API Response: $responseBody");

      // Handle the response
      if (response.statusCode == 200 && responseBody["status"] == "success") {
        showSnackbar("Profile completed successfully.", Colors.green);
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        showSnackbar(responseBody["message"] ?? "Profile update failed!", Colors.red);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _isApiCallInProgress = false;
      });
      showSnackbar("An error occurred while completing the profile.", Colors.red);
      print("Error: $e");
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
                  SizedBox(height: 40),
                  Text(
                    "Complete Your Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Fill in the details to complete your profile",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Image Picker
                  GestureDetector(
                    onTap: pickImage,
                    child: _image == null
                        ? CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.camera_alt, size: 30, color: Colors.blue),
                    )
                        : CircleAvatar(radius: 50, backgroundImage: FileImage(_image!)),
                  ),
                  SizedBox(height: 20),

                  // Input Fields
                  _buildTextField(firstNameController, "First Name"),
                  SizedBox(height: 10),
                  _buildTextField(lastNameController, "Last Name"),
                  SizedBox(height: 10),
                  _buildTextField(companyNameController, "Company Name"),
                  SizedBox(height: 10),
                  IntlPhoneField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
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
                    ),
                    initialCountryCode: 'IN',
                  ),
                  SizedBox(height: 10),
                  _buildTextField(addressLine1Controller, "Address Line 1"),
                  SizedBox(height: 10),
                  _buildTextField(addressLine2Controller, "Address Line 2"),
                  SizedBox(height: 10),
                  _buildTextField(cityController, "City"),
                  SizedBox(height: 10),
                  _buildTextField(stateController, "State"),
                  SizedBox(height: 10),
                  _buildTextField(countryController, "Country"),
                  SizedBox(height: 10),
                  _buildTextField(pincodeController, "Pincode", keyboardType: TextInputType.number),
                  SizedBox(height: 10),
                  _buildTextField(addressTypeController, "Address Type"),
                  SizedBox(height: 10),
                  _buildTextField(addressAliasController, "Address Alias"),
                  SizedBox(height: 10),
                  _buildTextField(additionalRemarksController, "Additional Remarks"),
                  SizedBox(height: 20),

                  // Terms and Conditions Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: termsAccepted,
                        onChanged: (value) => setState(() => termsAccepted = value!),
                        activeColor: Colors.blue,
                      ),
                      Text("I agree to the Terms and Conditions"),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Complete Profile Button
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
                      onPressed: completeProfile,
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Complete Profile",
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
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
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
        prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
      ),
      keyboardType: keyboardType,
    );
  }
}