
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';

import 'authentication/signup.dart';
import 'authentication/login.dart';
import 'authentication/email_verification.dart';
import 'authentication/complete_profile.dart';
import 'Screens/HomePage.dart';
import 'Screens/ProductsHome.dart'; // Import ProductsListScreen
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(MyApp());
}

Future<void> getLocationAndStore() async {
  final GetStorage storage = GetStorage();

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    storage.write("location", "Location services disabled");
    return;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    storage.write("location", "Location permission denied");
    return;
  }

  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  storage.write("location", "Lat: ${position.latitude}, Lng: ${position.longitude}");
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rental App',
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/otp_verification': (context) {
          final Map<String, dynamic>? args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final String email = args?['email'] ?? ''; // ✅ Retrieve email from arguments

          return OtpVerificationScreen(email: email); // ✅ Pass email
        },
        '/complete_profile': (context) => CompleteProfileScreen(),
        '/home': (context) => HomePage(),
        '/products': (context) => ProductsListScreen(),

      },
    );
  }
}
