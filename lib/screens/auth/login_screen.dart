import 'package:flutter/material.dart';
import '../../main.dart';
import 'signup_screen.dart';
import '../../services/auth_service.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = true;
  final TextEditingController phoneController = TextEditingController();

  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0A0E14);
  final Color fieldBg = const Color(0xFF111821);
  final Color textMuted = const Color(0xFF94A3B8);

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _buildStallIcon(),
            const SizedBox(height: 32),
            const Text(
              "Welcome back",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Access your stall dashboard and manage live orders.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: textMuted),
            ),
            const SizedBox(height: 48),
            _buildMobileInputLabel(),
            const SizedBox(height: 8),
            _buildPhoneField(),
            const SizedBox(height: 20),
            _buildOptionsRow(),
            const SizedBox(height: 32),
            _buildVerifyButton(),
            const SizedBox(height: 60),
            _buildRegisterSection(),
            const SizedBox(height: 40),
            _buildFooterLinks(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: const Text(
        "Vendor Portal",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  Widget _buildStallIcon() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: neonGreen.withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 10,
                )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: neonGreen.withOpacity(0.1),
              border: Border.all(color: neonGreen.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(Icons.storefront, color: neonGreen, size: 42),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInputLabel() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "Mobile Number",
        style: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text("+91", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
              ],
            ),
          ),
          Container(width: 1.5, height: 28, color: Colors.white.withOpacity(0.1)),
          Expanded(
            child: TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 1.5),
              decoration: const InputDecoration(
                hintText: "000 000 0000",
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 44,
              child: Switch(
                value: rememberMe,
                activeColor: neonGreen,
                activeTrackColor: neonGreen.withOpacity(0.3),
                inactiveThumbColor: textMuted,
                onChanged: (val) => setState(() => rememberMe = val),
              ),
            ),
            const SizedBox(width: 8),
            Text("Remember Me", style: TextStyle(color: textMuted, fontSize: 14)),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text(
              "Trouble signing in?",
              style: TextStyle(color: neonGreen, fontWeight: FontWeight.w600, fontSize: 14)
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: Colors.black,
          elevation: 8,
          shadowColor: neonGreen.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onPressed: loading ? null : () async {
          String phoneNum = phoneController.text.trim();
          String fullPhone = "+91$phoneNum";

          if (phoneNum.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Enter mobile number")),
            );
            return;
          }

          setState(() => loading = true);

          await AuthService.sendOtp(
            phone: fullPhone,
            onCodeSent: () {
              setState(() => loading = false);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpVerificationScreen(
                    isSignup: false,
                    stallName: "",
                    ownerName: "",
                    phoneNumber: fullPhone,
                  ),
                ),
              );
            },
            onError: (error) {
              setState(() => loading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error)),
              );
            },
          );
        },

        child: loading 
          ? const CircularProgressIndicator(color: Colors.black)
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Verify with OTP", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward, size: 22),
              ],
            ),
      ),
    );
  }

  Widget _buildRegisterSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "NEW TO THE PLATFORM?",
                style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.05))),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: neonGreen.withOpacity(0.3), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VendorSignUpScreen()),
              );
            },
            child: Text(
                "Register as Vendor",
                style: TextStyle(color: neonGreen, fontWeight: FontWeight.w800, fontSize: 16)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        Text("By signing in, you agree to our ", style: TextStyle(color: textMuted, fontSize: 12)),
        InkWell(
          onTap: () {},
          child: const Text(
              "Terms of Service",
              style: TextStyle(color: Colors.white, fontSize: 12, decoration: TextDecoration.underline, fontWeight: FontWeight.w600)
          ),
        ),
        Text(" and ", style: TextStyle(color: textMuted, fontSize: 12)),
        InkWell(
          onTap: () {},
          child: const Text(
              "Privacy Policy",
              style: TextStyle(color: Colors.white, fontSize: 12, decoration: TextDecoration.underline, fontWeight: FontWeight.w600)
          ),
        ),
      ],
    );
  }
}
