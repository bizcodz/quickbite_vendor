import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0A0E14);
  final Color cardBg = const Color(0xFF111821);
  
  bool showActive = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          _buildOnlineStatusIndicator(),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: showActive 
                ? FirebaseFirestore.instance
                    .collection('orders')
                    .where('vendorId', isEqualTo: user.uid)
                    .where('status', whereIn: ['received', 'paid', 'accepted', 'preparing', 'ready'])
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('orders')
                    .where('vendorId', isEqualTo: user.uid)
                    .where('status', whereIn: ['COMPLETED', 'REJECTED'])
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return _buildOrderCard(docId, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(showActive ? "No active orders" : "No order history", style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildOnlineStatusIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: neonGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: neonGreen, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          const Text("ON", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: GestureDetector(onTap: () => setState(() => showActive = true), child: _tabItem("ACTIVE", showActive))),
          Expanded(child: GestureDetector(onTap: () => setState(() => showActive = false), child: _tabItem("HISTORY", !showActive))),
        ],
      ),
    );
  }

  Widget _tabItem(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? "NEW";
    final items = (data['items'] as List?) ?? [];
    final total = (data['totalAmount'] ?? 0).toString();
    final time = data['createdAt'] != null 
        ? DateFormat('hh:mm a').format((data['createdAt'] as Timestamp).toDate())
        : "--:--";
    
    // 🔥 Check for Reminders
    final bool isReminded = data['remindVendor'] ?? false;

    Color statusColor = Colors.blue;
    String statusLabel = status;
    
    if (status == "received") {
      statusColor = Colors.blue;
      statusLabel = "NEW ORDER";
    } else if (status == "paid") {
      statusColor = Colors.amber;
      statusLabel = "PAID (WAITING)";
    } else if (status == "accepted") {
      statusColor = Colors.blue;
      statusLabel = "ACCEPTED";
    } else if (status == "preparing") {
      statusColor = Colors.orange;
      statusLabel = "PREPARING";
    } else if (status == "ready") {
      statusColor = neonGreen;
      statusLabel = "READY";
    } else if (status == "COMPLETED") {
      statusColor = Colors.white24;
    } else if (status == "REJECTED") {
      statusColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isReminded ? Colors.redAccent.withOpacity(0.5) : Colors.white.withOpacity(0.05), width: isReminded ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReminded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  const Text("CUSTOMER REMINDED YOU", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (data['tokenNumber'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text("TOKEN #${data['tokenNumber']}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
                    )
                  else
                    const Text("NEW ORDER", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 10)),
                  const SizedBox(width: 10),
                  Text(time, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(data['customerName'] ?? "Customer", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔥 FIXED: Handled field mismatch (quantity)
                Text("${item['quantity'] ?? item['qty']}x ${item['name']}", style: const TextStyle(color: Colors.white70)),
                Text("₹${item['price']}", style: const TextStyle(color: Colors.white60)),
              ],
            ),
          )),
          const Divider(height: 24, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("₹$total", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons(docId, status, data),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String docId, String status, Map<String, dynamic> data) {
    if (status == "received" || status == "paid") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _rejectOrder(docId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Reject"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _acceptOrder(docId, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Accept Order"),
            ),
          ),
        ],
      );
    } else if (status == "accepted") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(docId, "preparing"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Start Preparing"),
        ),
      );
    } else if (status == "preparing") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(docId, "ready"),
          style: ElevatedButton.styleFrom(
            backgroundColor: neonGreen,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Mark as Ready"),
        ),
      );
    } else if (status == "ready") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _updateStatus(docId, "COMPLETED"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("Order Picked Up / Complete"),
        ),
      );
    }
    return const SizedBox();
  }

  Future<void> _acceptOrder(String docId, Map<String, dynamic> data) async {
    final vendorId = FirebaseAuth.instance.currentUser!.uid;
    final metaRef = FirebaseFirestore.instance.collection('vendors').doc(vendorId).collection('meta').doc('settings');
    
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final metaSnapshot = await transaction.get(metaRef);
        int newToken = 1;
        
        if (metaSnapshot.exists) {
          newToken = (metaSnapshot.data()?['tokenCounter'] ?? 0) + 1;
        }
        
        transaction.set(metaRef, {'tokenCounter': newToken}, SetOptions(merge: true));
        transaction.update(FirebaseFirestore.instance.collection('orders').doc(docId), {
          'status': 'accepted',
          'tokenNumber': newToken,
          'acceptedAt': FieldValue.serverTimestamp(),
          'estimatedTime': 15,
          'remindVendor': false, // 🔥 Reset reminder when accepted
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error accepting order: $e")));
    }
  }

  void _rejectOrder(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': 'REJECTED'});
  }

  void _updateStatus(String docId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': status,
      'remindVendor': false, // 🔥 Reset reminder on any update
    });
  }
}
