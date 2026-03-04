import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'otp_verification_screen.dart';

class VendorSignUpScreen extends StatefulWidget {
  const VendorSignUpScreen({super.key});

  @override
  State<VendorSignUpScreen> createState() => _VendorSignUpScreenState();
}

class _VendorSignUpScreenState extends State<VendorSignUpScreen> {
  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0A0E14);
  final Color fieldBg = const Color(0xFF111821);
  final Color textMuted = const Color(0xFF94A3B8);

  final TextEditingController stallController = TextEditingController();
  final TextEditingController ownerController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool loading = false;

  Future<void> _sendOtp() async {
    String stallName = stallController.text.trim();
    String ownerName = ownerController.text.trim();
    String phone = "+91${phoneController.text.trim()}";

    if (stallName.isEmpty || ownerName.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (phoneController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 10-digit number")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 🔥 FIX: Prevent multiple registrations for the same number
      final existingVendor = await FirebaseFirestore.instance
          .collection("vendors")
          .where("phone", isEqualTo: phone)
          .get();

      if (existingVendor.docs.isNotEmpty) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This number is already registered. Please Sign In.")),
        );
        return;
      }

      await AuthService.sendOtp(
        phone: phone,
        onCodeSent: () {
          setState(() => loading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                isSignup: true,
                stallName: stallName,
                ownerName: ownerName,
                phoneNumber: phone,
              ),
            ),
          );
        },
        onError: (msg) {
          setState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
      );
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Vendor Sign Up", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("STEP 1 OF 3", style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold)),
                Text("Next: Verification", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            const Text("Business Info", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.33,
                child: Container(decoration: BoxDecoration(color: neonGreen, borderRadius: BorderRadius.circular(2))),
              ),
            ),
            const SizedBox(height: 40),
            const Text("Create Vendor Account", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Join our street food community and start growing your business today.", style: TextStyle(color: textMuted, fontSize: 14)),
            const SizedBox(height: 32),
            _buildField("Stall / Business Name", "e.g. Sunny's Taco Stand", Icons.store_outlined, stallController),
            _buildField("Owner Name", "Enter your full legal name", Icons.person_outline, ownerController),
            _buildField("Mobile Number", "000 000 0000", Icons.phone_android_outlined, phoneController, isPhone: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: loading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Send OTP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text("By continuing, you agree to our ", style: TextStyle(color: textMuted, fontSize: 12)),
                  Text("Terms of Service", style: TextStyle(color: neonGreen, fontSize: 12)),
                  Text(" and ", style: TextStyle(color: textMuted, fontSize: 12)),
                  Text("Privacy Policy", style: TextStyle(color: neonGreen, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Already have an account? ", style: TextStyle(color: textMuted)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text("Sign In", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, IconData icon, TextEditingController controller, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                prefixIcon: isPhone 
                  ? Padding(
                      padding: const EdgeInsets.only(left: 20, right: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text("+91", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
                          const SizedBox(width: 10),
                          Container(width: 1, height: 24, color: Colors.white10),
                        ],
                      ),
                    )
                  : Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
