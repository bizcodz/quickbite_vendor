import 'package:flutter/material.dart';
import '../../main.dart';// Import main to access MainScreen
import '../auth/login_screen.dart';


class LandingScreen extends StatelessWidget {
  LandingScreen({super.key});

  final Color accentNeon = const Color(0xFF22C55E);
  final Color cardBg = const Color(0xFF161C27);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: accentNeon,
                  borderRadius: BorderRadius.circular(8)
              ),
              child: const Icon(Icons.storefront, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('StreetSync', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800, // Fixed the extrabold error
                          color: Colors.white,
                          height: 1.1
                      ),
                      children: [
                        const TextSpan(text: "Digitize Your Stall in "),
                        TextSpan(text: "60 Seconds.", style: TextStyle(color: accentNeon)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Professional tools for street food entrepreneurs. Accept UPI and track sales instantly.",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?q=80&w=800',
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            _buildQuickStats(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentNeon,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // This now correctly pushes the MainScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Get Started Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.5),
        border: Border.symmetric(horizontal: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Stat(val: "12k+", lab: "VENDORS"),
          _Stat(val: "0%", lab: "FEES"),
          _Stat(val: "24/7", lab: "SUPPORT"),
        ],
      ),
    );
  }
}

// Helper Widget for Stat Items
class _Stat extends StatelessWidget {
  final String val, lab;
  const _Stat({required this.val, required this.lab});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(lab, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }
}