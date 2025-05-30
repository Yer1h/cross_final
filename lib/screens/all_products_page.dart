import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:invent_app_redesign/screens/product_detail_page.dart';
import 'package:invent_app_redesign/services/network_service.dart';
import 'package:provider/provider.dart';
import 'package:invent_app_redesign/providers/theme_provider.dart';

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<dynamic, dynamic>> _allProducts = [];
  List<Map<dynamic, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  bool _sortByDateDesc = true;

  final List<String> _categories = [
    'All', 'Electronics', 'Clothing', 'Books',
    'Home & Kitchen', 'Beauty', 'Toys', 'Sports',
    'Automotive', 'Groceries', 'Health', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadCachedProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cacheProducts(List<QueryDocumentSnapshot> products) async {
    final box = Hive.box('products');
    await box.clear();
    for (var product in products) {
      final data = product.data() as Map<String, dynamic>;
      data['id'] = product.id;
      data['isSynced'] = true;
      await box.put(product.id, data);
    }
  }

  Future<void> _loadCachedProducts() async {
    final box = Hive.box('products');
    final cached = box.values.cast<Map<dynamic, dynamic>>().toList();
    setState(() {
      _allProducts = cached;
      _applyFilters();
      _isLoading = false;
    });
  }

  Future<void> _syncDrafts(BuildContext context) async {
    if (!(await NetworkService.isOnline())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final draftBox = Hive.box('drafts');
    final productBox = Hive.box('products');
    for (var key in draftBox.keys) {
      final draft = draftBox.get(key) as Map<dynamic, dynamic>;
      if (!(draft['isSynced'] ?? false)) {
        try {
          final docRef = await FirebaseFirestore.instance.collection('products').add({
            'name': draft['name'],
            'company': draft['company'],
            'quantity': draft['quantity'],
            'wholesale_price': draft['wholesale_price'],
            'barcode': draft['barcode'],
            'category': draft['category'],
            'imageUrl': draft['imageUrl'],
            'timestamp': FieldValue.serverTimestamp(),
          });
          draft['id'] = docRef.id;
          draft['isSynced'] = true;
          await productBox.put(docRef.id, draft);
          await draftBox.delete(key);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync error: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Drafts synced successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    List<Map<dynamic, dynamic>> results = _allProducts.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final company = (product['company'] ?? '').toString().toLowerCase();
      final barcode = (product['barcode'] ?? '').toString().toLowerCase();
      final category = (product['category'] ?? 'Other').toString();

      final matchesSearch = name.contains(query) ||
          company.contains(query) ||
          barcode.contains(query);
      final matchesCategory = _selectedCategory == 'All' ||
          category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    results.sort((a, b) {
      final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
      return _sortByDateDesc ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });

    setState(() {
      _filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeName == 'dark';
    final themeData = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text("All Products"),
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sync,
                color: isDarkMode ? Colors.white : Colors.deepPurple),
            onPressed: () => _syncDrafts(context),
            tooltip: 'Sync drafts',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilterBar(isDarkMode),
            Expanded(
              child: _buildProductStream(isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => _applyFilters(),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.grey[400] : Colors.grey),
              filled: true,
              fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: isDarkMode ? Colors.grey[400] : Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
              )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    icon: Icon(Icons.arrow_drop_down,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  _sortByDateDesc ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isDarkMode ? Colors.white : Colors.deepPurple,
                ),
                tooltip: 'Sort by date',
                onPressed: () {
                  setState(() {
                    _sortByDateDesc = !_sortByDateDesc;
                    _applyFilters();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductStream(bool isDarkMode) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          _cacheProducts(docs);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final fetched = docs.map((d) => d.data() as Map<String, dynamic>).toList();
            setState(() {
              _allProducts = fetched;
              _applyFilters();
            });
          });

          return _buildProductList(_filteredProducts, isDarkMode);
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return _buildProductList(_filteredProducts, isDarkMode);
      },
    );
  }

  Widget _buildProductList(List<Map<dynamic, dynamic>> products, bool isDarkMode) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 60,
                color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No products found'
                  : 'No matching products',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 8, bottom: 16), // Added bottom padding
      itemCount: products.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      ),
      itemBuilder: (context, index) {
        final data = products[index];
        return _buildProductItem(data, isDarkMode);
      },
    );
  }

  Widget _buildProductItem(Map<dynamic, dynamic> data, bool isDarkMode) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: isDarkMode ? Colors.grey[900] : Colors.white,
      leading: data['imageUrl'] != null
          ? CircleAvatar(
        backgroundImage: NetworkImage(data['imageUrl']),
        radius: 24,
      )
          : CircleAvatar(
        backgroundColor: isDarkMode ? Colors.deepPurple[800] : Colors.deepPurple[100],
        radius: 24,
        child: Icon(Icons.inventory,
            color: isDarkMode ? Colors.deepPurple[200] : Colors.white),
      ),
      title: Text(
        data['name'] ?? 'Unnamed',
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
            '${data['company'] ?? '-'} • ${data['category'] ?? 'Other'}',
            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Chip(
                label: Text('Qty: ${data['quantity'] ?? 0}'),
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('${data['wholesale_price'] ?? 0} ₸'),
                backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right,
          color: isDarkMode ? Colors.grey[400] : Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: data),
          ),
        );
      },
    );
  }
}