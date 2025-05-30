import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive/hive.dart';
import 'package:invent_app_redesign/screens/login_screen.dart' as login; // Alias for login_screen.dart
import 'package:invent_app_redesign/services/network_service.dart';
import 'package:provider/provider.dart';
import 'package:invent_app_redesign/providers/theme_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'Electronics', 'Clothing', 'Books', 'Home & Kitchen',
    'Beauty', 'Toys', 'Sports', 'Automotive',
    'Groceries', 'Health', 'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _companyController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!(await NetworkService.isOnline())) {
      _showSnackBar(
        'Image upload requires internet connection',
        Colors.orange,
      );
      return;
    }

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productData = _prepareProductData();

      if (!(await NetworkService.isOnline())) {
        await _saveAsDraft(productData);
        return;
      }

      final docRef = await _saveToFirestore(productData);
      await _updateLocalStorage(docRef.id, productData);
      await _logHistoryAction(productData['name'], productData['quantity']);

      _showSnackBar('Product added successfully', Colors.green);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _prepareProductData() {
    return {
      'name': _nameController.text.trim(),
      'company': _companyController.text.trim(),
      'category': _selectedCategory == 'Other'
          ? _customCategoryController.text.trim()
          : _selectedCategory ?? 'Other',
      'quantity': int.parse(_quantityController.text.trim()),
      'wholesale_price': double.tryParse(_priceController.text.trim()) ?? 0.0,
      'barcode': _barcodeController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _saveAsDraft(Map<String, dynamic> data) async {
    final box = Hive.box('drafts');
    await box.add({
      ...data,
      'isSynced': false,
      'type': 'product',
    });
    _showSnackBar('Saved as draft for offline sync', Colors.blue);
    if (mounted) Navigator.pop(context, true);
  }

  Future<DocumentReference> _saveToFirestore(Map<String, dynamic> data) async {
    return await FirebaseFirestore.instance.collection('products').add({
      ...data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateLocalStorage(String docId, Map<String, dynamic> data) async {
    final box = Hive.box('products');
    await box.put(docId, {
      ...data,
      'id': docId,
      'isSynced': true,
    });
  }

  Future<void> _logHistoryAction(String name, int quantity) async {
    await FirebaseFirestore.instance.collection('history').add({
      'title': name,
      'action': 'Added',
      'quantity': quantity,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeName == 'dark';
    final themeData = themeProvider.currentTheme;
    final primaryColor = themeData.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: themeData.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: themeData.appBarTheme.iconTheme,
      ),
      body: SafeArea(
        child: Container(
          color: themeData.scaffoldBackgroundColor,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0), // Add bottom padding
                  child: Column(
                    children: [
                      _buildImageSection(isDarkMode, primaryColor),
                      const SizedBox(height: 24),
                      _buildFormSection(isDarkMode, primaryColor, themeData),
                      const SizedBox(height: 32),
                      _buildSaveButton(primaryColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDarkMode, Color primaryColor) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor,
                width: 2,
              ),
            ),
            child: _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            )
                : Icon(
              Icons.add_a_photo,
              size: 40,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Product Image',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(bool isDarkMode, Color primaryColor, ThemeData themeData) {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Product Name *',
          icon: Icons.shopping_bag,
          themeData: themeData,
          validator: (value) => value?.isEmpty ?? true ? 'Required field' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _companyController,
          label: 'Company',
          icon: Icons.business,
          themeData: themeData,
        ),
        const SizedBox(height: 16),
        _buildCategoryDropdown(isDarkMode, primaryColor, themeData),
        if (_selectedCategory == 'Other') ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _customCategoryController,
            label: 'Custom Category',
            icon: Icons.category,
            themeData: themeData,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _quantityController,
                label: 'Quantity *',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                themeData: themeData,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required field';
                  if (int.tryParse(value!) == null) return 'Invalid number';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: _priceController,
                label: 'Price',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                themeData: themeData,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _barcodeController,
          label: 'Barcode',
          icon: Icons.qr_code,
          themeData: themeData,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData themeData,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: themeData.textTheme.bodyMedium,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: themeData.inputDecorationTheme.labelStyle,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        filled: true,
        fillColor: themeData.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeData.colorScheme.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeData.colorScheme.primary.withOpacity(0.7)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeData.colorScheme.error),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDarkMode, Color primaryColor, ThemeData themeData) {
    return Container(
      decoration: BoxDecoration(
        color: themeData.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            labelText: 'Category',
            labelStyle: themeData.inputDecorationTheme.labelStyle,
            border: InputBorder.none,
            prefixIcon: Icon(Icons.category, color: primaryColor),
          ),
          dropdownColor: themeData.cardColor,
          style: themeData.textTheme.bodyMedium,
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
          validator: (value) => value == null ? 'Please select a category' : null,
        ),
      ),
    );
  }

  Widget _buildSaveButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        )
            : const Text(
          'SAVE PRODUCT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}