import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';

class BusinessSetupScreen extends StatefulWidget {
  final String stallName;
  final String ownerName;
  final String phoneNumber;

  const BusinessSetupScreen({
    super.key,
    required this.stallName,
    required this.ownerName,
    required this.phoneNumber,
  });

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0A0E14);
  final Color fieldBg = const Color(0xFF111821);

  bool agreed = false;
  bool loading = false;

  final TextEditingController upiController = TextEditingController();

  @override
  void dispose() {
    upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Vendor Registration",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "STEP 3 OF 3",
              style: TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Business Setup",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            _infoTile("Stall Name", widget.stallName, Icons.store_outlined),
            const SizedBox(height: 20),
            _infoTile("Owner Name", widget.ownerName, Icons.person_outline),
            const SizedBox(height: 24),
            _buildTextInput(
              controller: upiController,
              label: "UPI ID for Payments",
              hint: "e.g. 9876543210@upi",
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 32),
            _buildTermsCheckbox(),
            const SizedBox(height: 40),
            _buildFinishButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: neonGreen, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
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
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => agreed = !agreed),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: agreed ? neonGreen : Colors.white24),
              color: agreed ? neonGreen : Colors.transparent,
            ),
            child: agreed ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: "I agree to the ",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              children: [
                TextSpan(text: "Merchant Terms & Conditions", style: TextStyle(color: neonGreen)),
                const TextSpan(text: " and understand the service commission fees."),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 0,
        ),
        onPressed: loading ? null : () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          if (!agreed || upiController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please complete all fields and agree to terms")),
            );
            return;
          }

          setState(() => loading = true);

          try {
            await FirebaseFirestore.instance.collection("vendors").doc(user.uid).set({
              "stallName": widget.stallName,
              "ownerName": widget.ownerName,
              "upiId": upiController.text.trim(),
              "phone": widget.phoneNumber, // Use the passed phone number
              "createdAt": FieldValue.serverTimestamp(),
            });

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error saving profile: $e")),
            );
          } finally {
            setState(() => loading = false);
          }
        },
        child: loading
            ? const CircularProgressIndicator(color: Colors.black)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Finish & Go to Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(width: 10),
                  Icon(Icons.rocket_launch_outlined, size: 20),
                ],
              ),
      ),
    );
  }
}
