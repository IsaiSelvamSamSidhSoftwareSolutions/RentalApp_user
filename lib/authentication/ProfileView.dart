
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart'; // For location
import 'package:image_picker/image_picker.dart'; // For image picker
import 'dart:io'; // For File type
import 'package:mime/mime.dart'; // Import MIME package
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

  double? latitude;
  double? longitude;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  File? _imageFile; // To store the selected image
  String? _imageError; // To store image validation error

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final mimeType = lookupMimeType(
          pickedFile.path); // Get the actual MIME type

      if (mimeType == 'image/jpeg' || mimeType == 'image/jpg') {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageError = null; // Clear any previous error
        });
      } else {
        setState(() {
          _imageError = "Only JPEG images are allowed.";
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with stored values
    firstNameController =
        TextEditingController(text: storage.read("firstName") ?? "");
    lastNameController =
        TextEditingController(text: storage.read("lastName") ?? "");
    emailController = TextEditingController(text: storage.read("email") ?? "");
    phoneNumberController =
        TextEditingController(text: storage.read("phoneNumber") ?? "");
    addressLine1Controller =
        TextEditingController(text: storage.read("addressLine1") ?? "");
    addressLine2Controller =
        TextEditingController(text: storage.read("addressLine2") ?? "");
    cityController = TextEditingController(text: storage.read("city") ?? "");
    stateController = TextEditingController(text: storage.read("state") ?? "");
    countryController =
        TextEditingController(text: storage.read("country") ?? "");
    pincodeController =
        TextEditingController(text: storage.read("pincode") ?? "");
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      // Check if the selected image is valid
      if (_imageFile != null && !(_imageFile!.path.endsWith('.jpg') ||
          _imageFile!.path.endsWith('.jpeg'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Only .jpg or .jpeg files are allowed for the avatar."),
            backgroundColor: Colors.red,
          ),
        );
        return; // Exit the function if the file type is invalid
      }

      setState(() {
        _isLoading = true;
      });

      final String jwt = storage.read("jwt") ?? "";
      final String url = "https://getsetbuild.samsidh.com/api/v1/auth/user/updateMe";

      // Create a multipart request for image upload
      var request = http.MultipartRequest('PATCH', Uri.parse(url));
      request.headers['Authorization'] = "Bearer $jwt";

      // Add text fields to the request
      request.fields['firstName'] = firstNameController.text;
      request.fields['lastName'] = lastNameController.text;
      request.fields['email'] = emailController.text;
      request.fields['phoneNumber'] = phoneNumberController.text;

      // Construct the addresses field as a JSON object
      final addresses = [
        {
          "alias": "Home",
          "addressLine1": addressLine1Controller.text,
          "addressLine2": addressLine2Controller.text,
          "city": cityController.text,
          "state": stateController.text,
          "country": countryController.text,
          "pincode": pincodeController.text,
          "location": {
            "type": "Point",
            "coordinates": [
              longitude ?? 0.0, // Use 0.0 if longitude is null
              latitude ?? 0.0,  // Use 0.0 if latitude is null
            ],
          },
        },
      ];

      // Add the addresses field as a JSON-encoded string
      request.fields['addresses'] = json.encode(addresses);

      // Add image file to the request if selected
      if (_imageFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('avatar', _imageFile!.path));
      }

      try {
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        print(
            "View Profile API Response: $responseBody"); // Print the API response

        if (response.statusCode == 200) {
          // Update GetStorage with the new values
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

          // Update avatar URL if image was uploaded
          if (_imageFile != null) {
            final responseData = json.decode(responseBody);
            storage.write("avatar", responseData['avatar']);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Profile updated successfully!",
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Print the error response in the console
          print("API Error: $responseBody");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update profile. Please try again.",
                  style: GoogleFonts.poppins()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "An error occurred. Please check your internet connection.",
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  Future<void> _getUserLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Location services are disabled. You can manually enter your address or Allow Location"),
          backgroundColor: Colors.blueGrey,
        ),
      );
      setState(() {
        _isFetchingLocation = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Location permissions are denied. You can manually enter your address."),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isFetchingLocation = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Location permissions are permanently denied. You can manually enter your address."),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _isFetchingLocation = false;
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      _isFetchingLocation = false;
    });

    // Fetch address from API using latitude and longitude
    await _fetchAddressFromAPI(latitude!, longitude!);
  }
  Future<void> _fetchAddressFromAPI(double lat, double lng) async {
    setState(() {
      _isLoading = true;
    });

    final String url =
        "https://getsetbuild.samsidh.com/api/v1/products/location?lat=$lat&lng=$lng";

    try {
      final response = await http.get(Uri.parse(url));
      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        final address = responseBody['data']['address'];
        setState(() {
          addressLine1Controller.text = address['addressLine1'];
          addressLine2Controller.text = address['addressLine2'];
          cityController.text = address['city'];
          stateController.text = address['state'];
          countryController.text = address['country'];
          pincodeController.text = address['pinCode'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch address. Please try again.",
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "An error occurred. Please check your internet connection.",
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "User Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
                childAnimationBuilder: (widget) =>
                    SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                children: [
                  // Image Upload Section
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (storage.read("avatar") != null
                              ? NetworkImage(storage.read("avatar"))
                              : null),
                          child: _imageFile == null &&
                              storage.read("avatar") == null
                              ? Icon(
                              Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Tap to upload profile picture",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (_imageError !=
                          null) // Show error message if file type is invalid
                        Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            _imageError!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildReadOnlyField("Role", storage.read("role") ?? "N/A"),
                  _buildReadOnlyField(
                      "Subscription Status",
                      storage.read("subscription_status") ?? "N/A"),
                  _buildEditableField("First Name", firstNameController),
                  _buildEditableField("Last Name", lastNameController),
                  _buildEditableField("Email", emailController),
                  _buildEditableField("Phone Number", phoneNumberController),
                  _buildEditableFieldWithLocation(
                      "Address Line 1", addressLine1Controller),
                  _buildEditableField("Address Line 2", addressLine2Controller),
                  _buildEditableField("City", cityController),
                  _buildEditableField("State", stateController),
                  _buildEditableField("Country", countryController),
                  _buildEditableField("Pincode", pincodeController),
                  SizedBox(height: 20),
                  _isLoading
                      ? CircularProgressIndicator()
                      : Container(
                    width: double.infinity,
                    // Makes the button take the full width of its parent
                    child: ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: Colors.blue.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Card(
      elevation: 3,
      // Slightly raised for better visibility
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // More rounded corners
      ),
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      // Adds spacing between cards
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        // Balanced padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          // Align text properly
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right, // Align value text to the right
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis, // Prevents overflow issues
                maxLines: 1,
              ),
            ),
          ],
        ),
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
              contentPadding: EdgeInsets.symmetric(
                  vertical: 12, horizontal: 15),
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

  Widget _buildEditableFieldWithLocation(String label,
      TextEditingController controller) {
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 12, horizontal: 15),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "This field is required";
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.location_on, color: Colors.blue.shade900),
                onPressed: _isFetchingLocation ? null : _getUserLocation,
              ),
            ],
          ),
          if (_isFetchingLocation)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}