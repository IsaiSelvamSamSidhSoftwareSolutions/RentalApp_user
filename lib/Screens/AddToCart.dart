//
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:get_storage/get_storage.dart';
//
// class AddToCartScreen extends StatefulWidget {
//   final String productId;
//   final String productName;
//   final String productCondition;
//   final String productDescription;
//   final String vendorName;
//   final String vendorLocation;
//   final String productImage;
//   final double priceHourly;
//   final double priceDaily;
//   final List<String> availableDays;
//   final int quantity;
//   final String selectedPriceType;
//   final int numberOfDays;
//   final DateTime? selectedStartDate;
//   final DateTime? selectedEndDate;
//   final List<Map<String, dynamic>> additionalFields;
//   final List<Map<String, dynamic>> additionalAttachments; // Add this
//   final List<Map<String, dynamic>> additionalServices; // Add this
//   AddToCartScreen({
//     required this.productId,
//     required this.productName,
//     required this.productCondition,
//     required this.productDescription,
//     required this.vendorName,
//     required this.vendorLocation,
//     required this.productImage,
//     required this.priceHourly,
//     required this.priceDaily,
//     required this.availableDays,
//     required this.additionalFields,
//     required this.quantity,
//     required this.selectedPriceType,
//     required this.numberOfDays,
//     required this.selectedStartDate,
//     required this.selectedEndDate,
//     required this.additionalAttachments,
//     required this.additionalServices, // Add this
//   });
//
//   @override
//   _AddToCartScreenState createState() => _AddToCartScreenState();
// }
//
// class _AddToCartScreenState extends State<AddToCartScreen>
//     with SingleTickerProviderStateMixin {
//   final String baseUrl = "https://getsetbuild.samsidh.com/";
//   final GetStorage storage = GetStorage();
//   bool isLoading = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize animation controller
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(seconds: 2), // Total animation duration
//     );
//
//     // Fade animation for text elements
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeIn,
//       ),
//     );
//
//     // Start the animation
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double price = widget.selectedPriceType == "hourly"
//         ? widget.priceHourly
//         : widget.priceDaily;
//
//     return Scaffold(
//       backgroundColor: Colors.white, // White background
//       appBar: AppBar(
//         title: Text(
//           "Add to Cart - ${widget.productName}",
//           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.white,
//         iconTheme: IconThemeData(color: Colors.black),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Hero Animation for Product Image
//             Hero(
//               tag: 'product-image-${widget.productId}',
//               child: Card(
//                 elevation: 5,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(15),
//                   child: Image.network(
//                     widget.productImage,
//                     height: 200,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 20),
//             // Staggered Fade-In Animations for Text Elements
//             FadeTransition(
//               opacity: _fadeAnimation,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildAnimatedText(
//                     "Condition: ${widget.productCondition}",
//                     delay: 0.2,
//                   ),
//                   SizedBox(height: 10),
//                   _buildAnimatedText(
//                     "Vendor: ${widget.vendorName}",
//                     delay: 0.4,
//                   ),
//                   SizedBox(height: 10),
//                   _buildAnimatedText(
//                     "Location: ${widget.vendorLocation}",
//                     delay: 0.6,
//                   ),
//                   SizedBox(height: 10),
//                   _buildAnimatedText(
//                     "Price: ₹$price / ${widget.selectedPriceType}",
//                     delay: 0.8,
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       color: Colors.green,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 20),
//                   _buildAnimatedText(
//                     "Start Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedStartDate!)}",
//                     delay: 1.0,
//                   ),
//                   SizedBox(height: 10),
//                   _buildAnimatedText(
//                     "End Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedEndDate!)}",
//                     delay: 1.2,
//                   ),
//                   SizedBox(height: 20),
//                   _buildAnimatedText(
//                     "Total Price: ₹${(price * widget.quantity * widget.numberOfDays).toStringAsFixed(2)}",
//                     delay: 1.4,
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       color: Colors.green,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 20),
//             // Add to Cart Button
//             ScaleTransition(
//               scale: Tween<double>(begin: 1.0, end: 0.95).animate(
//                 CurvedAnimation(
//                   parent: _animationController,
//                   curve: Interval(1.6, 2.0, curve: Curves.easeInOut),
//                 ),
//               ),
//               child: ElevatedButton(
//                 onPressed: _confirmAddToCart,
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white, backgroundColor: Colors.blue,
//                   padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 child: Text(
//                   "Add to Cart",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper method to build animated text
//   Widget _buildAnimatedText(String text, {double delay = 0.0, TextStyle? style}) {
//     return FadeTransition(
//       opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
//         CurvedAnimation(
//           parent: _animationController,
//           curve: Interval(delay, delay + 0.2, curve: Curves.easeIn),
//         ),
//       ),
//       child: Text(
//         text,
//         style: style ?? GoogleFonts.poppins(fontSize: 16),
//       ),
//     );
//   }
//
//   void _confirmAddToCart() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Confirm Add to Cart"),
//           content: Text("Are you sure you want to add this product to your cart?"),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _addToCart();
//               },
//               child: Text("Add to Cart"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.check_circle,
//                 color: Colors.green,
//                 size: 60,
//               ),
//               SizedBox(height: 20),
//               Text(
//                 "Added Successfully!",
//                 style: GoogleFonts.poppins(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 "Your product has been added to the cart.",
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   color: Colors.grey.shade600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(); // Close the dialog
//                   Navigator.of(context).pop(); // Navigate back to the previous screen
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 child: Text(
//                   "OK",
//                   style: GoogleFonts.poppins(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//   Future<void> _addToCart() async {
//     setState(() => isLoading = true);
//
//     try {
//       final String token = storage.read("jwt") ?? "";
//       if (token.isEmpty) {
//         showSnackbar("Please log in to add items to the cart", Colors.red);
//         return;
//       }
//
//       // Construct the request body
//       final Map<String, dynamic> requestBody = {
//         "productId": widget.productId,
//         "prompt": true, // Set to true if additional prompts are required
//         "quantity": widget.quantity,
//         "bookingDates": {
//           "from": DateFormat('yyyy-MM-dd').format(widget.selectedStartDate!),
//           "to": DateFormat('yyyy-MM-dd').format(widget.selectedEndDate!),
//         },
//         "priceType": {
//           "type": widget.selectedPriceType, // "hourly" or "daily"
//           "price": widget.selectedPriceType == "hourly"
//               ? widget.priceHourly
//               : widget.priceDaily,
//         },
//         "additionalAttachments": widget.additionalAttachments, // Pass additional attachments
//         "additionalServices": widget.additionalServices, // Pass additional services
//       };
//
//       // Make the API call
//       final Uri url = Uri.parse("$baseUrl/api/v1/cart");
//       final response = await http.post(
//         url,
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode(requestBody),
//       );
//
//       setState(() => isLoading = false);
//
//       if (response.statusCode == 200) {
//         final responseBody = jsonDecode(response.body);
//         if (responseBody["status"] == "success") {
//           // Show modern UI alert for success
//           _showSuccessDialog();
//         } else {
//           showSnackbar(responseBody["message"] ?? "Failed to add product to cart", Colors.red);
//         }
//       } else {
//         showSnackbar("Failed to add product to cart: ${response.statusCode}", Colors.red);
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//       showSnackbar("An error occurred: $e", Colors.red);
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class AddToCartScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String productCondition;
  final String productDescription;
  final String vendorName;
  final String vendorLocation;
  final String productImage;
  final double priceHourly;
  final double priceDaily;
  final List<String> availableDays;
  final int quantity;
  final String selectedPriceType;
  final int numberOfDays;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;
  final List<Map<String, dynamic>> additionalFields;
  final List<Map<String, dynamic>> additionalAttachments;
  final List<Map<String, dynamic>> additionalServices;

  AddToCartScreen({
    required this.productId,
    required this.productName,
    required this.productCondition,
    required this.productDescription,
    required this.vendorName,
    required this.vendorLocation,
    required this.productImage,
    required this.priceHourly,
    required this.priceDaily,
    required this.availableDays,
    required this.additionalFields,
    required this.quantity,
    required this.selectedPriceType,
    required this.numberOfDays,
    required this.selectedStartDate,
    required this.selectedEndDate,
    required this.additionalAttachments,
    required this.additionalServices,
  });

  @override
  _AddToCartScreenState createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen>
    with SingleTickerProviderStateMixin {
  final String baseUrl = "https://getsetbuild.samsidh.com/";
  final GetStorage storage = GetStorage(); // Initialize GetStorage
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int cartItemCount = 0; // Declare cartItemCount here
  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    // Fade animation for text elements
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double price = widget.selectedPriceType == "hourly"
        ? widget.priceHourly
        : widget.priceDaily;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Add to Cart - ${widget.productName}",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Animation for Product Image
            Hero(
              tag: 'product-image-${widget.productId}',
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    widget.productImage,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Staggered Fade-In Animations for Text Elements
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedText(
                    "Condition: ${widget.productCondition}",
                    delay: 0.2,
                  ),
                  SizedBox(height: 10),
                  _buildAnimatedText(
                    "Vendor: ${widget.vendorName}",
                    delay: 0.4,
                  ),
                  SizedBox(height: 10),
                  _buildAnimatedText(
                    "Location: ${widget.vendorLocation}",
                    delay: 0.6,
                  ),
                  SizedBox(height: 10),
                  _buildAnimatedText(
                    "Price: ₹$price / ${widget.selectedPriceType}",
                    delay: 0.8,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildAnimatedText(
                    "Start Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedStartDate!)}",
                    delay: 1.0,
                  ),
                  SizedBox(height: 10),
                  _buildAnimatedText(
                    "End Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedEndDate!)}",
                    delay: 1.2,
                  ),
                  SizedBox(height: 20),
                  _buildAnimatedText(
                    "Total Price: ₹${(price * widget.quantity * widget.numberOfDays).toStringAsFixed(2)}",
                    delay: 1.4,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Display Additional Attachments
                  if (widget.additionalAttachments.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          "Additional Attachments:",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...widget.additionalAttachments.map((attachment) {
                          return ListTile(
                            leading: Image.network(
                              attachment["attachementImage"],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(attachment["attachmentName"]),
                            subtitle: Text("Price: ₹${attachment["price"]}"),
                          );
                        }).toList(),
                      ],
                    ),
                  // Display Additional Services
                  if (widget.additionalServices.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text(
                          "Additional Services:",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...widget.additionalServices.map((service) {
                          return ListTile(
                            leading: Icon(Icons.miscellaneous_services),
                            title: Text(service["serviceType"]),
                            subtitle: Text("Price: ₹${service["price"]}"),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Add to Cart Button
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(1.6, 2.0, curve: Curves.easeInOut),
                ),
              ),
              child: ElevatedButton(
                onPressed: _confirmAddToCart,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Add to Cart",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build animated text
  Widget _buildAnimatedText(String text, {double delay = 0.0, TextStyle? style}) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, delay + 0.2, curve: Curves.easeIn),
        ),
      ),
      child: Text(
        text,
        style: style ?? GoogleFonts.poppins(fontSize: 16),
      ),
    );
  }

  void _confirmAddToCart() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Add to Cart"),
          content: Text("Are you sure you want to add this product to your cart?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addToCart();
              },
              child: Text("Add to Cart"),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                "Added Successfully!",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Your product has been added to the cart.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Navigate back to the previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "OK",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _addToCart() async {
    setState(() => isLoading = true);

    try {
      // Retrieve JWT token from GetStorage
      final String token = storage.read("jwt") ?? "";

      // Validate token
      if (token.isEmpty) {
        showSnackbar("Please log in to add items to the cart", Colors.red);
        setState(() => isLoading = false); // Reset loading state
        return;
      }

      // Construct the request body
      final Map<String, dynamic> requestBody = {
        "productId": widget.productId,
        "prompt": true, // Set to true if additional prompts are required
        "quantity": widget.quantity,
        "bookingDates": {
          "from": DateFormat('yyyy-MM-dd').format(widget.selectedStartDate!),
          "to": DateFormat('yyyy-MM-dd').format(widget.selectedEndDate!),
        },
        "priceType": {
          "type": widget.selectedPriceType, // "hourly" or "daily"
          "price": widget.selectedPriceType == "hourly"
              ? widget.priceHourly
              : widget.priceDaily,
        },
        "additionalAttachments": widget.additionalAttachments, // Pass additional attachments
        "additionalServices": widget.additionalServices, // Pass additional services
      };

      // Make the API call
      final Uri url = Uri.parse("$baseUrl/api/v1/cart");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token", // Include JWT token in headers
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      // Update cart item count in GetStorage
      int currentCount = storage.read("cartItemCount") ?? 0;
      storage.write("cartItemCount", currentCount + 1);

      // Update UI state
      setState(() {
        isLoading = false;
        cartItemCount = storage.read("cartItemCount") ?? 0;
      });

      // Handle API response
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody["status"] == "success") {
          // Show modern UI alert for success
          _showSuccessDialog();
        } else {
          showSnackbar(responseBody["message"] ?? "Failed to add product to cart", Colors.green);
        }
      } else {
        showSnackbar("Failed to add product to cart: ${response.statusCode}", Colors.greenAccent);
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
}