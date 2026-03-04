import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isStallOpen = true;

  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBlueCard = const Color(0xFF1D4ED8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatusToggle(),
              const SizedBox(height: 20),
              _buildTodaySummary(),
              const SizedBox(height: 20),
              Expanded(child: _buildLiveOrdersSection()),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    
    final uid = user.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vendors')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final stallName = data?['stallName'] ?? "Vendor";

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white10,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back,",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13),
                    ),
                    Text(
                      stallName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            _buildNotificationIcon(),
          ],
        );
      },
    );
  }

  Widget _buildNotificationIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
      child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFF111821), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          Expanded(child: _statusButton("Open", isStallOpen, neonGreen)),
          Expanded(child: _statusButton("Closed", !isStallOpen, Colors.white24)),
        ],
      ),
    );
  }

  Widget _statusButton(String label, bool isActive, Color activeColor) {
    return GestureDetector(
      onTap: () => setState(() => isStallOpen = (label == "Open")),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isActive ? Border.all(color: activeColor.withOpacity(0.3)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? activeColor : Colors.white24),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox(height: 120);
    
    final uid = user.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: uid)
          .where('status', isEqualTo: 'COMPLETED') // 🔥 Only completed orders
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 120);
        }

        double totalEarnings = 0;
        int orderCount = snapshot.data!.docs.length;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalEarnings += (data['totalAmount'] ?? 0).toDouble();
        }

        final avgValue =
        orderCount == 0 ? 0 : totalEarnings / orderCount;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkBlueCard,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Earnings",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13),
                  ),
                  _buildLiveBadge(),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Text(
                    "₹${totalEarnings.toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  _SummaryStat(
                      label: "ORDERS",
                      value: orderCount.toString()),
                  _SummaryStat(
                      label: "AVG VALUE",
                      value:
                      "₹${avgValue.toStringAsFixed(2)}"),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: const Text("LIVE", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildLiveOrdersSection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: uid)
          .where('status', whereIn: ['received', 'paid', 'accepted', 'preparing', 'ready'])
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            color: Colors.white.withOpacity(0.02),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                child: Icon(Icons.restaurant, color: neonGreen.withOpacity(count > 0 ? 1.0 : 0.2), size: 36),
              ),
              const SizedBox(height: 16),
              Text(count > 0 ? "$count Active Orders" : "No live orders yet",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(count > 0 ? "Check the Orders tab to manage them." : "Keep the app open and stay online.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
            ],
          ),
        );
      }
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
