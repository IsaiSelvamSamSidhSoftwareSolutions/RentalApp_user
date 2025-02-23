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
  final List<Map<String, dynamic>> additionalFields;
  final int quantity;
  final String selectedPriceType;
  final int numberOfDays;
  final DateTime? selectedStartDate;
  final DateTime? selectedEndDate;

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
  });

  @override
  _AddToCartScreenState createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  final String baseUrl = "https://getsetbuild.samsidh.com/";
  final GetStorage storage = GetStorage();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

  }



  Future<void> _addToCart() async {
    final String token = storage.read("jwt") ?? "";
    print("ADD TO CART TOKEN $token");

    setState(() {
      isLoading = true; // Show loading indicator
    });

     final url = Uri.parse('$baseUrl/api/v1/cart/${widget.productId}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      "prompt":true,
      "productId": widget.productId,
      "quantity": widget.quantity,
      "bookingDates": {
        "from": DateFormat('yyyy-MM-dd').format(widget.selectedStartDate!),
        "to": DateFormat('yyyy-MM-dd').format(widget.selectedEndDate!),
      },
      "priceType": {
        "type": widget.selectedPriceType,
        "price": widget.selectedPriceType == "hourly"
            ? widget.priceHourly
            : widget.priceDaily,
      },
      "additionalFields": widget.additionalFields.map((field) => {
        "fieldName": field["fieldName"],
        "price": field["price"],
        "quantity": field["quantity"],
      }).toList(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      print("API Response: ${response.body}"); // Debugging: Print API response

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added to cart successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 401) {
        _showLoginError(); // Handle unauthorized error
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add to cart: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  void _showLoginError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("You are not logged in! Please log in to continue."),
        backgroundColor: Colors.red,
      ),
    );
    // Optionally, navigate to the login screen
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
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
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _addToCart(); // Proceed to add to cart
              },
              child: Text("Add to Cart"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double price = widget.selectedPriceType == "hourly"
        ? widget.priceHourly
        : widget.priceDaily;

    return Scaffold(
      appBar: AppBar(title: Text("Add to Cart - ${widget.productName}")),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                widget.productImage,
                height: 200,
              ),
            ),
            SizedBox(height: 20),
            Text("Condition: ${widget.productCondition}",
                style: GoogleFonts.poppins(fontSize: 16)),
            Text("Vendor: ${widget.vendorName}",
                style: GoogleFonts.poppins(fontSize: 16)),
            Text("Location: ${widget.vendorLocation}",
                style: GoogleFonts.poppins(fontSize: 16)),
            Text("Price: ₹$price / ${widget.selectedPriceType}",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.green)),
            SizedBox(height: 20),
            Text("Start Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedStartDate!)}",
                style: GoogleFonts.poppins(fontSize: 16)),
            Text("End Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedEndDate!)}",
                style: GoogleFonts.poppins(fontSize: 16)),
            SizedBox(height: 20),
            Text("Total Price: ₹${(price * widget.quantity * widget.numberOfDays).toStringAsFixed(2)}",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.green)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _confirmAddToCart,
              child: Text("Add to Cart", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}