import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';

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
  final TextEditingController addressTypeController = TextEditingController(); // New controller for address type
  final TextEditingController addressAliasController = TextEditingController(); // New controller for address alias

  bool termsAccepted = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final GetStorage storage = GetStorage();
  bool isLoading = false;
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final fileExtension = pickedFile.path.split('.').last.toLowerCase();
      print("Picked file: ${pickedFile.path}"); // Debugging: print the file path
      print("File extension: $fileExtension"); // Debugging: print the file extension

      if (fileExtension != 'jpg' && fileExtension != 'jpeg') {
        showSnackbar("Only JPG and JPEG images are allowed!", Colors.red);
        return;
      }

      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  Future<void> completeProfile() async {
    if (!termsAccepted || _image == null || firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty || phoneController.text.isEmpty ||
        addressLine1Controller.text.isEmpty || cityController.text.isEmpty ||
        stateController.text.isEmpty || countryController.text.isEmpty ||
        pincodeController.text.isEmpty || addressTypeController.text.isEmpty ||
        addressAliasController.text.isEmpty) {
      showSnackbar("Please fill in all required fields!", Colors.red);
      return;
    }

    setState(() => isLoading = true);
    final String token = storage.read("jwt") ?? "";
    print("Token Complete Profile $token");

    final url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/auth/user/complete-profile");
    var request = http.MultipartRequest("PUT", url)
      ..headers["Authorization"] = "Bearer $token"
      ..fields["firstName"] = firstNameController.text.trim()
      ..fields["lastName"] = lastNameController.text.trim()
      ..fields["companyName"] = companyNameController.text.trim()
      ..fields["phoneNumber"] = phoneController.text.trim()
      ..fields["addresses[0][type]"] = addressTypeController.text.trim() // Get user input for address type
      ..fields["addresses[0][alias]"] = addressAliasController.text.trim() // Get user input for address alias
      ..fields["addresses[0][addressLine1]"] = addressLine1Controller.text.trim()
      ..fields["addresses[0][addressLine2]"] = addressLine2Controller.text.trim()
      ..fields["addresses[0][city]"] = cityController.text.trim()
      ..fields["addresses[0][state]"] = stateController.text.trim()
      ..fields["addresses[0][country]"] = countryController.text.trim()
      ..fields["addresses[0][pincode]"] = pincodeController.text.trim()
      ..fields["additionalRemarks"] = additionalRemarksController.text.trim()
      ..fields["termsAndConditions"] = "true";

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath("avatar", _image!.path));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final responseBody = jsonDecode(responseData);

    setState(() => isLoading = false);

    print("API Response: $responseBody"); // Print API response for debugging

    if (response.statusCode == 200 && responseBody["status"] == "success") {
      showSnackbar("Profile completed successfully.", Colors.green);
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      showSnackbar(responseBody["message"] ?? "Profile update failed!", Colors.red);
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
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(child: Text("Complete Profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 20),

              // Image Picker
              GestureDetector(
                onTap: pickImage,
                child: _image == null
                    ? ZoomIn(child: CircleAvatar(radius: 50, backgroundColor: Colors.grey[300], child: Icon(Icons.camera_alt, size: 30)))
                    : CircleAvatar(radius: 50, backgroundImage: FileImage(_image!)),
              ),
              SizedBox(height: 20),

              // Input Fields
              FadeInLeft(child: TextField(controller: firstNameController, decoration: InputDecoration(labelText: "First Name"))),
              SizedBox(height: 10),
              FadeInRight(child: TextField(controller: lastNameController, decoration: InputDecoration(labelText: "Last Name"))),
              SizedBox(height: 10),
              FadeInLeft(child: TextField(controller: companyNameController, decoration: InputDecoration(labelText: "Company Name"))),
              SizedBox(height: 10),
              FadeInRight(child: TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone Number"))),
              SizedBox(height: 10),
              FadeInLeft(child: TextField(controller: addressLine1Controller, decoration: InputDecoration(labelText: "Address Line 1"))),
              SizedBox(height: 10),
              FadeInRight(child: TextField(controller: addressLine2Controller, decoration: InputDecoration(labelText: "Address Line 2"))),
              SizedBox(height: 10),
              FadeInLeft(child: TextField(controller: cityController, decoration: InputDecoration(labelText: "City"))),
              SizedBox(height: 10),
              FadeInRight(child: TextField(controller: stateController, decoration: InputDecoration(labelText: "State"))),
              SizedBox(height: 10),
              FadeInLeft(child: TextField(controller: countryController, decoration: InputDecoration(labelText: "Country"))),
              SizedBox(height: 10),
              FadeInRight(child: TextField(controller: pincodeController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Pincode"))),
              SizedBox(height: 10),
              FadeInLeft(child: TextField(controller: addressTypeController, decoration: InputDecoration(labelText: "Address Type"))), // New field for address type
              SizedBox(height: 10),
              FadeInRight(child: TextField(controller: addressAliasController, decoration: InputDecoration(labelText: "Address Alias"))), // New field for address alias
              SizedBox(height: 10),
              FadeInLeft(child: TextField(controller: additionalRemarksController, decoration: InputDecoration(labelText: "Additional Remarks"))), // New field for additional remarks
              SizedBox(height: 20),

              // Terms and Conditions Checkbox
              FadeInUp(
                child: Row(
                  children: [
                    Checkbox(value: termsAccepted, onChanged: (value) => setState(() => termsAccepted = value!)),
                    Expanded(child: Text("I agree to the Terms and Conditions")),
                  ],
                ),
              ),

              SizedBox(height: 20),

              isLoading
                  ? Bounce(child: CircularProgressIndicator())
                  : FadeInUp(
                child: ElevatedButton(
                  onPressed: completeProfile,
                  child: Text("Complete Profile"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}