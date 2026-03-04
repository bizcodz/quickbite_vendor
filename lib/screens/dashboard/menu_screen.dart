import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final Color neonGreen = const Color(0xFF22C55E);
  final Color darkBg = const Color(0xFF0A0E14);
  final Color cardBg = const Color(0xFF111821);
  
  String selectedCategory = "All Items";

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Menu Management", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildCategories(),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menu')
                  .where('vendorId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_menu, size: 64, color: Colors.white10),
                        const SizedBox(height: 16),
                        Text("No items in your menu", style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;
                if (selectedCategory != "All Items") {
                  docs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['category'] == selectedCategory).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return _buildMenuItem(
                      docId,
                      data['name'] ?? "",
                      (data['price'] ?? 0).toString(),
                      data['inStock'] ?? true,
                      data['category'] ?? "Main Course",
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(context, user.uid),
        backgroundColor: neonGreen,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }

  void _showItemDialog(BuildContext context, String vendorId, {String? docId, String? name, String? price, String? category}) {
    final nameController = TextEditingController(text: name);
    final priceController = TextEditingController(text: price);
    final categoryController = TextEditingController(text: category ?? "Main Course");
    
    bool isEditing = docId != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isEditing ? "Edit Item" : "Add New Item", style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "Item Name", hintStyle: TextStyle(color: Colors.white24)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "Price", hintStyle: TextStyle(color: Colors.white24)),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Category", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: ["Main Course", "Popular", "Sides", "Beverages"].contains(categoryController.text) ? categoryController.text : null,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      underline: const SizedBox(),
                      hint: Text(categoryController.text, style: const TextStyle(color: Colors.white)),
                      items: ["Main Course", "Popular", "Sides", "Beverages"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          categoryController.text = val!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: categoryController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "Or type custom category", hintStyle: TextStyle(color: Colors.white24)),
                  ),
                ],
              ),
            ),
            actions: [
              if (isEditing)
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('menu').doc(docId).delete();
                    Navigator.pop(context);
                  },
                  child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
                ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: neonGreen, foregroundColor: Colors.black),
                onPressed: () async {
                  if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                    final itemData = {
                      'vendorId': vendorId,
                      'name': nameController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'category': categoryController.text,
                      'inStock': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (isEditing) {
                      await FirebaseFirestore.instance.collection('menu').doc(docId).update(itemData);
                    } else {
                      itemData['createdAt'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance.collection('menu').add(itemData);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(isEditing ? "Update" : "Add"),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildCategories() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('menu')
          .where('vendorId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        List<String> categories = ["All Items"];
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final cat = (doc.data() as Map<String, dynamic>)['category'] as String?;
            if (cat != null && !categories.contains(cat)) {
              categories.add(cat);
            }
          }
        }
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: categories.map((cat) => _categoryChip(cat, selectedCategory == cat)).toList(),
          ),
        );
      },
    );
  }

  Widget _categoryChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? neonGreen : cardBg,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? null : Border.all(color: Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(String docId, String name, String price, bool inStock, String category) {
    return GestureDetector(
      onLongPress: () => _showItemDialog(context, FirebaseAuth.instance.currentUser!.uid, docId: docId, name: name, price: price, category: category),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: neonGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.restaurant, color: neonGreen),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text("₹$price", style: TextStyle(color: neonGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(category, style: TextStyle(color: Colors.white24, fontSize: 11)),
                  const SizedBox(height: 8),
                  Text(
                    inStock ? "IN STOCK" : "OUT OF STOCK",
                    style: TextStyle(
                      color: inStock ? Colors.white38 : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: inStock,
                  activeColor: neonGreen,
                  onChanged: (val) async {
                    await FirebaseFirestore.instance.collection('menu').doc(docId).update({'inStock': val});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white38),
                  onPressed: () => _showItemDialog(context, FirebaseAuth.instance.currentUser!.uid, docId: docId, name: name, price: price, category: category),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
