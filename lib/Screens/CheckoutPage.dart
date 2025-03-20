import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'CartListScreen.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final double totalPrice;
  final Map<String, String> bufferDates;

  CheckoutPage({required this.products, required this.totalPrice, required this.bufferDates});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final GetStorage storage = GetStorage();
  final _formKey = GlobalKey<FormState>();
  late Razorpay _razorpay;
  bool _isLoading = false;

  // Controllers for shipping address
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();
  final TextEditingController _additionalRemarksController = TextEditingController();

  // Billing address same as shipping
  bool _billingSameAsShipping = true;

  @override
  void initState() {
    super.initState();
    // Load stored data first
    _firstNameController.text = storage.read("firstName") ?? "";
    _lastNameController.text = storage.read("lastName") ?? "";
    _emailController.text = storage.read("email") ?? "";
    _phoneNumberController.text = storage.read("phoneNumber") ?? "";
    print("Products being sent: ${widget.products}");
    print("Products in CheckoutPage: ${widget.products}");
// Print the loaded data
    print("First Name: ${_firstNameController.text}");
    print("Last Name: ${_lastNameController.text}");
    print("Email: ${_emailController.text}");
    print("Phone Number: ${_phoneNumberController.text}");

    _fetchAddresses(); // Then fetch API data (but avoid overriding existing values)

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }


  @override
  void dispose() {
    _razorpay.clear(); // Clear listeners
    super.dispose();
  }


  Future<void> _createBooking() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      final String token = storage.read("jwt") ?? "";

      // Prepare the products list with all required fields
      List<Map<String, dynamic>> bookingProducts = widget.products.map((product) {
        return {
          "productId": product["productId"],
          "productName": product["productName"] ?? "", // Ensure productName is included
          "productImage": product["productImage"] ?? "", // Ensure productImage is included
          "vendorId": product["vendorId"] ?? "", // Ensure vendorId is included
          "quantity": product["quantity"],
          "priceType": {
            "type": product["priceType"]["type"] ?? "daily", // Ensure priceType is included
            "price": product["priceType"]["price"] ?? 0, // Ensure price is included
          },
          "bookingDates": {
            "from": product["bookingDates"]["from"],
            "to": product["bookingDates"]["to"],
          },
          "bufferDates": {
            "from": widget.bufferDates["from"],
            "to": widget.bufferDates["to"],
          },
          "additionalAttachments": product["additionalAttachments"] != null
              ? product["additionalAttachments"].map((attachment) {
            return {
              "attachmentName": attachment["attachmentName"] ?? "",
              "attachementDescription": attachment["attachementDescription"] ?? "",
              "price": attachment["price"] ?? 0,
              "attachementImage": attachment["attachementImage"] ?? "",
            };
          }).toList()
              : [],
          "additionalServices": product["additionalServices"] != null
              ? product["additionalServices"].map((service) {
            return {
              "serviceType": service["serviceType"] ?? "",
              "price": service["price"] ?? 0,
            };
          }).toList()
              : [],
        };
      }).toList();

      // Prepare the request body
      final Map<String, dynamic> requestBody = {
        "products": bookingProducts,
        "shippingAddress": {
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "companyName": _companyNameController.text,
          "phoneNumber": _phoneNumberController.text,
          "emailId": _emailController.text,
          "address": _addressController.text,
          "addressLine2": _addressLine2Controller.text,
          "city": _cityController.text,
          "state": _stateController.text,
          "pinCode": _pinCodeController.text,
        },
        "billingAddress": _billingSameAsShipping
            ? {
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "companyName": _companyNameController.text,
          "phoneNumber": _phoneNumberController.text,
          "emailId": _emailController.text,
          "address": _addressController.text,
          "addressLine2": _addressLine2Controller.text,
          "city": _cityController.text,
          "state": _stateController.text,
          "pinCode": _pinCodeController.text,
        }
            : {
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "companyName": _companyNameController.text,
          "phoneNumber": _phoneNumberController.text,
          "emailId": _emailController.text,
          "address": _addressController.text,
          "addressLine2": _addressLine2Controller.text,
          "city": _cityController.text,
          "state": _stateController.text,
          "pinCode": _pinCodeController.text,
        },
        "gst": 18, // Static value for GST
        "platformCharges": 2, // Static value for platform charges
      };

      // Debug logs to check the request body
      print("Request Body: ${jsonEncode(requestBody)}");

      final Uri url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/booking/create");

      try {
        final response = await http.post(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        );

        // Print the API response status code and body for debugging
        print("API Response Booking Status Code: ${response.statusCode}");
        print("API Response Booking Body: ${response.body}");

        if (response.statusCode == 200) {
          // Booking created successfully, extract razorpayOrderId
          final responseBody = jsonDecode(response.body);
          final String razorpayOrderId = responseBody["razorpayOrder"]["id"];
          print("Response Body of Create Booking $responseBody");
          // Proceed to payment with razorpayOrderId
          _openRazorpay(razorpayOrderId);
        }
        else if (response.statusCode == 400) {
          final responseBody = jsonDecode(response.body);
          if (responseBody["message"].contains("Dates unavailable")) {
            // Extract unavailable dates from the error message
            final String errorMessage = responseBody["message"];
            final RegExp dateRegex = RegExp(r"\d{4}-\d{2}-\d{2}");
            final Iterable<Match> matches = dateRegex.allMatches(errorMessage);
            final List<String> unavailableDates = matches.map((match) => match.group(0)!).toList();

            // Show user-friendly message with unavailable dates
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Selected dates are unavailable. Unavailable dates: ${unavailableDates.join(", ")}",
                ),
              ),
            );
          } else {
            throw Exception("Failed to create booking: ${response.statusCode}");
          }
        }
        else if (response.statusCode == 400) {
          final responseBody = jsonDecode(response.body);
          if (responseBody["message"].contains("Dates unavailable")) {
            // Show user-friendly message for unavailable dates
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Selected dates are unavailable. Please choose different dates.")),
            );
          } else {
            throw Exception("Failed to create booking: ${response.statusCode}");
          }
        }
        else if (response.statusCode == 500) {
          final responseBody = jsonDecode(response.body);
          if (responseBody["message"].contains("transaction number")) {
            // Handle transaction mismatch error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("A server error occurred. Please try again later."),
              ),
            );
            // Log the error for debugging
            print("Server Error: ${responseBody["message"]}");
          } else {
            throw Exception("Failed to create booking: ${response.statusCode}");
          }
        }

        else if (response.statusCode == 500) {
          final responseBody = jsonDecode(response.body);
          if (responseBody["message"] == "Price is updated for the selected PriceType, please update the product in cart") {
            // Update the cart with the new price
            await _updateCart();
          } else {
            throw Exception("Failed to create booking: ${response.statusCode}");
          }
        } else {
          throw Exception("Failed to create booking: ${response.statusCode}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating booking: $e")),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }
  void _openRazorpay(String razorpayOrderId) {
    var options = {
      'key': 'rzp_test_fxRDm53DIm5TMs', // Replace with your Razorpay key
      'amount': (widget.totalPrice * 100).toInt(), // Amount in paise
      'name': 'Rental_App_Samsidh',
      'description': 'Payment for Order',
      'order_id': razorpayOrderId, // Pass the razorpayOrderId here
      'prefill': {
        'contact': _phoneNumberController.text,
        'email': _emailController.text,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Show a snackbar for immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
    );

    // Call the API to verify payment
    _verifyPayment(response.paymentId, response.orderId, response.signature);
  }

  Future<void> _verifyPayment(String? paymentId, String? razorpayOrderId, String? razorpaySignature) async {
    // Print the arguments being passed
    print("Verifying payment with the following parameters:");
    print("Payment ID: $paymentId");
    print("Razorpay Order ID: $razorpayOrderId");
    print("Razorpay Signature: $razorpaySignature");

    // Check for null values
    if (paymentId == null || razorpayOrderId == null || razorpaySignature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment verification failed: Missing parameters")),
      );
      return; // Exit the method if any parameter is null
    }

    final String token = storage.read("jwt") ?? "";
    final Uri url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/booking/verify-payment");

    final Map<String, dynamic> requestBody = {
      "paymentId": paymentId,
      "razorpayOrderId": razorpayOrderId,
      "razorpaySignature": razorpaySignature,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      // Print the response status code and body for debugging
      print("Response status: ${response.statusCode}");
      print("Response checkout body: ${response.body}");

      if (response.statusCode == 201) {
        // Payment verification successful
        print("Response Body of Create Booking $response");
        _showSuccessDialog();
      }
      else if (response.statusCode == 400) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Booking dates already taken"),
            content: Text("The selected dates are unavailable. Please choose different dates or products "),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
      else {
        // Handle error response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment verification failed: ${response.body}")),
        );
      }
    } catch (e) {
      // Print the error for debugging
      print("Error verifying payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error verifying payment: $e")),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Successful"),
          content: Text("Your payment has been verified successfully!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  Future<void> _updateCart() async {
    final String token = storage.read("jwt") ?? "";
    final Uri url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/cart");

    try {
      for (var product in widget.products) {
        final Map<String, dynamic> requestBody = {
          "productId": product["productId"],
          "prompt": true,
          "quantity": product["quantity"],
          "bookingDates": widget.bufferDates,
          "priceType": product["priceType"],
          "additionalAttachments": product["additionalAttachments"],
          "additionalServices": product["additionalServices"],
        };

        final response = await http.post(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode != 200) {
          throw Exception("Failed to update cart: ${response.statusCode}");
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating cart: $e")),
      );
    }
  }

  void _viewCart() {
    // Navigate to the cart page without disposing the current state
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartListScreen(), // Replace with your cart screen
      ),
    );
  }
  Future<void> _fetchAddresses() async {
    final String token = storage.read("jwt") ?? "";
    final Uri url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/users/addresses");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']['addresses'].isNotEmpty) {
          final address = data['data']['addresses'][0];

          // Update UI but only if fields are empty
          setState(() {
            if (_addressController.text.isEmpty) _addressController.text = address['addressLine1'] ?? "";
            if (_addressLine2Controller.text.isEmpty) _addressLine2Controller.text = address['addressLine2'] ?? "";
            if (_cityController.text.isEmpty) _cityController.text = address['city'] ?? "";
            if (_stateController.text.isEmpty) _stateController.text = address['state'] ?? "";
            if (_pinCodeController.text.isEmpty) _pinCodeController.text = address['pincode'] ?? "";
          });
        }
      } else {
        throw Exception("Failed to fetch addresses: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching addresses: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Checkout", style: GoogleFonts.poppins()),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 4,
                ),
                SizedBox(height: 20),
                Text(
                  "Tightly hold, we are almost done!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Payment initiation is in process.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Thanks for waiting.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Shipping Address", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              _buildTextField(_firstNameController, "First Name *"),
              _buildTextField(_lastNameController, "Last Name *"),
              _buildTextField(_companyNameController, "Company Name"),
              _buildTextField(_phoneNumberController, "Phone Number *"),
              _buildTextField(_emailController, "Email *"),
              _buildTextField(_addressController, "Address *"),
              _buildTextField(_addressLine2Controller, "Address Line 2"),
              _buildTextField(_cityController, "City / Town *"),
              _buildTextField(_stateController, "State *"),
              _buildTextField(_pinCodeController, "Pincode *"),
              _buildTextField(_additionalRemarksController, "Additional Remarks(For Office Construction) *"),
              SizedBox(height: 20),
              CheckboxListTile(
                title: Text("Billing address same as shipping", style: GoogleFonts.poppins()),
                value: _billingSameAsShipping,
                onChanged: (value) {
                  setState(() {
                    _billingSameAsShipping = value ?? true;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createBooking, // Call _createBooking() instead of _openRazorpay()
                child: Text("Proceed to Payment", style: GoogleFonts.poppins(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _viewCart,
                child: Text("View Cart", style: GoogleFonts.poppins()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter your $label";
          }
          return null;
        },
      ),
    );
  }
}