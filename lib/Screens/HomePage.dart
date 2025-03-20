
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:get_storage/get_storage.dart';
import 'ProductsHome.dart'; // Import Products List Screen
import '../authentication/ProfileView.dart'; // Import Profile Screen
import '../Screens/CartListScreen.dart'; // Import Cart List Screen
import '../Screens/OrderHistory.dart';
void main() async {
  await GetStorage.init(); // Initialize GetStorage
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GetStorage storage = GetStorage(); // Global instance of GetStorage
  final List<Widget> _screens = [ProductsListScreen(), OrderHistoryScreen(), UserProfileScreen()];

  @override
  void initState() {
    super.initState();
    // Initialize cart item count if not already set
    if (storage.read("cartProductCount") == null) {
      storage.write("cartProductCount", 0);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Callback to update cart item count
  void _updateCartItemCount(int count) {
    storage.write("cartProductCount", count);
    setState(() {}); // Trigger a rebuild to reflect the new count
  }

  @override
  Widget build(BuildContext context) {
    int cartItemCount = storage.read("cartProductCount") ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Rental App User",
          style: TextStyle(
            fontSize: 20, // Increase font size
            fontWeight: FontWeight.bold, // Make text bold
            color: Colors.black, // Change text color
            letterSpacing: 1.2, // Add letter spacing
          ),
          overflow: TextOverflow.ellipsis, // Handle overflow
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: badges.Badge(
              position: badges.BadgePosition.topEnd(top: -5, end: -5),
              badgeContent: Text(
                cartItemCount.toString(),
                style: TextStyle(color: Colors.white),
              ),
              child: IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartListScreen(
                        updateCartItemCount: _updateCartItemCount,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: "Order History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}