import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("История", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('history')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("История пуста."));
                  }

                  final historyItems = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: historyItems.length,
                    itemBuilder: (context, index) {
                      final item = historyItems[index];
                      final timestamp = item['timestamp'] as Timestamp?;
                      final date = timestamp != null
                          ? timestamp.toDate().toString()
                          : 'Без времени';

                      return ListTile(
                        leading: Icon(
                          item['action'] == 'Added'
                              ? Icons.add_circle
                              : Icons.remove_circle,
                          color: const Color(0xFF111827),
                        ),
                        title: Text(item['title'] ?? 'Без названия'),
                        subtitle: Text('${item['action']} в $date'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
