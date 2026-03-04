import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'business_setup_screen.dart';
import '../../main.dart';

class OtpVerificationScreen extends StatefulWidget {
  final bool isSignup;
  final String stallName;
  final String ownerName;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.isSignup,
    required this.stallName,
    required this.ownerName,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0A0E14);
  final Color fieldBg = const Color(0xFF111821);
  final Color textMuted = const Color(0xFF94A3B8);

  bool loading = false;
  final List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  String getOtp() => controllers.map((e) => e.text).join();

  Future<void> _verify() async {
    String otp = getOtp();
    if (otp.length < 6) return;

    setState(() => loading = true);

    try {
      final res = await AuthService.verifyOtp(otp);

      if (res != null) {
        final user = FirebaseAuth.instance.currentUser!;

        if (widget.isSignup) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessSetupScreen(
                stallName: widget.stallName,
                ownerName: widget.ownerName,
                phoneNumber: widget.phoneNumber,
              ),
            ),
          );
        } else {
          // Check for existing vendor by phone number
          final query = await FirebaseFirestore.instance
              .collection("vendors")
              .where("phone", isEqualTo: widget.phoneNumber)
              .get();

          if (query.docs.isNotEmpty) {
            final oldDoc = query.docs.first;
            final oldData = oldDoc.data();
            
            // Migration: If the old profile is under a different UID (common in anonymous auth),
            // move the data to the current UID so the app works seamlessly.
            if (oldDoc.id != user.uid) {
              await FirebaseFirestore.instance
                  .collection("vendors")
                  .doc(user.uid)
                  .set(oldData);
            }

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (r) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account not found. Please register.")),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification failed: $e")),
      );
    }

    setState(() => loading = false);
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
        title: const Text("OTP Verification", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                Text("STEP 2 OF 3", style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold)),
                Text("Next: Final Step", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            const Text("Verify Your Number", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.66,
                child: Container(decoration: BoxDecoration(color: neonGreen, borderRadius: BorderRadius.circular(2))),
              ),
            ),
            const SizedBox(height: 40),
            const Text("Check your SMS", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("We've sent a 6-digit code to ${widget.phoneNumber}", style: TextStyle(color: textMuted, fontSize: 14)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOtpBox(index)),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text("Didn't receive the code?", style: TextStyle(color: textMuted, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text("Resend Code in 0:54", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: loading ? null : _verify,
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
                          Text("Verify & Continue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_outline),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(
                  text: TextSpan(
                    text: "Wrong phone number? ",
                    style: TextStyle(color: textMuted),
                    children: [
                      TextSpan(text: "Edit Number", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
          if (getOtp().length == 6) {
            _verify();
          }
        },
      ),
    );
  }
}
