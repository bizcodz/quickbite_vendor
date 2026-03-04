import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../landing/landing_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0A0E14);
  final Color cardBg = const Color(0xFF111821);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LandingScreen()),
      (route) => false,
    );
  }

  Future<void> _downloadQr(BuildContext context, String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final path = "${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png";
      
      await Dio().download(url, path);
      
      await Gal.putImage(path);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ QR Code saved to Gallery")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to download: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileHeader(user.uid),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSettingsCard(
                        icon: Icons.store_rounded,
                        title: "Business Details",
                        subtitle: "Stall name, category, and bio",
                        onTap: () {},
                      ),
                      _buildSettingsCard(
                        icon: Icons.qr_code_2_rounded,
                        title: "QR Code & Printing",
                        subtitle: "View, share and download your menu QR",
                        onTap: () => _showQrModal(context, user.uid),
                      ),
                      _buildSettingsCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: "Payment Settings",
                        subtitle: "UPI ID and Bank info",
                        onTap: () {},
                      ),
                      _buildSettingsCard(
                        icon: Icons.help_outline_rounded,
                        title: "Help & Support",
                        subtitle: "FAQs and contact us",
                        onTap: () {},
                      ),
                      const SizedBox(height: 24),
                      _buildLogoutButton(context),
                      const SizedBox(height: 16),
                      Text(
                        "VERSION 1.0.2",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final stallName = data?['stallName'] ?? "Vendor";
        final phone = data?['phone'] ?? "";

        return Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: neonGreen.withOpacity(0.1),
              child: Icon(Icons.person, color: neonGreen, size: 40),
            ),
            const SizedBox(height: 16),
            Text(stallName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(phone, style: TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        );
      },
    );
  }

  void _showQrModal(BuildContext context, String uid) {
    // 🔥 UPDATED URL TO MATCH YOUR FIREBASE PROJECT
    final menuUrl = "https://quickbite-vendor.web.app/menu?vendorId=$uid";
    final qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=500x500&data=$menuUrl&color=000000&bgcolor=ffffff";
    
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 32),
                    const Text("Store Menu QR", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Customers can scan this to order live", style: TextStyle(color: Colors.white38, fontSize: 14)),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Image.network(
                        qrUrl,
                        height: 180,
                        width: 180,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Share.share("Scan to view our menu and order live: $menuUrl");
                            },
                            icon: const Icon(Icons.share),
                            label: const Text("Share Link"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () => _downloadQr(context, qrUrl),
                            icon: const Icon(Icons.download, color: Colors.white),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        label: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
