import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0A0E14);
  final Color cardBg = const Color(0xFF111821);
  
  String selectedFilter = "WEEKLY";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Sales Analytics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today_outlined, size: 20), onPressed: () {}),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('vendorId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'COMPLETED')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          double totalRevenue = 0;
          double upiTotal = 0;
          double cashTotal = 0;
          int upiOrders = 0;
          int cashOrders = 0;

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final amount = (data['totalAmount'] ?? 0).toDouble();
              final method = data['paymentMethod'] ?? 'UPI';

              totalRevenue += amount;
              if (method == 'UPI') {
                upiTotal += amount;
                upiOrders++;
              } else {
                cashTotal += amount;
                cashOrders++;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildTimeFilters(),
                const SizedBox(height: 40),
                Text("TOTAL REVENUE", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text("₹${totalRevenue.toStringAsFixed(0)}", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: neonGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text("+14.2% from last week", style: TextStyle(color: Color(0xFF22C55E), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
                _buildChartPlaceholder(),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Payment Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildPaymentCard("UPI PAYMENTS", "₹${upiTotal.toStringAsFixed(0)}", "$upiOrders orders", Icons.qr_code, Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPaymentCard("CASH PAYMENTS", "₹${cashTotal.toStringAsFixed(0)}", "$cashOrders orders", Icons.payments_outlined, neonGreen)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeFilters() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: GestureDetector(onTap: () => setState(() => selectedFilter = "DAILY"), child: _filterItem("DAILY", selectedFilter == "DAILY"))),
          Expanded(child: GestureDetector(onTap: () => setState(() => selectedFilter = "WEEKLY"), child: _filterItem("WEEKLY", selectedFilter == "WEEKLY"))),
          Expanded(child: GestureDetector(onTap: () => setState(() => selectedFilter = "MONTHLY"), child: _filterItem("MONTHLY", selectedFilter == "MONTHLY"))),
        ],
      ),
    );
  }

  Widget _filterItem(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: LineChartPainter(neonGreen),
      ),
    );
  }

  Widget _buildPaymentCard(String label, String amount, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final Color color;
  LineChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.1, size.height * 0.8, size.width * 0.2, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.1, size.width * 0.4, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width * 0.6, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.3, size.width * 0.8, size.height * 0.1);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.4, size.width, size.height * 0.3);

    canvas.drawPath(path, paint);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.2), Colors.transparent],
    );

    canvas.drawPath(fillPath, Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    
    final textStyle = TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold);
    final days = ["MON", "WED", "FRI", "SUN"];
    for(int i=0; i<days.length; i++){
      final textPainter = TextPainter(text: TextSpan(text: days[i], style: textStyle), textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width * (i/3.2), size.height + 10));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
