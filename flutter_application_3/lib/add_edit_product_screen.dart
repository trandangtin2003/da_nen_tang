import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddEditProductScreen extends StatefulWidget {
  final DocumentSnapshot? product;

  AddEditProductScreen({this.product});

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _category = '';
  double _price = 0;
  File? _image;
  String? _existingImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _name = widget.product!['name'];
      _category = widget.product!['category'];
      _price = widget.product!['price'];
      _existingImageUrl = widget.product!['imageUrl'];
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() {
        _isSaving = true;
      });
      _formKey.currentState!.save();
      String? imageUrl = _existingImageUrl;
      try {
        if (_image != null) {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference ref = FirebaseStorage.instance.ref().child('product_images/$fileName');
          await ref.putFile(_image!);
          imageUrl = await ref.getDownloadURL();

          if (_existingImageUrl != null) {
            await FirebaseStorage.instance.refFromURL(_existingImageUrl!).delete();
          }
        }

        Map<String, dynamic> productData = {
          'name': _name,
          'category': _category,
          'price': _price,
          'imageUrl': imageUrl,
        };

        if (widget.product == null) {
          await FirebaseFirestore.instance.collection('products').add(productData);
        } else {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.product!.id)
              .update(productData);
        }

        Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (e) {
        print('Error saving product: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: InputDecoration(
                labelText: 'Tên sản phẩm',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
              onSaved: (value) => _name = value!,
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: 'Loại sản phẩm',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Vui lòng nhập loại sản phẩm' : null,
              onSaved: (value) => _category = value!,
            ),
            SizedBox(height: 16),
            TextFormField(
              initialValue: _price.toString(),
              decoration: InputDecoration(
                labelText: 'Giá',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value!.isEmpty ? 'Vui lòng nhập giá' : null,
              onSaved: (value) => _price = double.parse(value!),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _getImage,
              icon: Icon(Icons.image),
              label: Text('Chọn ảnh'),
            ),
            SizedBox(height: 16),
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover)
            else if (_existingImageUrl != null)
              Image.network(_existingImageUrl!, height: 200, fit: BoxFit.cover),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProduct,
              child: _isSaving
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Lưu'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}