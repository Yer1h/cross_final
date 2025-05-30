import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:invent_app_redesign/providers/theme_provider.dart';

class Product {
  final String name;
  final int quantity;
  final String? id;
  final String? company;
  final String? barcode;
  final double? price;

  Product({
    required this.name,
    required this.quantity,
    this.id,
    this.company,
    this.barcode,
    this.price,
  });
}

class LowStockPage extends StatefulWidget {
  final List<Product> allProducts;
  final int lowStockThreshold;

  const LowStockPage({
    Key? key,
    required this.allProducts,
    this.lowStockThreshold = 5,
  }) : super(key: key);

  @override
  _LowStockPageState createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  List<Product> lowStockItems = [];
  bool _isLoading = true;
  bool _syncError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLowStockItems();
  }

  Future<void> _loadLowStockItems() async {
    setState(() {
      _isLoading = true;
      _syncError = false;
      _errorMessage = '';
    });

    try {
      print('Attempting to fetch products from Firestore...');
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('quantity', isGreaterThanOrEqualTo: 0)
          .where('quantity', isLessThanOrEqualTo: widget.lowStockThreshold)
          .get();

      print('Firestore fetch successful. Docs retrieved: ${snapshot.docs.length}');

      // Update Hive cache, excluding Timestamp
      final box = Hive.box('products');
      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data()); // Convert to Map<String, dynamic>
        data['id'] = doc.id;
        data['isSynced'] = true;
        data.remove('timestamp'); // Remove Timestamp to avoid Hive error
        await box.put(doc.id, data);
        print('Cached product in Hive: ${doc.id} - ${data['name']}');
      }

      // Get low stock products directly from Firestore result
      final lowStockProducts = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final quantity = (data['quantity'] is int)
            ? data['quantity']
            : int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
        final price = (data['wholesale_price'] is double)
            ? data['wholesale_price']
            : double.tryParse(data['wholesale_price']?.toString() ?? '0') ?? 0;

        return Product(
          id: doc.id,
          name: data['name']?.toString() ?? 'Unnamed',
          quantity: quantity,
          company: data['company']?.toString(),
          barcode: data['barcode']?.toString(),
          price: price,
        );
      }).toList();

      // Sort by quantity ascending
      lowStockProducts.sort((a, b) => a.quantity.compareTo(b.quantity));

      setState(() {
        lowStockItems = lowStockProducts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error syncing products: $e');
      setState(() {
        _syncError = true;
        _errorMessage = e.toString();
      });

      // Fallback to Hive cache if Firestore fails
      final box = Hive.box('products');
      print('Falling back to Hive. Total cached items: ${box.length}');
      final cachedProducts = box.values.map((p) {
        try {
          final data = p as Map<dynamic, dynamic>;
          final quantity = (data['quantity'] is int)
              ? data['quantity']
              : int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
          final price = (data['wholesale_price'] is double)
              ? data['wholesale_price']
              : double.tryParse(data['wholesale_price']?.toString() ?? '0') ?? 0;

          return Product(
            id: data['id']?.toString(),
            name: data['name']?.toString() ?? 'Unnamed',
            quantity: quantity,
            company: data['company']?.toString(),
            barcode: data['barcode']?.toString(),
            price: price,
          );
        } catch (e) {
          print('Error mapping Hive data to Product: $e');
          return null;
        }
      }).where((p) => p != null).cast<Product>().toList();

      setState(() {
        lowStockItems = cachedProducts
            .where((p) => p.quantity <= widget.lowStockThreshold && p.quantity >= 0)
            .toList()
          ..sort((a, b) => a.quantity.compareTo(b.quantity));
        _isLoading = false;
      });

      // If cache is empty, ensure UI reflects this
      if (lowStockItems.isEmpty && box.isEmpty) {
        setState(() {
          _syncError = true;
          _errorMessage = 'No cached data available';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeName == 'dark';

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text("Low Stock Items"),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDarkMode ? Colors.white : Colors.deepPurple,
            ),
            onPressed: _loadLowStockItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(isDarkMode),
      ),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDarkMode ? Colors.deepPurple[200] : Colors.deepPurple,
        ),
      );
    }

    if (_syncError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to load data",
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Unknown error occurred',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              lowStockItems.isEmpty ? "No cached data available" : "Showing cached data",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLowStockItems,
              child: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    if (lowStockItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              "All items are sufficiently stocked",
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Low stock threshold: ${widget.lowStockThreshold} units",
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lowStockItems.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final product = lowStockItems[index];
        final percentage = (product.quantity / widget.lowStockThreshold * 100).clamp(0, 100).toInt();

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning,
              color: Colors.red,
            ),
          ),
          title: Text(
            product.name,
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
                'Stock: ${product.quantity} units (${percentage}% of threshold)',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: product.quantity / widget.lowStockThreshold,
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                color: product.quantity == 0
                    ? Colors.red
                    : product.quantity <= widget.lowStockThreshold / 2
                    ? Colors.orange
                    : Colors.yellow,
              ),
            ],
          ),
          trailing: Text(
            '${product.price?.toStringAsFixed(2) ?? '0.00'} ₸',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        );
      },
    );
  }
}