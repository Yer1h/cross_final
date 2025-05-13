import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllProductsPage extends StatelessWidget {
  const AllProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Products"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No products available"));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final bgColor = index % 2 == 0 ? Colors.white : const Color(0xFFF3F4F6);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: bgColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'No name',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Компания: ${data['company'] ?? '-'}'),
                        Text('Штрихкод: ${data['barcode'] ?? '-'}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Кол-во: ${data['quantity'] ?? 0}'),
                        const SizedBox(width: 16),
                        Text('Цена: ${data['wholesale_price'] ?? 0} ₸'),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
