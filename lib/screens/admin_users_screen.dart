import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({Key? key}) : super(key: key);

  void _toggleLockUser(BuildContext context, String docId, bool isCurrentlyLocked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCurrentlyLocked ? 'Xác nhận mở khóa' : 'Xác nhận khóa'),
        content: Text(isCurrentlyLocked 
          ? 'Bạn có chắc chắn muốn mở khóa người dùng này? Họ sẽ có thể đăng nhập lại.'
          : 'Bạn có chắc chắn muốn khóa người dùng này? Họ sẽ không thể đăng nhập.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('accounts').doc(docId).update({
                'isLocked': !isCurrentlyLocked,
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isCurrentlyLocked ? 'Đã mở khóa người dùng' : 'Đã khóa người dùng')
              ));
            },
            child: Text(isCurrentlyLocked ? 'Mở khóa' : 'Khóa', style: TextStyle(color: isCurrentlyLocked ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Người dùng', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF059AA6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Đã có lỗi xảy ra'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Chưa có người dùng nào.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isLocked = data['isLocked'] == true;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isLocked ? Colors.red : const Color(0xFF059AA6),
                    child: Icon(isLocked ? Icons.lock : Icons.person, color: Colors.white),
                  ),
                  title: Text(data['name'] ?? 'Không có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['email'] ?? 'Không có email'),
                  trailing: IconButton(
                    icon: Icon(isLocked ? Icons.lock_open : Icons.lock, color: isLocked ? Colors.green : Colors.red),
                    onPressed: () => _toggleLockUser(context, docs[index].id, isLocked),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
