import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final GetStorage storage = GetStorage();
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneNumberController;
  late TextEditingController addressLine1Controller;
  late TextEditingController addressLine2Controller;
  late TextEditingController cityController;
  late TextEditingController stateController;
  late TextEditingController countryController;
  late TextEditingController pincodeController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with stored values
    firstNameController = TextEditingController(text: storage.read("firstName") ?? "");
    lastNameController = TextEditingController(text: storage.read("lastName") ?? "");
    emailController = TextEditingController(text: storage.read("email") ?? "");
    phoneNumberController = TextEditingController(text: storage.read("phoneNumber") ?? "");
    addressLine1Controller = TextEditingController(text: storage.read("addressLine1") ?? "");
    addressLine2Controller = TextEditingController(text: storage.read("addressLine2") ?? "");
    cityController = TextEditingController(text: storage.read("city") ?? "");
    stateController = TextEditingController(text: storage.read("state") ?? "");
    countryController = TextEditingController(text: storage.read("country") ?? "");
    pincodeController = TextEditingController(text: storage.read("pincode") ?? "");
  }

  void _updateProfile() {
    if (_formKey.currentState!.validate()) {
      // Save updated values to GetStorage
      storage.write("firstName", firstNameController.text);
      storage.write("lastName", lastNameController.text);
      storage.write("email", emailController.text);
      storage.write("phoneNumber", phoneNumberController.text);
      storage.write("addressLine1", addressLine1Controller.text);
      storage.write("addressLine2", addressLine2Controller.text);
      storage.write("city", cityController.text);
      storage.write("state", stateController.text);
      storage.write("country", countryController.text);
      storage.write("pincode", pincodeController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile updated successfully!", style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "User Profile",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: Duration(milliseconds: 500),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildAvatar(),
                  SizedBox(height: 20),
                  _buildReadOnlyField("Role", storage.read("role") ?? "N/A"),
                  _buildReadOnlyField("Subscription Status", storage.read("subscription_status") ?? "N/A"),
                  _buildEditableField("First Name", firstNameController),
                  _buildEditableField("Last Name", lastNameController),
                  _buildEditableField("Email", emailController),
                  _buildEditableField("Phone Number", phoneNumberController),
                  _buildEditableField("Address Line 1", addressLine1Controller),
                  _buildEditableField("Address Line 2", addressLine2Controller),
                  _buildEditableField("City", cityController),
                  _buildEditableField("State", stateController),
                  _buildEditableField("Country", countryController),
                  _buildEditableField("Pincode", pincodeController),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Update Profile",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildAvatar() {
    final String avatarUrl = storage.read("avatar") ?? "";
    return CircleAvatar(
      radius: 50,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty ? Icon(Icons.person, size: 50, color: Colors.white) : null,
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 5),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "This field is required";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}