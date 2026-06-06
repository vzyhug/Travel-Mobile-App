import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class AdminHotelsScreen extends StatelessWidget {
  const AdminHotelsScreen({Key? key}) : super(key: key);

  void _deleteHotel(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa khách sạn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('hotels').doc(docId).delete();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa khách sạn')));
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHotelDialog(BuildContext context, {Map<String, dynamic>? data, String? docId}) {
    final isEdit = docId != null;
    final nameController = TextEditingController(text: data?['name'] ?? '');
    final priceController = TextEditingController(text: (data?['price'] ?? data?['pricePerNight'] ?? '').toString());
    final locationController = TextEditingController(text: data?['location'] ?? data?['address'] ?? '');
    final descController = TextEditingController(text: data?['description'] ?? '');
    String? currentImageUrl = data?['image'];
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickImage() async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              setState(() {
                selectedImage = File(pickedFile.path);
              });
            }
          }

          return AlertDialog(
            title: Text(isEdit ? 'Sửa khách sạn' : 'Thêm khách sạn'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên khách sạn')),
                  TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Giá (đ)'), keyboardType: TextInputType.number),
                  TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Địa chỉ')),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Chọn ảnh'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: selectedImage != null
                            ? const Text('Đã chọn ảnh mới', style: TextStyle(color: Colors.green))
                            : (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                                ? const Text('Đang dùng ảnh cũ', style: TextStyle(color: Colors.blue))
                                : const Text('Chưa có ảnh', style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                  if (isUploading) const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isUploading ? null : () => Navigator.pop(ctx), child: const Text('Hủy')),
              TextButton(
                onPressed: isUploading ? null : () async {
                  final name = nameController.text.trim();
                  final price = int.tryParse(priceController.text.trim()) ?? 0;
                  final location = locationController.text.trim();
                  final desc = descController.text.trim();

                  if (name.isEmpty) return;

                  setState(() => isUploading = true);

                  String? imageUrl = currentImageUrl;

                  try {
                    if (selectedImage != null) {
                      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(selectedImage!.path)}';
                      final ref = FirebaseStorage.instance.ref().child('hotels').child(fileName);
                      await ref.putFile(selectedImage!);
                      imageUrl = await ref.getDownloadURL();
                    }

                    final payload = {
                      'name': name,
                      'pricePerNight': price,
                      'price': price, // Cho tương thích
                      'image': imageUrl ?? '',
                      'location': location,
                      'address': location,
                      'description': desc,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (isEdit) {
                      await FirebaseFirestore.instance.collection('hotels').doc(docId).update(payload);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật')));
                    } else {
                      payload['createdAt'] = FieldValue.serverTimestamp();
                      await FirebaseFirestore.instance.collection('hotels').add(payload);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm mới')));
                    }
                    if (context.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    setState(() => isUploading = false);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Khách sạn', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF059AA6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hotels').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Đã có lỗi xảy ra'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Chưa có khách sạn nào.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['image'] ?? 'https://via.placeholder.com/150',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.hotel, size: 60),
                    ),
                  ),
                  title: Text(data['name'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['location'] ?? data['address'] ?? 'Không có địa chỉ'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showHotelDialog(context, data: data, docId: docs[index].id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteHotel(context, docs[index].id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHotelDialog(context),
        backgroundColor: const Color(0xFF059AA6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
