
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
class CartListScreen extends StatefulWidget {
  @override
  _CartListScreenState createState() => _CartListScreenState();
}

class _CartListScreenState extends State<CartListScreen> {
  bool isLoading = true;
  Map<String, dynamic>? cartData;
  List<dynamic> products = [];
  double totalPrice = 0.0;

  // Map to hold checkbox states for additional attachments per product.
  Map<String, Map<String, bool>> additionalAttachmentsChecked = {};
  final GetStorage storage = GetStorage();
  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  Future<void> fetchCartData() async {
    final String token = storage.read("jwt") ?? "";
    print("Token $token");// Retrieve JWT token
    final Uri url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/cart/viewCart");

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          cartData = data["cart"];
          products = cartData!["products"];
          totalPrice = cartData!["totalPrice"].toDouble();
          isLoading = false;

          // Initialize checkbox state for each product's additional attachments
          for (var product in products) {
            String productId = product["_id"];
            additionalAttachmentsChecked[productId] = {};
            if (product["isAdditionalAttachments"] == true &&
                product["additionalAttachments"] != null) {
              for (var attachment in product["additionalAttachments"]) {
                additionalAttachmentsChecked[productId]![attachment["_id"]] = false;
              }
            }
          }
        });
      } else {
        throw Exception("Failed to load cart data: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching cart data: $e")),
      );
    }
  }

  Widget _buildProductCard(dynamic product) {
    String productId = product["_id"];
    String name = product["name"];
    String condition = product["condition"];
    double total = product["total"] != null ? product["total"].toDouble() : 0.0;
    String imageUrl = (product["productImages"] != null &&
        product["productImages"].length > 0)
        ? product["productImages"][0]
        : "https://via.placeholder.com/150";

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Text(name,
            style:
            GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        subtitle: Text("Total: ₹$total",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.green)),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Condition: $condition",
                    style: GoogleFonts.poppins(fontSize: 16)),
                SizedBox(height: 5),
                Text("Description: ${product["description"]}",
                    style: GoogleFonts.poppins(fontSize: 14)),
                SizedBox(height: 10),
                Text("Booking Dates:",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text("From: ${product["bookingDates"]["from"]}",
                    style: GoogleFonts.poppins(fontSize: 14)),
                Text("To: ${product["bookingDates"]["to"]}",
                    style: GoogleFonts.poppins(fontSize: 14)),
                SizedBox(height: 10),
                Text("Additional Attachments:",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (product["isAdditionalAttachments"] == true &&
                    product["additionalAttachments"] != null)
                  Column(
                    children: List<Widget>.from(
                        product["additionalAttachments"].map((attachment) {
                          String attachmentId = attachment["_id"];
                          return Row(
                            children: [
                              Checkbox(
                                value: additionalAttachmentsChecked[productId]!
                                [attachmentId],
                                onChanged: (bool? value) {
                                  setState(() {
                                    additionalAttachmentsChecked[productId]![attachmentId] =
                                        value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: ListTile(
                                  leading: Image.network(
                                    attachment["attachementImage"],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                  title: Text(attachment["attachmentName"],
                                      style: GoogleFonts.poppins(fontSize: 16)),
                                  subtitle: Text("Price: ₹${attachment["price"]}",
                                      style: GoogleFonts.poppins(fontSize: 14)),
                                ),
                              )
                            ],
                          );
                        })),
                  ),
                SizedBox(height: 10),
                Text("Additional Services:",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (product["isAdditionalServices"] == true &&
                    product["additionalServices"] != null)
                  Column(
                    children: List<Widget>.from(
                        product["additionalServices"].map((service) {
                          return ListTile(
                            leading: Icon(Icons.miscellaneous_services),
                            title: Text(service["serviceType"],
                                style: GoogleFonts.poppins(fontSize: 16)),
                            subtitle: Text("Price: ₹${service["price"]}",
                                style: GoogleFonts.poppins(fontSize: 14)),
                          );
                        })),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cart List", style: GoogleFonts.poppins())),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Display cart items as cards
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index]);
              },
            ),
            SizedBox(height: 20),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Cart Summary",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("Total Price: ₹$totalPrice",
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.green)),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // Show cart summary details in a dialog
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Cart Details",
                                  style: GoogleFonts.poppins()),
                              content: Text(
                                "Total Products: ${products.length}\nTotal Price: ₹$totalPrice",
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: Text("Close",
                                      style: GoogleFonts.poppins()),
                                )
                              ],
                            );
                          });
                    },
                    child: Text("View Details",
                        style: GoogleFonts.poppins()),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}