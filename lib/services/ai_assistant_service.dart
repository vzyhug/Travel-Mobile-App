import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiAssistantService {
  static const String _apiKey = 'AQ.Ab8RN6IsRY-q3q8glN8K-RY3DIuHy6aQrwf0TcuRjhENjLVYbA';
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
      String rawText = response.text ?? '[]';
      
      String jsonStr = '[]';
      if (rawText.contains('```json')) {
        int start = rawText.indexOf('```json') + 7;
        int end = rawText.indexOf('```', start);
        if (end != -1) jsonStr = rawText.substring(start, end).trim();
      } else {
        int startIndex = rawText.indexOf('[');
        int endIndex = rawText.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          jsonStr = rawText.substring(startIndex, endIndex + 1);
        }
      }

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
      throw Exception('Chi tiết lỗi AI: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> analyzeAllPendingBookings() async {
    try {
      final db = FirebaseFirestore.instance;
      final snaps = await db.collection('bookings').where('status', isEqualTo: 'Chờ duyệt').get();
      if (snaps.docs.isEmpty) return [];

      final dataList = snaps.docs.map((doc) => {'id': doc.id, 'content': doc.data()}).toList();

      final prompt = '''
Bạn là hệ thống kiểm duyệt đơn đặt phòng/tour tự động.
Dưới đây là danh sách các đơn "Chờ duyệt" (JSON).
Đánh giá từng đơn: nếu thông tin (tên, email, số lượng người, giá tiền) có vẻ hợp lý và là đơn thật, hãy đánh dấu là "Valid". Nếu là dữ liệu rác, spam, giả mạo, hoặc bất hợp lý, đánh dấu "Spam".
Trả về mảng JSON nghiêm ngặt:
[
  { "id": "id", "status": "Valid" | "Spam", "reason": "Lý do ngắn gọn" }
]
Danh sách:
${jsonEncode(dataList)}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      String rawText = response.text ?? '[]';
      String jsonStr = '[]';
      if (rawText.contains('```json')) {
        int start = rawText.indexOf('```json') + 7;
        int end = rawText.indexOf('```', start);
        if (end != -1) jsonStr = rawText.substring(start, end).trim();
      } else {
        int startIndex = rawText.indexOf('[');
        int endIndex = rawText.lastIndexOf(']');
        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          jsonStr = rawText.substring(startIndex, endIndex + 1);
        }
      }
      List<dynamic> evaluations = jsonDecode(jsonStr);

      List<Map<String, dynamic>> finalResult = [];
      for (var eval in evaluations) {
        String docId = eval['id'] ?? '';
        var originalDoc = dataList.firstWhere((e) => e['id'] == docId, orElse: () => {});
        if (originalDoc.isNotEmpty) {
          final d = originalDoc['content'] as Map<String, dynamic>;
          finalResult.add({
            'id': docId,
            'status': eval['status'] ?? 'Valid',
            'reason': eval['reason'] ?? '',
            'customerName': d['customerName'] ?? d['userEmail'] ?? 'Khách',
            'tripName': d['tripName'] ?? d['hotelName'] ?? 'Dịch vụ',
          });
        }
      }
      return finalResult;
    } catch (e) {
      print('Lỗi AI Booking: $e');
      throw Exception('Chi tiết lỗi AI: $e');
    }
  }
}
