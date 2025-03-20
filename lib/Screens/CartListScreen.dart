import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:vendor_app_user/Screens/ProductsHome.dart';
import 'CheckoutPage.dart'; // Import the CheckoutPage

class CartListScreen extends StatefulWidget {
  final Function(int)? updateCartItemCount; // Callback to update cart item count

  const CartListScreen({Key? key, this.updateCartItemCount}) : super(key: key);

  @override
  _CartListScreenState createState() => _CartListScreenState();
}

class _CartListScreenState extends State<CartListScreen> {
  bool isLoading = true;
  Map<String, dynamic>? cartData;
  List<dynamic> products = [];
  double totalPrice = 0.0;

  // Maps to hold checkbox states and quantities for additional services per product.
  Map<String, Map<String, bool>> additionalServicesChecked = {};
  Map<String, Map<String, int>> additionalServicesQuantity = {};
  Map<String, bool> selectedProducts = {}; // Track selected products
  Map<String, bool> selectedServices = {}; // Track selected services
  Map<String, bool> selectedAttachments = {}; // Track selected attachments
  Map<String, String> selectedDeliveryOptions = {}; // Key: productId, Value: delivery option

  final GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();
    fetchCartData();
    // Initialize selected items (all items are unselected by default)
    selectedProducts = {};
    selectedServices = {};
    selectedAttachments = {};
  }

  // Helper function to format date
  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date); // Format: 12 Oct 2023
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  // Function to calculate the total price of selected items
  void _calculateTotalPrice() {
    double newTotalPrice = 0.0;

    print("Selected Products: $selectedProducts");
    print("Selected Services: $selectedServices");
    print("Selected Attachments: $selectedAttachments");

    // Loop through products and add prices of selected items
    products.forEach((product) {
      String productId = product["productId"] ?? "";
      if (selectedProducts[productId] ?? false) {
        print("Adding product: ${product["productName"]} - ₹${product["total"]}");
        newTotalPrice += (product["total"] ?? 0.0).toDouble();

        // Add additional services
        if (product["additionalServices"] != null) {
          for (var service in product["additionalServices"]) {
            String serviceId = service["_id"] ?? "";
            if (selectedServices[serviceId] ?? false) {
              print("Adding service: ${service["serviceType"]} - ₹${service["price"]}");
              newTotalPrice += (service["price"] ?? 0.0).toDouble();
            }
          }
        }

        // Add additional attachments
        if (product["additionalAttachments"] != null) {
          for (var attachment in product["additionalAttachments"]) {
            String attachmentId = attachment["_id"] ?? "";
            if (selectedAttachments[attachmentId] ?? false) {
              print("Adding attachment: ${attachment["attachmentName"]} - ₹${attachment["price"]}");
              newTotalPrice += (attachment["price"] ?? 0.0).toDouble();
            }
          }
        }
      }
    });

    print("New Total Price: ₹${newTotalPrice.toStringAsFixed(2)}");
    setState(() {
      totalPrice = newTotalPrice;
    });
  }

  Future<void> fetchCartData() async {
    final String token = storage.read("jwt") ?? "";
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
          isLoading = false;
          totalPrice = (cartData!["totalPrice"] ?? 0.0).toDouble();
        });

        // Update cartProductCount in GetStorage and notify HomePage
        if (widget.updateCartItemCount != null) {
          widget.updateCartItemCount!(products.length);
        }
        print("Cart details $data");
      } else {
        print("API Error Response: ${response.body}");
        throw Exception("Failed to load cart data: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching cart data: $e")));
    }
  }

  Future<void> deleteCart() async {
    String? userId = storage.read("_id");
    String? token = storage.read("jwt");

    if (userId == null) {
      print("User ID not found");
      return;
    }

    final String apiUrl = "https://getsetbuild.samsidh.com/api/v1/cart/deleteCart";

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        print("Cart deleted successfully");
        setState(() {
          products = [];
          totalPrice = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cart deleted successfully")));
      } else {
        print("Failed to delete cart: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete cart")));
      }
    } catch (e) {
      print("Exception occurred: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting cart: $e")));
    }
  }
  //
  // Widget _buildProductCard(dynamic product) {
  //   String productId = product["productId"] ?? "";
  //   String name = product["productName"] ?? "Unnamed Product";
  //   double total = (product["total"] ?? 0.0).toDouble();
  //   String imageUrl = product["productImage"] ?? "https://via.placeholder.com/150";
  //   int productQuantity = product["quantity"] ?? 1;
  //
  //   return Card(
  //     margin: EdgeInsets.all(10),
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //     child: ExpansionTile(
  //       title: Row(
  //         children: [
  //           Checkbox(
  //             value: selectedProducts[productId] ?? false,
  //             onChanged: (value) {
  //               setState(() {
  //                 selectedProducts[productId] = value ?? false;
  //
  //                 // Clear all selections for this product if unchecked
  //                 if (!(value ?? false)) {
  //                   // Clear selected services
  //                   if (product["additionalServices"] != null) {
  //                     for (var service in product["additionalServices"]) {
  //                       String serviceId = service["_id"] ?? "";
  //                       selectedServices.remove(serviceId);
  //                     }
  //                   }
  //
  //                   // Clear selected attachments
  //                   if (product["additionalAttachments"] != null) {
  //                     for (var attachment in product["additionalAttachments"]) {
  //                       String attachmentId = attachment["_id"] ?? "";
  //                       selectedAttachments.remove(attachmentId);
  //                     }
  //                   }
  //
  //                   // Clear selected delivery option
  //                   selectedDeliveryOptions.remove(productId);
  //                 }
  //
  //                 _calculateTotalPrice(); // Update total price
  //               });
  //             },
  //           ),
  //           Expanded(
  //             child: Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
  //           ),
  //         ],
  //       ),
  //       leading: ClipRRect(
  //         borderRadius: BorderRadius.circular(10),
  //         child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
  //       ),
  //       subtitle: Text(
  //         "Total: ₹${total.toStringAsFixed(2)}",
  //         style: GoogleFonts.poppins(fontSize: 16, color: Colors.green),
  //       ),
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text("Booking Dates:", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
  //               Text("From: ${_formatDate(product["bookingDates"]["from"])}", style: GoogleFonts.poppins(fontSize: 14)),
  //               Text("To: ${_formatDate(product["bookingDates"]["to"])}", style: GoogleFonts.poppins(fontSize: 14)),
  //               SizedBox(height: 10),
  //
  //               // Operator Service Checkbox
  //               Row(
  //                 children: [
  //                   Checkbox(
  //                     value: additionalServicesChecked[productId]?["operatorService"] ?? false,
  //                     onChanged: (bool? value) {
  //                       setState(() {
  //                         additionalServicesChecked[productId] ??= {};
  //                         additionalServicesChecked[productId]!["operatorService"] = value ?? false;
  //                         _calculateTotalPrice();
  //                       });
  //                     },
  //                   ),
  //                   Text("Operator Service", style: GoogleFonts.poppins(fontSize: 16)),
  //                 ],
  //               ),
  //
  //               SizedBox(height: 10),
  //
  //               // Delivery Options (Radio Buttons)
  //               Text("Delivery Options:", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
  //               if (product["additionalServices"] != null && product["additionalServices"].isNotEmpty)
  //                 Column(
  //                   children: List<Widget>.from(product["additionalServices"].map((service) {
  //                     String serviceId = service["_id"] ?? "";
  //                     String serviceType = service["serviceType"] ?? "";
  //                     double servicePrice = (service["price"] ?? 0.0).toDouble();
  //
  //                     return GestureDetector(
  //                       onDoubleTap: () {
  //                         // Double-click to deselect the radio button
  //                         setState(() {
  //                           if (selectedDeliveryOptions[productId] == serviceId) {
  //                             selectedDeliveryOptions[productId] = ""; // Deselect
  //                             selectedServices.remove(serviceId); // Remove from selected services
  //                           }
  //                           _calculateTotalPrice(); // Update total price
  //                         });
  //                       },
  //                       child: RadioListTile<String>(
  //                         title: Text("$serviceType - ₹${servicePrice.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 14)),
  //                         value: serviceId,
  //                         groupValue: selectedDeliveryOptions[productId] ?? "",
  //                         onChanged: (value) {
  //                           setState(() {
  //                             // Toggle selection: If the same option is clicked again, deselect it
  //                             if (selectedDeliveryOptions[productId] == value) {
  //                               selectedDeliveryOptions[productId] = ""; // Deselect
  //                               selectedServices.remove(serviceId); // Remove from selected services
  //                             } else {
  //                               selectedDeliveryOptions[productId] = value!; // Select
  //                               selectedServices[serviceId] = true; // Add to selected services
  //                             }
  //                             _calculateTotalPrice(); // Update total price
  //                           });
  //                         },
  //                       ),
  //                     );
  //                   })),
  //                 ),
  //
  //               SizedBox(height: 10),
  //
  //               // Additional Attachments
  //               Text("Additional Attachments:", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
  //               if (product["additionalAttachments"] != null && product["additionalAttachments"].isNotEmpty)
  //                 Column(
  //                   children: List<Widget>.from(product["additionalAttachments"].map((attachment) {
  //                     String attachmentId = attachment["_id"] ?? "";
  //                     return CheckboxListTile(
  //                       title: Text(attachment["attachmentName"] ?? "Unnamed Attachment"),
  //                       subtitle: Text("Price: ₹${(attachment["price"] ?? 0.0).toStringAsFixed(2)}"),
  //                       value: selectedAttachments[attachmentId] ?? false,
  //                       onChanged: (bool? value) {
  //                         setState(() {
  //                           selectedAttachments[attachmentId] = value ?? false;
  //                           _calculateTotalPrice();
  //                         });
  //                       },
  //                     );
  //                   })),
  //                 ),
  //
  //               SizedBox(height: 10),
  //
  //               // Display additional services summary
  //               Text(
  //                 "Additional Services Summary:",
  //                 style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //               if (product["additionalServices"] != null && product["additionalServices"].isNotEmpty)
  //                 Column(
  //                   children: [
  //                     // Display selected services
  //                     ...List<Widget>.from(product["additionalServices"].map((service) {
  //                       String serviceId = service["_id"] ?? "";
  //                       if (selectedServices[serviceId] ?? false) {
  //                         return ListTile(
  //                           title: Text(service["serviceType"] ?? "Unnamed Service"),
  //                           subtitle: Text("Price: ₹${(service["price"] ?? 0.0).toStringAsFixed(2)}"),
  //                         );
  //                       }
  //                       return SizedBox.shrink(); // Hide unselected services
  //                     })),
  //                     // Display selected attachments
  //                     ...List<Widget>.from(product["additionalAttachments"].map((attachment) {
  //                       String attachmentId = attachment["_id"] ?? "";
  //                       if (selectedAttachments[attachmentId] ?? false) {
  //                         return ListTile(
  //                           title: Text(attachment["attachmentName"] ?? "Unnamed Attachment"),
  //                           subtitle: Text("Price: ₹${(attachment["price"] ?? 0.0).toStringAsFixed(2)}"),
  //                         );
  //                       }
  //                       return SizedBox.shrink(); // Hide unselected attachments
  //                     })),
  //                     // Display total price of selected services and attachments
  //                     ListTile(
  //                       title: Text(
  //                         "Total Additional Services:",
  //                         style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
  //                       ),
  //                       subtitle: Text(
  //                         "₹${_calculateAdditionalServicesTotal(product).toStringAsFixed(2)}",
  //                         style: GoogleFonts.poppins(fontSize: 16, color: Colors.green),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildProductCard(dynamic product) {
    String productId = product["productId"] ?? "";
    String name = product["productName"] ?? "Unnamed Product";
    double total = (product["total"] ?? 0.0).toDouble();
    String imageUrl = product["productImage"] ?? "https://via.placeholder.com/150";
    int productQuantity = product["quantity"] ?? 1;

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              value: selectedProducts[productId] ?? false,
              onChanged: (value) {
                setState(() {
                  selectedProducts[productId] = value ?? false;

                  // Clear all selections for this product if unchecked
                  if (!(value ?? false)) {
                    // Clear selected services
                    if (product["additionalServices"] != null) {
                      for (var service in product["additionalServices"]) {
                        String serviceId = service["_id"] ?? "";
                        selectedServices.remove(serviceId);
                      }
                    }

                    // Clear selected attachments
                    if (product["additionalAttachments"] != null) {
                      for (var attachment in product["additionalAttachments"]) {
                        String attachmentId = attachment["_id"] ?? "";
                        selectedAttachments.remove(attachmentId);
                      }
                    }

                    // Clear selected delivery option
                    selectedDeliveryOptions.remove(productId);
                  }

                  _calculateTotalPrice(); // Update total price
                });
              },
            ),
            Expanded(
              child: Text(name, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
        ),
        subtitle: Text(
          "Total: ₹${total.toStringAsFixed(2)}",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.green),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            // Show confirmation dialog
            bool confirmDelete = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Delete Product"),
                  content: Text("Are you sure you want to delete this product from the cart?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false); // Return false if canceled
                      },
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true); // Return true if confirmed
                      },
                      child: Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );

            // If user confirms deletion, call the API to delete the product
            if (confirmDelete == true) {
              await _deleteProductFromCart(productId);
            }
          },
        ),
        children: [
          Text("From: ${_formatDate(product["bookingDates"]["from"])}", style: GoogleFonts.poppins(fontSize: 17)),
          Text("To: ${_formatDate(product["bookingDates"]["to"])}", style: GoogleFonts.poppins(fontSize: 17)),
          // Rest of the ExpansionTile children (unchanged)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [

                    Checkbox(
                      value: additionalServicesChecked[productId]?["operatorService"] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          additionalServicesChecked[productId] ??= {};
                          additionalServicesChecked[productId]!["operatorService"] = value ?? false;
                          _calculateTotalPrice();
                        });
                      },
                    ),
                    Text("Operator Service", style: GoogleFonts.poppins(fontSize: 16)),
                  ],
                ),

                SizedBox(height: 10),

                // Delivery Options (Radio Buttons)
                Text("Delivery Options:", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                if (product["additionalServices"] != null && product["additionalServices"].isNotEmpty)
                  Column(
                    children: List<Widget>.from(product["additionalServices"].map((service) {
                      String serviceId = service["_id"] ?? "";
                      String serviceType = service["serviceType"] ?? "";
                      double servicePrice = (service["price"] ?? 0.0).toDouble();

                      return GestureDetector(
                        onDoubleTap: () {
                          // Double-click to deselect the radio button
                          setState(() {
                            if (selectedDeliveryOptions[productId] == serviceId) {
                              selectedDeliveryOptions[productId] = ""; // Deselect
                              selectedServices.remove(serviceId); // Remove from selected services
                            }
                            _calculateTotalPrice(); // Update total price
                          });
                        },
                        child: RadioListTile<String>(
                          title: Text("$serviceType - ₹${servicePrice.toStringAsFixed(2)}", style: GoogleFonts.poppins(fontSize: 14)),
                          value: serviceId,
                          groupValue: selectedDeliveryOptions[productId] ?? "",
                          onChanged: (value) {
                            setState(() {
                              // Toggle selection: If the same option is clicked again, deselect it
                              if (selectedDeliveryOptions[productId] == value) {
                                selectedDeliveryOptions[productId] = ""; // Deselect
                                selectedServices.remove(serviceId); // Remove from selected services
                              } else {
                                selectedDeliveryOptions[productId] = value!; // Select
                                selectedServices[serviceId] = true; // Add to selected services
                              }
                              _calculateTotalPrice(); // Update total price
                            });
                          },
                        ),
                      );
                    })),
                  ),

                SizedBox(height: 10),

                // Additional Attachments
                Text("Additional Attachments:", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                if (product["additionalAttachments"] != null && product["additionalAttachments"].isNotEmpty)
                  Column(
                    children: List<Widget>.from(product["additionalAttachments"].map((attachment) {
                      String attachmentId = attachment["_id"] ?? "";
                      return CheckboxListTile(
                        title: Text(attachment["attachmentName"] ?? "Unnamed Attachment"),
                        subtitle: Text("Price: ₹${(attachment["price"] ?? 0.0).toStringAsFixed(2)}"),
                        value: selectedAttachments[attachmentId] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            selectedAttachments[attachmentId] = value ?? false;
                            _calculateTotalPrice();
                          });
                        },
                      );
                    })),
                  ),

                SizedBox(height: 10),



                // Display additional services summary
                Text(
                  "Additional Services Summary:",
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (product["additionalServices"] != null && product["additionalServices"].isNotEmpty)
                  Column(
                    children: [
                      // Display selected services
                      ...List<Widget>.from(product["additionalServices"].map((service) {
                        String serviceId = service["_id"] ?? "";
                        if (selectedServices[serviceId] ?? false) {
                          return ListTile(
                            title: Text(service["serviceType"] ?? "Unnamed Service"),
                            subtitle: Text("Price: ₹${(service["price"] ?? 0.0).toStringAsFixed(2)}"),
                          );
                        }
                        return SizedBox.shrink(); // Hide unselected services
                      })),
                      // Display selected attachments
                      ...List<Widget>.from(product["additionalAttachments"].map((attachment) {
                        String attachmentId = attachment["_id"] ?? "";
                        if (selectedAttachments[attachmentId] ?? false) {
                          return ListTile(
                            title: Text(attachment["attachmentName"] ?? "Unnamed Attachment"),
                            subtitle: Text("Price: ₹${(attachment["price"] ?? 0.0).toStringAsFixed(2)}"),
                          );
                        }
                        return SizedBox.shrink(); // Hide unselected attachments
                      })),
                      // Display total price of selected services and attachments
                      ListTile(
                        title: Text(
                          "Total Additional Services:",
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "₹${_calculateAdditionalServicesTotal(product).toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.green),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  double _calculateAdditionalServicesTotal(dynamic product) {
    double total = 0.0;

    // Add selected services
    if (product["additionalServices"] != null) {
      for (var service in product["additionalServices"]) {
        String serviceId = service["_id"] ?? "";
        if (selectedServices[serviceId] ?? false) {
          total += (service["price"] ?? 0.0).toDouble();
        }
      }
    }

    // Add selected attachments
    if (product["additionalAttachments"] != null) {
      for (var attachment in product["additionalAttachments"]) {
        String attachmentId = attachment["_id"] ?? "";
        if (selectedAttachments[attachmentId] ?? false) {
          total += (attachment["price"] ?? 0.0).toDouble();
        }
      }
    }

    return total;
  }
  void _showBufferDateDialog(String bookingFrom, String bookingTo) {
    TextEditingController fromController = TextEditingController();
    TextEditingController toController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        DateTime firstDateFrom = DateTime.parse(bookingTo).add(Duration(days: 1));

        return AlertDialog(
          title: Text("Buffer Dates"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Buffer dates are additional days reserved around your booking dates for preparation, cleaning, or transition."),
              SizedBox(height: 10),
              Text("Please select buffer dates:"),
              TextField(
                controller: fromController,
                decoration: InputDecoration(labelText: "From (YYYY-MM-DD)"),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());

                  DateTime initialDate = DateTime.now();
                  if (initialDate.isBefore(firstDateFrom)) {
                    initialDate = firstDateFrom;
                  }

                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDateFrom,
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    fromController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                  }
                },
              ),
              TextField(
                controller: toController,
                decoration: InputDecoration(labelText: "To (YYYY-MM-DD)"),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());

                  DateTime firstDateTo = DateTime.parse(fromController.text).add(Duration(days: 1));

                  DateTime initialDate = DateTime.now();
                  if (initialDate.isBefore(firstDateTo)) {
                    initialDate = firstDateTo;
                  }

                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: firstDateTo,
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    toController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String bufferFrom = fromController.text;
                String bufferTo = toController.text;

                if (bufferFrom.isNotEmpty && bufferTo.isNotEmpty) {
                  Navigator.of(context).pop();
                  _navigateToCheckout(bufferFrom, bufferTo);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select valid buffer dates.")),
                  );
                }
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCheckout(String bufferFrom, String bufferTo) {
    List<Map<String, dynamic>> bookingProducts = products.map((product) {
      return {
        "productId": product["productId"],
        "quantity": product["quantity"],
        "bookingDates": {
          "from": product["bookingDates"]["from"],
          "to": product["bookingDates"]["to"],
        },
        "bufferDates": {
          "from": bufferFrom,
          "to": bufferTo,
        },
        "priceType": {
          "type": "daily",
          "price": product["total"] / product["quantity"],
        },
        "gst": 18,
        "platformCharges": 2,
        "additionalAttachments": product["additionalAttachments"] != null
            ? product["additionalAttachments"].map((attachment) {
          return {
            "attachmentName": attachment["attachmentName"],
            "attachementDescription": attachment["attachementDescription"] ?? "",
            "price": attachment["price"],
            "attachementImage": attachment["attachementImage"] ?? "",
          };
        }).toList()
            : [],
        "additionalServices": product["additionalServices"].where((service) {
          return selectedServices[service["_id"]] ?? false;
        }).map((service) {
          return {
            "serviceType": service["serviceType"],
            "price": service["price"],
          };
        }).toList(),
      };
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(
          products: bookingProducts,
          totalPrice: totalPrice,
          bufferDates: {
            "from": _formatDate(bufferFrom),
            "to": _formatDate(bufferTo),
          },
        ),
      ),
    );
  }
  Future<void> _deleteProductFromCart(String productId) async {
    final String token = storage.read("jwt") ?? "";
    final Uri url = Uri.parse("https://getsetbuild.samsidh.com/api/v1/cart/removeProduct");

    try {
      final response = await http.patch(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "productId": productId,
        }),
      );

      // Print the API response for debugging
      print("Delete Product Response Status Code: ${response.statusCode}");
      print("Delete Product Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Product deleted successfully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Product deleted successfully!")),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => CartListScreen()), // Replace with your cart page widget
        );

        // Refresh the cart or update the UI
        // You can call a method to reload the cart data here

      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete product: ${response.statusCode}")),
        );
      }
    } catch (e) {
      // Handle exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting product: $e")),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cart List", style: GoogleFonts.poppins()),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text(
              "Your cart is empty",
              style: GoogleFonts.poppins(fontSize: 20, color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            SizedBox(height: 20),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
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
                  Text(
                    "Cart Summary",
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                    child: Text(
                      "Total Price: ₹${totalPrice.toStringAsFixed(2)}",
                      key: ValueKey(totalPrice),
                      style: GoogleFonts.poppins(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Confirm Delete", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                                  content: Text("Do you want to delete Entire product in cart?", style: GoogleFonts.poppins(fontSize: 16)),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text("Cancel", style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        deleteCart();
                                      },
                                      child: Text("Delete", style: GoogleFonts.poppins(fontSize: 16, color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text("Delete Cart", style: GoogleFonts.poppins(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (products.isNotEmpty) {
                              String bookingFrom = products[0]["bookingDates"]["from"];
                              String bookingTo = products[0]["bookingDates"]["to"];
                              _showBufferDateDialog(bookingFrom, bookingTo);
                            }
                          },
                          child: Text("Proceed to Checkout", style: GoogleFonts.poppins()),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white, backgroundColor: Colors.lightGreen,
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: products.isEmpty
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductsListScreen()));
        },
        child: Icon(Icons.shopping_cart),
        backgroundColor: Colors.blue,
      )
          : null,
    );
  }
}