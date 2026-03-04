import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart'; // 🔥 Added for clean URLs
import 'screens/landing/landing_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/dashboard/menu_screen.dart';
import 'screens/dashboard/orders_screen.dart';
import 'screens/dashboard/sales_screen.dart';
import 'screens/dashboard/profile_screen.dart' as dashboard;
import 'screens/customer/customer_menu_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // 🔥 Removes the '#' from web URLs
  
  // 🔥 Initializing Firebase with Web Configuration
  await Firebase.initializeApp(
    options: kIsWeb ? const FirebaseOptions(
      apiKey: "AIzaSyCAvf3TD3AS3U37y3FwDBjACJGKzjH9r88",
      authDomain: "quickbite-vendor.firebaseapp.com",
      projectId: "quickbite-vendor",
      storageBucket: "quickbite-vendor.firebasestorage.app",
      messagingSenderId: "490491870103",
      appId: "1:490491870103:web:e6a30c8f876e70038e62d2",
    ) : null,
  );

  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StreetSync Vendor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E14),
        primaryColor: const Color(0xFF22C55E),
        fontFamily: 'Manrope',
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF161C27),
          selectedItemColor: Color(0xFF22C55E),
          unselectedItemColor: Color(0xFF94A3B8),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      onGenerateRoute: (settings) {
        // 🔥 Handle web routing for customer menu: /menu?vendorId=xyz
        if (settings.name != null && settings.name!.startsWith('/menu')) {
          final uri = Uri.parse(settings.name!);
          final vendorId = uri.queryParameters['vendorId'];
          
          if (vendorId != null) {
            return MaterialPageRoute(
              builder: (context) => CustomerMenuScreen(vendorId: vendorId),
            );
          }
        }
        return null;
      },
      home: LandingScreen(),
    );
  }
}

// --- MAIN NAVIGATION SHELL ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      const HomeScreen(),
      const MenuScreen(),
      const OrdersScreen(),
      const SalesScreen(),
      const dashboard.ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (value) => setState(() => index = value),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: "Menu"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Sales"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
