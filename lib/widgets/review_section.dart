import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';
import '../helper/local_storage_service.dart';

const Color tealColor = Color(0xFF059AA6);

class ReviewSection extends StatefulWidget {
  final String itemId;
  final String itemType;

  const ReviewSection({
    super.key,
    required this.itemId,
    required this.itemType,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  final LocalStorageService _localStorageService = LocalStorageService();
  String? currentUserEmail;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final email = await _localStorageService.getUserEmail();
    final name = await _localStorageService.getUserName();
    if (mounted) {
      setState(() {
        currentUserEmail = email;
        currentUserName = name;
      });
    }
  }

  void _showAddReviewSheet() {
    if (currentUserEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return;
    }

    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đánh giá trải nghiệm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 40,
                        icon: Icon(
                          index < selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Hãy chia sẻ cảm nhận của bạn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: tealColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final text = commentController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá')),
                          );
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context); // Close the sheet

                        final review = ReviewModel(
                          id: '',
                          itemId: widget.itemId,
                          itemType: widget.itemType,
                          userEmail: currentUserEmail!,
                          userName: currentUserName ?? 'Người dùng',
                          rating: selectedRating,
                          comment: text,
                          createdAt: DateTime.now(),
                          status: 'pending',
                        );

                        await FirebaseFirestore.instance
                            .collection('reviews')
                            .add(review.toJson());

                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Đánh giá của bạn đã được gửi và đang đợi admin kiểm duyệt!')),
                          );
                        }
                      },
                      child: const Text(
                        'Gửi Đánh Giá',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đánh giá',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddReviewSheet,
              icon: const Icon(Icons.edit_rounded, size: 16, color: tealColor),
              label: const Text(
                'Viết đánh giá',
                style: TextStyle(color: tealColor, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('itemId', isEqualTo: widget.itemId)
              .where('itemType', isEqualTo: widget.itemType)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: tealColor),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Lỗi khi tải đánh giá.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              );
            }

            final List<QueryDocumentSnapshot> rawDocs = snapshot.data?.docs.toList() ?? [];
            final docs = rawDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'approved';
            }).toList();

            docs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              final dateA = dataA['createdAt'] != null ? DateTime.tryParse(dataA['createdAt']) ?? DateTime.now() : DateTime.now();
              final dateB = dataB['createdAt'] != null ? DateTime.tryParse(dataB['createdAt']) ?? DateTime.now() : DateTime.now();
              return dateB.compareTo(dateA); // Descending
            });

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Chưa có đánh giá nào. Hãy là người đầu tiên!',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final reviewData = docs[index].data() as Map<String, dynamic>;
                final review = ReviewModel.fromJson(reviewData, docs[index].id);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: tealColor.withOpacity(0.15),
                      child: Text(
                        _getInitials(review.userName),
                        style: const TextStyle(
                          color: tealColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review.comment,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
