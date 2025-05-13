import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController productQuantityController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController wholesalePriceController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('product_images/$fileName.jpg');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  Future<void> saveProduct() async {
    String productName = productNameController.text.trim();
    String company = companyController.text.trim();
    String barcode = barcodeController.text.trim();
    int productQuantity = int.tryParse(productQuantityController.text.trim()) ?? 0;
    double wholesalePrice = double.tryParse(wholesalePriceController.text.trim()) ?? 0.0;

    if (productName.isEmpty || productQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter correct data')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final timestamp = FieldValue.serverTimestamp();
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      // Добавляем товар в коллекцию 'products'
      await FirebaseFirestore.instance.collection('products').add({
        'name': productName,
        'company': company,
        'quantity': productQuantity,
        'wholesale_price': wholesalePrice,
        'barcode': barcode,
        'imageUrl': imageUrl,
        'timestamp': timestamp,
      });

      // Добавляем запись в историю
      await FirebaseFirestore.instance.collection('history').add({
        'title': productName,
        'action': 'Added',
        'timestamp': timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added')),
      );

      if (context.mounted) {
        Navigator.pop(context, true); // передаем true, чтобы родитель понял, что нужно обновиться
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error while adding: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: productNameController,
              decoration: const InputDecoration(labelText: 'Product name'),
            ),
            TextField(
              controller: companyController,
              decoration: const InputDecoration(labelText: 'Company'),
            ),
            TextField(
              controller: productQuantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Количество'),
            ),
            TextField(
              controller: wholesalePriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Wholesale price'),
            ),
            TextField(
              controller: barcodeController,
              decoration: const InputDecoration(labelText: 'Barcode'),
            ),
            const SizedBox(height: 20),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 150)
                : const Text('No image selected'),
            TextButton.icon(
              icon: const Icon(Icons.photo),
              label: const Text('Select photo'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : saveProduct,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
