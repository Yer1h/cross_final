import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:invent_app_redesign/providers/theme_provider.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeName == 'dark'; // Corrected theme access

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Operation History"),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('history')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: isDarkMode ? Colors.deepPurple[200] : Colors.deepPurple,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 60,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Error loading history",
                              style: TextStyle(
                                fontSize: 18,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 60,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Operation history is empty",
                              style: TextStyle(
                                fontSize: 18,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final historyItems = snapshot.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16), // Added bottom padding
                      itemCount: historyItems.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final item = historyItems[index];
                        final data = item.data() as Map<String, dynamic>;

                        final action = data['action']?.toString() ?? '';
                        final title = data['title']?.toString() ?? 'Untitled';
                        final quantity = data['quantity']?.toString() ?? '?';
                        final timestampRaw = data['timestamp'];
                        final timestamp = timestampRaw is Timestamp
                            ? timestampRaw.toDate()
                            : DateTime.tryParse(timestampRaw?.toString() ?? '');
                        final dateFormatted = timestamp != null
                            ? DateFormat('dd MMM yyyy, HH:mm').format(timestamp)
                            : 'No timestamp';

                        final isAddition = action.toLowerCase() == 'added';
                        final iconColor = isAddition ? Colors.green : Colors.red;
                        final actionText = isAddition ? 'Added' : 'Ordered';

                        return Container(
                          color: isDarkMode ? Colors.grey[900] : Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAddition ? Icons.add_circle : Icons.remove_circle,
                                color: iconColor,
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '$actionText: $quantity units',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateFormatted,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}