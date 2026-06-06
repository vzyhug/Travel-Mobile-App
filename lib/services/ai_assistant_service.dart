import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiAssistantService {
  static const String _apiKey = 'AQ.Ab8RN6KmNSoIVj0_A96rkoH6GJOtgIRezdCqB-8Hp7AJAjBmdw';
  late final GenerativeModel _model;

  AiAssistantService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> analyzePotentialTrips(List<Map<String, dynamic>> allBookings) async {
    try {
      final tripBookings = allBookings.where((b) => b['type'] == 'trip').toList();
      final prompt = '''
Dựa vào lịch sử đơn đặt phòng/tour dưới đây (định dạng JSON), hãy phân tích và đưa ra 3 tour có tiềm năng nhất trong thời gian tới. 
Giải thích lý do ngắn gọn cho mỗi tour dựa trên số lượng đặt, doanh thu hoặc xu hướng. 
Định dạng câu trả lời bằng Markdown.

Dữ liệu đặt tour:
${jsonEncode(tripBookings)}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Không thể đưa ra đánh giá lúc này.';
    } catch (e) {
      return 'Lỗi khi phân tích bằng AI: $e';
    }
  }

  Future<String> analyzePotentialHotels(List<Map<String, dynamic>> allBookings) async {
    try {
      final hotelBookings = allBookings.where((b) => b['type'] == 'hotel').toList();
      final prompt = '''
Dựa vào lịch sử đơn đặt khách sạn dưới đây (định dạng JSON), hãy phân tích và đưa ra 3 khách sạn có tiềm năng kinh doanh tốt nhất. 
Giải thích lý do ngắn gọn cho mỗi khách sạn dựa trên số lượng đặt, doanh thu hoặc xu hướng. 
Định dạng câu trả lời bằng Markdown.

Dữ liệu đặt khách sạn:
${jsonEncode(hotelBookings)}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Không thể đưa ra đánh giá lúc này.';
    } catch (e) {
      return 'Lỗi khi phân tích bằng AI: $e';
    }
  }

  Future<List<Map<String, dynamic>>?> analyzeAllPendingReviews() async {
    try {
      final db = FirebaseFirestore.instance;
      final reviewsSnap = await db.collection('reviews').where('status', isEqualTo: 'pending').get();
      
      if (reviewsSnap.docs.isEmpty) {
        return []; // Trả về mảng rỗng nếu không có review
      }

      final reviewsData = reviewsSnap.docs.map((doc) => {'id': doc.id, 'content': doc.data()}).toList();

      final prompt = '''
Bạn là một AI kiểm duyệt nội dung đánh giá của khách hàng cho một ứng dụng du lịch.
Dưới đây là danh sách các đánh giá (reviews) đang chờ duyệt.
Yêu cầu:
1. Đọc nội dung từng đánh giá.
2. Phân loại xem đánh giá là "Positive" (Tích cực), "Negative" (Tiêu cực), hay "Neutral" (Bình thường).
3. Trả về một mảng JSON nghiêm ngặt (không có markdown formatting, chỉ raw JSON) có cấu trúc như sau:
[
  { "id": "id của bài đánh giá", "sentiment": "Positive" | "Negative" | "Neutral", "reason": "Lý do vì sao" }
]

Danh sách review:
${jsonEncode(reviewsData)}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '[]';
      
      String jsonStr = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      List<dynamic> evaluations = jsonDecode(jsonStr);

      // Gắn thêm data gốc (comment, userName) vào để UI hiển thị cho tiện
      List<Map<String, dynamic>> finalResult = [];
      for (var eval in evaluations) {
        String docId = eval['id'] ?? '';
        var originalDoc = reviewsData.firstWhere((element) => element['id'] == docId, orElse: () => {});
        if (originalDoc.isNotEmpty) {
          final docData = originalDoc['content'] as Map<String, dynamic>;
          finalResult.add({
            'id': docId,
            'sentiment': eval['sentiment'] ?? 'Neutral',
            'reason': eval['reason'] ?? '',
            'comment': docData['comment'] ?? '',
            'userName': docData['userName'] ?? 'Khách',
          });
        }
      }

      return finalResult;
    } catch (e) {
      print('Lỗi AI: $e');
      return null; // Null đại diện cho lỗi
    }
  }
}
