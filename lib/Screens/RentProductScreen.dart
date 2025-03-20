import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'AddToCart.dart';

class RentProductScreen extends StatefulWidget {
  final dynamic product;

  RentProductScreen({required this.product});

  @override
  _RentProductScreenState createState() => _RentProductScreenState();
}

class _RentProductScreenState extends State<RentProductScreen>
    with SingleTickerProviderStateMixin {
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  List<DateTime> availableDates = [];
  int quantity = 1;
  String selectedPriceType = "daily";
  int numberOfDays = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    print("Product Data: ${widget.product}"); // Print product details
    if (widget.product != null) {
      _parseAvailableDates(); // Parse dates only if product exists
    } else {
      print("Error: Product data is null");
    }

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _parseAvailableDates() {
    if (widget.product.containsKey("availableDays") && widget.product["availableDays"] != null) {
      // If `availableDays` exists, use it
      List<dynamic> datesJson = widget.product["availableDays"];
      availableDates = datesJson.map((date) => DateTime.parse(date.toString())).toList();
    } else if (widget.product.containsKey("availability") &&
        widget.product["availability"]["from"] != null &&
        widget.product["availability"]["to"] != null) {
      // Generate availableDays from "availability" period
      DateTime startDate = DateTime.parse(widget.product["availability"]["from"]);
      DateTime endDate = DateTime.parse(widget.product["availability"]["to"]);

      availableDates = [];
      for (DateTime date = startDate;
      date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
      date = date.add(Duration(days: 1))) {
        availableDates.add(date);
      }

      print("Generated availableDates from availability: $availableDates");
    } else {
      print("No available date information found!");
      availableDates = [];
    }

    print("Final availableDates: $availableDates");
  }



  Future<void> _selectStartDate(BuildContext context) async {
    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No available dates found.")),
      );
      return;
    }

    // Convert availableDates.first to local time and extract date part
    DateTime today = DateTime.now();
    DateTime firstAvailableDate = availableDates.first.toLocal();

    // Normalize dates to ignore time (only compare Year-Month-Day)
    DateTime normalizedToday = DateTime(today.year, today.month, today.day);
    DateTime normalizedFirstAvailable = DateTime(firstAvailableDate.year, firstAvailableDate.month, firstAvailableDate.day);

    // Check if the first available date is in the past
    if (normalizedFirstAvailable.isBefore(normalizedToday)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Stock Unavailable"),
          content: Text(
            "Sorry for the inconvenience! This stock is currently unavailable. "
                "You will get an update when the vendor adds new stock.\n\n"
                "Still, you can browse more products.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: availableDates.first,
      firstDate: availableDates.first,
      lastDate: availableDates.last,
      selectableDayPredicate: (DateTime date) {
        return availableDates.any((availableDate) =>
        availableDate.year == date.year &&
            availableDate.month == date.month &&
            availableDate.day == date.day);
      },
    );

    if (pickedDate != null && pickedDate != selectedStartDate) {
      setState(() {
        selectedStartDate = pickedDate;
        selectedEndDate = null; // Reset end date
        numberOfDays = 0;
      });
    }
  }


  Future<void> _selectEndDate(BuildContext context) async {
    if (selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a start date first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedStartDate!,
      firstDate: selectedStartDate!,
      lastDate: availableDates.last,
      selectableDayPredicate: (DateTime date) {
        return availableDates.any((availableDate) =>
        availableDate.year == date.year &&
            availableDate.month == date.month &&
            availableDate.day == date.day);
      },
    );

    if (pickedDate != null && pickedDate != selectedEndDate) {
      setState(() {
        selectedEndDate = pickedDate;
        numberOfDays = selectedEndDate!.difference(selectedStartDate!).inDays + 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Number of days updated to $numberOfDays."),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showImageGallery(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: widget.product["productImages"].length,
          itemBuilder: (context, index) {
            return Image.network(
              widget.product["productImages"][index],
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    double price = selectedPriceType == "hourly"
        ? widget.product["priceTypes"][0]["price"].toDouble()
        : widget.product["priceTypes"][1]["price"].toDouble();

    double totalPrice = price * quantity * (numberOfDays == 0 ? 1 : numberOfDays);

    return Scaffold(
      appBar: AppBar(
        title: Text("Rent ${widget.product["name"]}"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Animation for Product Image
            Hero(
              tag: 'product-image-${widget.product["_id"]}',
              child: GestureDetector(
                onTap: () => _showImageGallery(context),
                child: Center(
                  child: Image.network(
                    widget.product["productImages"].isNotEmpty
                        ? widget.product["productImages"][0]
                        : "https://via.placeholder.com/150",
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Fade-In Animations for Text Elements
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capitalizeFirstLetter(widget.product["name"]),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Condition: ${widget.product["condition"]}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Description: ${widget.product["description"]}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Vendor Name: ${widget.product["vendor"]["companyName"]}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Vendor Location: ${widget.product["address"]["city"]}, ${widget.product["address"]["state"]}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Vendor Code: ${widget.product["vendor"]["_id"]}",
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  if (widget.product["additionalAttachments"] != null &&
                      widget.product["additionalAttachments"].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Additional Attachments:",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...widget.product["additionalAttachments"].map<Widget>((attachment) {
                          return ListTile(
                            leading: Image.network(
                              attachment["attachementImage"],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(
                              attachment["attachmentName"],
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            subtitle: Text(
                              "${attachment["attachementDescription"]} - ₹${attachment["price"]}",
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 10),
                      ],
                    )
                  else
                    Text(
                      "No additional attachments available.",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    ),

                  // Display Additional Services
                  if (widget.product["additionalServices"] != null &&
                      widget.product["additionalServices"].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Additional Services:",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...widget.product["additionalServices"].map<Widget>((service) {
                          return ListTile(
                            title: Text(
                              service["serviceType"],
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            trailing: Text(
                              "₹${service["price"]}",
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ],
                    )
                  else
                    Text(
                      "No additional services available.",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Date Pickers
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectStartDate(context),
                    icon: Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(
                      selectedStartDate == null
                          ? "Select Start Date"
                          : "Start Date: ${DateFormat('yyyy-MM-dd').format(selectedStartDate!)}",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectEndDate(context),
                    icon: Icon(Icons.calendar_today, color: Colors.white),
                    label: Text(
                      selectedEndDate == null
                          ? "Select End Date"
                          : "End Date: ${DateFormat('yyyy-MM-dd').format(selectedEndDate!)}",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedPriceType, // Ensure this matches one of the DropdownMenuItem values
              onChanged: (String? newValue) {
                setState(() {
                  selectedPriceType = newValue!;
                });
              },
              items: [
                DropdownMenuItem(
                  value: "hourly", // Unique value
                  child: Text("Hourly"),
                ),
                DropdownMenuItem(
                  value: "daily", // Unique value
                  child: Text("Daily"),
                ),
              ],
            ),

            SizedBox(height: 10),
            // Quantity Input
            TextField(
              decoration: InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Allow only digits
              ],
              onChanged: (value) {
                int enteredQuantity = int.tryParse(value) ?? 1; // Parse the entered value
                int availableStock = widget.product["quantity"] ?? 1; // Get available stock from the product

                if (enteredQuantity > availableStock) {
                  // Show an alert if the quantity exceeds available stock
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Check Qunatity"),
                      content: Text("Quantity exceeds available stock. Available stock: $availableStock"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                          },
                          child: Text("OK"),
                        ),
                      ],
                    ),
                  );

                  // Reset the quantity to the available stock
                  setState(() {
                    quantity = availableStock;
                  });
                } else {
                  // Update the quantity if it's valid
                  setState(() {
                    quantity = enteredQuantity;
                  });
                }
              },
            ),
            SizedBox(height: 20),
            // Number of Days and Total Price
            Text(
              "Number of Days: $numberOfDays",
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              "Total Price: ₹${totalPrice.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            // Add to Cart Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              onPressed: selectedStartDate == null || selectedEndDate == null
                  ? null
                  : () {
                print("📦 Navigating to AddToCartScreen with Arguments:");
                print("Product ID: ${widget.product["_id"]}");
                print("Product Name: ${widget.product["name"]}");
                print("Product Condition: ${widget.product["condition"]}");
                print("Product Description: ${widget.product["description"]}");
                print("Vendor Name: ${widget.product["vendor"]["companyName"]}");
                print("Vendor Location: ${widget.product["address"]["city"]}, ${widget.product["address"]["state"]}");
                print("Product Image: ${widget.product["productImages"].isNotEmpty ? widget.product["productImages"][0] : "https://via.placeholder.com/150"}");
                print("Price Hourly: ${widget.product["priceTypes"][0]["price"].toDouble()}");
                print("Price Daily: ${widget.product["priceTypes"][1]["price"].toDouble()}");
                print("Available Days: ${widget.product.containsKey("availableDays") ? widget.product["availableDays"] : "No available days"}");
                print("Additional Services: ${widget.product.containsKey("additionalServices") ? jsonEncode(widget.product["additionalServices"]) : "[]"}");
                print("Additional Attachments: ${widget.product.containsKey("additionalAttachments") ? jsonEncode(widget.product["additionalAttachments"]) : "[]"}");
                print("Quantity: $quantity");
                print("Selected Price Type: $selectedPriceType");
                print("Number of Days: $numberOfDays");
                print("Selected Start Date: $selectedStartDate");
                print("Selected End Date: $selectedEndDate");

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddToCartScreen(
                      productId: widget.product["_id"],
                      productName: widget.product["name"],
                      productCondition: widget.product["condition"],
                      productDescription: widget.product["description"],
                      vendorName: widget.product["vendor"]["companyName"],
                      vendorLocation: "${widget.product["address"]["city"]}, ${widget.product["address"]["state"]}",
                      productImage: widget.product["productImages"].isNotEmpty
                          ? widget.product["productImages"][0]
                          : "https://via.placeholder.com/150",
                      priceHourly: widget.product["priceTypes"][0]["price"].toDouble(),
                      priceDaily: widget.product["priceTypes"][1]["price"].toDouble(),
                      availableDays: widget.product.containsKey("availableDays")
                          ? List<String>.from(widget.product["availableDays"])
                          : [], // Pass empty list if availableDays is null
                      quantity: quantity,
                      selectedPriceType: selectedPriceType,
                      numberOfDays: numberOfDays,
                      selectedStartDate: selectedStartDate!,
                      selectedEndDate: selectedEndDate!,
                      additionalServices: widget.product.containsKey("additionalServices")
                          ? List<Map<String, dynamic>>.from(widget.product["additionalServices"])
                          : [], // Pass empty list if additionalServices is null
                      additionalAttachments: widget.product.containsKey("additionalAttachments")
                          ? List<Map<String, dynamic>>.from(widget.product["additionalAttachments"])
                          : [], // Pass empty list if additionalAttachments is null
                    ),
                  ),
                );
              },
              child: Text(
                "Add to Cart",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}