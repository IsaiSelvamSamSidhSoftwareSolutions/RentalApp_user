// import 'package:flutter/material.dart';
// import 'ProductsHome.dart'; // Import Products List Screen
//
// import '../authentication/ProfileView.dart';
// import '../Screens/CartListScreen.dart';
// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;
//   final List<Widget> _screens = [ProductsListScreen(),UserProfileScreen()];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           title: Text("Home"),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.shopping_cart),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => CartListScreen()),
//               );
//             },
//           )
//         ],
//
//       ),
//       body: _screens[_selectedIndex], // Display the selected screen
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         selectedItemColor: Colors.blue,
//         unselectedItemColor: Colors.grey,
//         items: [
//           BottomNavigationBarItem(icon: Icon(Icons.list), label: "Products"), // ✅ Navigate to Products
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:get_storage/get_storage.dart';
import 'ProductsHome.dart'; // Import Products List Screen
import '../authentication/ProfileView.dart'; // Import Profile Screen
import '../Screens/CartListScreen.dart'; // Import Cart List Screen

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
  final List<Widget> _screens = [ProductsListScreen(), UserProfileScreen()];

  @override
  void initState() {
    super.initState();
    // Initialize cart item count if not already set
    if (storage.read("cartItemCount") == null) {
      storage.write("cartItemCount", 0);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateCartItemCount(int count) {
    storage.write("cartItemCount", count);
    setState(() {}); // Trigger a rebuild to reflect the new count
  }

  @override
  Widget build(BuildContext context) {
    int cartItemCount = storage.read("cartItemCount") ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
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
                    MaterialPageRoute(builder: (context) => CartListScreen()),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}