
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool isLoading = true;
  List<dynamic> bookings = [];
  final GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();
    fetchOrderHistory();
  }

  Future<void> fetchOrderHistory() async {
    final String token = storage.read("jwt") ?? "";
    final Uri url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/booking/user");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      print("API Response: ${response.body}");
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);

        setState(() {
          bookings = data["bookings"];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load order history: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle error (e.g., show a snackbar or dialog)
    }
  }
  void _showBookingDetails(dynamic booking) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking Details",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.blueAccent, // Change to your preferred color
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Text("Order ID: ${booking["_id"]}", style: GoogleFonts.poppins(fontSize: 16)),
                  SizedBox(height: 8),
                  Text("Status: ${booking["status"]}", style: GoogleFonts.poppins(fontSize: 16)),
                  SizedBox(height: 8),
                  Text("Created At: ${booking["createdAt"]}", style: GoogleFonts.poppins(fontSize: 14)),
                  SizedBox(height: 16),
                  Text("Billing Address:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  Text("${booking["billingAddress"]["firstName"]} ${booking["billingAddress"]["lastName"]}", style: GoogleFonts.poppins()),
                  Text("${booking["billingAddress"]["address"]}", style: GoogleFonts.poppins()),
                  Text("${booking["billingAddress"]["city"]}, ${booking["billingAddress"]["state"]} - ${booking["billingAddress"]["pinCode"]}", style: GoogleFonts.poppins()),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text("Phone: ${booking["billingAddress"]["phoneNumber"]}", style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text("Email: ${booking["billingAddress"]["emailId"]}", style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text("Vendor Details:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  for (var product in booking["products"])
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Vendor Email: ${product["vendorId"]["email"]}", style: GoogleFonts.poppins()),
                            SizedBox(height: 8),
                            Text("Product Details:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            Text("Booking Dates: ${product["bookingDates"]["from"]} to ${product["bookingDates"]["to"]}", style: GoogleFonts.poppins()),
                            Text("Quantity: ${product["quantity"]}", style: GoogleFonts.poppins()),
                            Text("Total: ₹${product["total"]}", style: GoogleFonts.poppins()),
                            SizedBox(height: 8),
                            if (product["additionalFields"] != null && product["additionalFields"].isNotEmpty)
                              Text("Additional Fields:", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            if (product["additionalFields"] != null)
                              for (var field in product["additionalFields"])
                                Text("${field["fieldName"]}: ₹${field["price"]} (Qty: ${field["quantity"]})", style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.blueAccent, // Text color
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Close", style: GoogleFonts.poppins()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 5, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: EdgeInsets.all(10),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order History", style: GoogleFonts.poppins()),
      ),
      body: isLoading
          ? _buildShimmerEffect() // Show shimmer effect while loading
          : bookings.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              "No Orders Found",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            margin: EdgeInsets.all(10),
            elevation: 5,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order ID: ${booking["_id"]}",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Total Price: ₹${booking["totalPrice"]}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Status: ${booking["status"]}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Created At: ${booking["createdAt"]}",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Shipping Address:",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${booking["shippingAddress"]["address"]}, ${booking["shippingAddress"]["city"]}, ${booking["shippingAddress"]["state"]}, ${booking["shippingAddress"]["pinCode"]}",
                    style: GoogleFonts.poppins(),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showBookingDetails(booking);
                    },
                    child: Text(
                      "View Details",
                      style: GoogleFonts.poppins(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}