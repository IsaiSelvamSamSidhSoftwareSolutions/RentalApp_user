
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../Screens/RentProductScreen.dart';
class ProductsListScreen extends StatefulWidget {
  @override
  _ProductsListScreenState createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  bool isLoading = false;
  bool showAllProducts = false;
  double latitude = 17.5513;
  double longitude = 78.3855;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (latitude == 0.0 || longitude == 0.0) {
      showSnackbar("Please set a valid location first.", Colors.red);
      return;
    }

    setState(() => isLoading = true);
    final String token = storage.read("jwt") ?? "";
    print("ORGINAL TOKEN $token");
    // Construct the API URL
    final url = Uri.parse(
        "https://getsetbuild.samsidh.com/api/v1/products/getProductsNearby?lat=$latitude&lng=$longitude");

    // Print the API URL
    print("Fetching products from: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      setState(() => isLoading = false);

      // Print the API response
      print("API Response: ${response.body}");

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody["status"] == "success") {
        setState(() {
          products = responseBody["data"]["products"];
          filteredProducts = products;
        });

        // Check if no products were found
        if (products.isEmpty) {
          _showNoProductsAlert();
        }
      } else if (responseBody["status"] == "fail" && responseBody["message"] ==
          "No products found within the specified range") {
        _showNoProductsAlert();
      } else {
        throw Exception(responseBody["message"] ?? "Failed to load products.");
      }
    } catch (e) {
      setState(() {
        products = [];
        filteredProducts = [];
      });
      showSnackbar("Error: $e", Colors.red);
    }
  }

  void _showNoProductsAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("No Products Found"),
          content: Text(
              "No products were found for the current location. Would you like to use the development use default Lat and Long instead?"),
          actions: [
            TextButton(
              onPressed: () {
                // Set the development URL
                latitude = 17.5513; // Set the development latitude
                longitude = 78.3855; // Set the development longitude
                Navigator.of(context).pop(); // Close the dialog
                _fetchProducts(); // Fetch products with the development URL
              },
              child: Text("Yes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("No"),
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      filteredProducts = value.isEmpty
          ? products
          : products.where((product) =>
          product["name"].toLowerCase().contains(value.toLowerCase())).toList();
    });
  }

  Future<void> _convertPlaceToLatLng(String place) async {
    try {
      List<Location> locations = await locationFromAddress(place);
      if (locations.isNotEmpty) {
        setState(() {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
        });
        _fetchProducts();
      } else {
        throw Exception("No valid location found.");
      }
    } catch (e) {
      showSnackbar("Error: $e", Colors.red);
    }
  }

  void _showLocationDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: "Enter Location (e.g., Chennai, Kerala, Vizag)",
                    labelStyle: GoogleFonts.poppins(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    String place = locationController.text.trim();
                    if (place.isEmpty) {
                      showSnackbar("Please enter a location.", Colors.red);
                      return;
                    }
                    Navigator.pop(context);
                    _convertPlaceToLatLng(place);
                  },
                  child: Text(
                    "Set Location",
                    style: GoogleFonts.poppins(fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    // If location services are disabled, ask the user to enable them
    if (!serviceEnabled) {
      bool isEnabled = await Geolocator.openLocationSettings();
      if (!isEnabled) {
        showSnackbar("Please enable location services.", Colors.red);
        return;
      }
    }

    // Check and request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showSnackbar("Location permission is required to fetch your location.",
            Colors.red);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showSnackbar(
          "Location permissions are permanently denied. Please enable them in settings.",
          Colors.red);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      showSnackbar("Location fetched successfully!", Colors.green);

      // Fetch products after getting location
      await _fetchProducts(); // Ensure this is awaited to handle any errors

    } catch (e) {
      showSnackbar("Failed to get location: $e", Colors.red);
    }
  }

  void showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeInDown(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search products...",
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  searchController.clear();
                  _onSearchChanged("");
                },
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.location_on, color: Colors.black87),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.black87))
          : filteredProducts.isEmpty
          ? Center(
        child: Text(
          "No products found",
          style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600),
        ),
      )
          : ListView(
        children: [
          ...filteredProducts.take(5).map((product) =>
              _buildProductCard(product)).toList(),
          if (filteredProducts.length > 5 && !showAllProducts)
            TextButton(
              onPressed: () => setState(() => showAllProducts = true),
              child: Text("See more",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.blue)),
            ),
          if (showAllProducts) ...filteredProducts.skip(5).map((product) =>
              _buildProductCard(product)).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLocationDialog,
        backgroundColor: Colors.black87,
        child: Icon(Icons.location_searching, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    String imageUrl = product["productImages"].isNotEmpty
        ? product["productImages"][0]
        : "https://via.placeholder.com/150"; // Placeholder if no image

    return GestureDetector(
      onTap: () {


        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RentProductScreen(
              product: product,

            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(10),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            product["name"],
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Price: ₹${product["priceTypes"][0]["price"]} / ${product["priceTypes"][0]["type"]}"),
              Text("Condition: ${product["condition"]}"),
              Text("Available Quantity: ${product["quantity"]}"),
            ],
          ),
        ),
      ),
    );
  }
}