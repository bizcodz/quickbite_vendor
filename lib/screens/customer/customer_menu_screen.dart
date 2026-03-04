import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum CustomerStage { menu, checkout, tracking }

class CustomerMenuScreen extends StatefulWidget {
  final String vendorId;
  const CustomerMenuScreen({super.key, required this.vendorId});

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  final Color accentOrange = const Color(0xFFE67E22);
  final Color darkBg = const Color(0xFF0F172A);

  CustomerStage stage = CustomerStage.menu;
  Map<String, Map<String, dynamic>> cart = {}; // itemId: {qty, name, price}
  String? activeOrderId;
  String selectedPaymentMethod = "UPI";
  final TextEditingController nameController = TextEditingController();

  double get totalAmount {
    double total = 0;
    cart.forEach((key, value) {
      total += (value['price'] * value['qty']);
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: stage == CustomerStage.menu,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (stage == CustomerStage.checkout) {
          setState(() => stage = CustomerStage.menu);
        }
      },
      child: Scaffold(
        backgroundColor: stage == CustomerStage.tracking ? darkBg : Colors.white,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (stage) {
      case CustomerStage.menu:
        return _buildMenuView();
      case CustomerStage.checkout:
        return _buildCheckoutView();
      case CustomerStage.tracking:
        return _buildTrackingView();
    }
  }

  // --- MENU VIEW ---
  Widget _buildMenuView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('vendors').doc(widget.vendorId).snapshots(),
      builder: (context, vendorSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('menu').where('vendorId', isEqualTo: widget.vendorId).snapshots(),
          builder: (context, menuSnap) {
            if (!vendorSnap.hasData || !menuSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
            }

            final vendorData = vendorSnap.data!.data() as Map<String, dynamic>?;
            final stallName = vendorData?['stallName'] ?? "StreetSync Stall";
            final items = menuSnap.data!.docs;

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          Container(
                            height: 200,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?q=80&w=800'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.8)],
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Welcome to $stallName", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                                const Text("Authentic South Indian Street Food", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                              child: const TextField(
                                decoration: InputDecoration(icon: Icon(Icons.search, color: Colors.grey), hintText: "Search for items...", border: InputBorder.none),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ["All Items", "Dosas", "Idlis", "Drinks"].map((cat) => _buildCategoryChip(cat, cat == "All Items")).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final doc = items[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return _buildMenuItem(doc.id, data);
                          },
                          childCount: items.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
                if (cart.isNotEmpty)
                  Positioned(
                    bottom: 24, left: 20, right: 20,
                    child: InkWell(
                      onTap: () => setState(() => stage = CustomerStage.checkout),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        decoration: BoxDecoration(
                          color: accentOrange,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: accentOrange.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${cart.length} ITEMS", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            const Text("View Cart", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("₹$totalAmount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? accentOrange : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildMenuItem(String id, Map<String, dynamic> data) {
    final bool inStock = data['inStock'] ?? true;
    final int qty = cart[id]?['qty'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 85, height: 85,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1668236543090-82eba5ee5976?q=80&w=200'), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text("₹${data['price']}", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          if (inStock)
            qty == 0
                ? InkWell(
              onTap: () => setState(() => cart[id] = {'qty': 1, 'name': data['name'], 'price': data['price']}),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: accentOrange.withOpacity(0.3))),
                child: Icon(Icons.add, color: accentOrange, size: 20),
              ),
            )
                : Row(
              children: [
                IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.grey[400], size: 24), onPressed: () => setState(() {
                  if (cart[id]!['qty'] > 1) cart[id]!['qty']--;
                  else cart.remove(id);
                })),
                Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: Icon(Icons.add_circle, color: accentOrange, size: 24), onPressed: () => setState(() => cart[id]!['qty']++)),
              ],
            )
          else
            const Text("OUT OF STOCK", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- CHECKOUT VIEW ---
  Widget _buildCheckoutView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20), onPressed: () => setState(() => stage = CustomerStage.menu)),
        title: const Text("Checkout", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ORDER SUMMARY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 20),
            ...cart.values.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Text("${item['qty']}x", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  Text("₹${item['price'] * item['qty']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("₹$totalAmount", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: accentOrange)),
              ],
            ),
            const SizedBox(height: 40),
            const Text("YOUR DETAILS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Your Name (Optional)",
                hintText: "E.g. Rahul",
                filled: true, fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            const Text("SELECT PAYMENT METHOD", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPaymentCard("UPI", Icons.qr_code_scanner)),
                const SizedBox(width: 16),
                Expanded(child: _buildPaymentCard("Cash", Icons.payments_outlined)),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 64,
              child: ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(backgroundColor: accentOrange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text("Place Order • ₹$totalAmount →", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(String method, IconData icon) {
    bool isSelected = selectedPaymentMethod == method;
    return InkWell(
      onTap: () => setState(() => selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? accentOrange : Colors.grey.withOpacity(0.2), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? accentOrange : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(method, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? accentOrange : Colors.grey)),
          ],
        ),
      ),
    );
  }

  // --- TRACKING VIEW ---
  Widget _buildTrackingView() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(activeOrderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const Center(child: Text("Order not found", style: TextStyle(color: Colors.white)));

        final String status = data['status'] ?? "received";
        final token = data['tokenNumber'] ?? "--";

        return Container(
          color: darkBg,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text("Order status updated: ${status.toUpperCase()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("YOUR TOKEN", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 2)),
                Text("#${token.toString().padLeft(3, '0')}", style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900)),
                const SizedBox(height: 40),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        _buildTimelineStep("Order Received", "Sent to vendor", true, status != "received"),
                        _buildTimelineStep("Preparing", "Chef is cooking your meal", status == "preparing", status == "ready" || status == "COMPLETED"),
                        _buildTimelineStep("Ready for Pickup", "Collect from stall", status == "ready", status == "COMPLETED"),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {}, icon: const Icon(Icons.phone), label: const Text("Call Vendor"),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {}, icon: const Icon(Icons.receipt_long), label: const Text("View Order Details"),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineStep(String title, String sub, bool isActive, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? const Color(0xFFF43F5E) : (isActive ? Colors.white : Colors.white10),
                  border: isActive ? Border.all(color: const Color(0xFFF43F5E), width: 4) : null,
                ),
                child: isDone ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              Container(width: 2, height: 40, color: Colors.white10),
            ],
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isActive || isDone ? Colors.white : Colors.white24, fontWeight: FontWeight.bold, fontSize: 18)),
              Text(sub, style: TextStyle(color: isActive || isDone ? Colors.white38 : Colors.white10, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final orderRef = await FirebaseFirestore.instance.collection('orders').add({
      'vendorId': widget.vendorId,
      'customerName': nameController.text.isEmpty ? "Customer" : nameController.text,
      'items': cart.values.toList(),
      'totalAmount': totalAmount,
      'status': 'received',
      'createdAt': FieldValue.serverTimestamp(),
      'paymentMethod': selectedPaymentMethod,
    });

    setState(() {
      activeOrderId = orderRef.id;
      stage = CustomerStage.tracking;
    });
  }
}