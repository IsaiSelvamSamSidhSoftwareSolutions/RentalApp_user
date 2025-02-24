
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
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
    _parseAvailableDates();
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
    List<dynamic> datesJson = widget.product["availableDays"];
    availableDates = datesJson.map((date) => DateTime.parse(date)).toList();
  }

  Future<void> _selectStartDate(BuildContext context) async {
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
        selectedEndDate = null; // Reset end date when start date changes
        numberOfDays = 0; // Reset number of days
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
                  Row(
                    children: [
                      Text(
                        "Availability: ",
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Additional Services:",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...widget.product["additionalFields"].map<Widget>((service) {
                    return Text(
                      "${service["fieldName"]}: ₹${service["price"]} per day",
                      style: GoogleFonts.poppins(fontSize: 16),
                    );
                  }).toList(),
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
            // // Price Type Dropdown
            // DropdownButton<String>(
            //   value: selectedPriceType,
            //   onChanged: (String? newValue) {
            //     setState(() {
            //       selectedPriceType = newValue!;
            //     });
            //   },
            //   items: widget.product["priceTypes"].map<DropdownMenuItem<String>>((priceType) {
            //     return DropdownMenuItem<String>(
            //       value: priceType["type"],
            //       child: Text(priceType["type"]),
            //     );
            //   }).toList(),
            // ),
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
                FilteringTextInputFormatter.digitsOnly
              ],
              onChanged: (value) {
                setState(() {
                  quantity = int.tryParse(value) ?? 1;
                });
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
                      availableDays: List<String>.from(widget.product["availableDays"]),
                      additionalFields: List<Map<String, dynamic>>.from(widget.product["additionalFields"]),
                      quantity: quantity,
                      selectedPriceType: selectedPriceType,
                      numberOfDays: numberOfDays,
                      selectedStartDate: selectedStartDate,
                      selectedEndDate: selectedEndDate,
                      additionalServices: List<Map<String, dynamic>>.from(widget.product["additionalServices"]),
                      additionalAttachments: List<Map<String, dynamic>>.from(widget.product["additionalAttachments"]), // Pass additionalAttachments
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