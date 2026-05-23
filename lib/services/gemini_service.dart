import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class GeminiService {
  Future<String> getChatResponse(List<Map<String, dynamic>> localMessages) async {
    // 1. Tìm tin nhắn cuối cùng gửi lên của người dùng
    final lastUserMsg = localMessages.lastWhere(
      (msg) => msg['sender'] == 'user',
      orElse: () => {'text': ''},
    );
    final String userMessage = (lastUserMsg['text'] ?? '').toString().trim();

    if (userMessage.isEmpty) {
      return 'Xin chào! Tôi có thể giúp gì cho bạn hôm nay?';
    }

    try {
      // 2. Gửi request POST tới Python Flask Server
      final response = await http.post(
        Uri.parse(AiConfig.backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': userMessage,
        }),
      );

      // 3. Xử lý kết quả trả về
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return (data['response'] ?? '').toString().trim();
        } else {
          return data['message'] ?? 'Máy chủ AI báo lỗi không rõ nguyên nhân.';
        }
      } else {
        print('Backend Server Error: ${response.statusCode} - ${response.body}');
        try {
          final data = json.decode(response.body);
          if (data['message'] != null) {
            return 'Lỗi máy chủ AI (Mã lỗi: ${response.statusCode}).\nChi tiết:\n${data['message']}';
          }
        } catch (_) {}
        return 'Lỗi kết nối máy chủ AI (Mã lỗi: ${response.statusCode}).';
      }
    } catch (e) {
      print('Service Error: $e');
      return 'Không thể kết nối đến máy chủ Flask Backend.\n'
             '• Vui lòng chắc chắn rằng bạn đã chạy server Python bằng lệnh: python app.py\n'
             '• Nếu chạy trên máy thật, hãy kiểm tra và đổi IP trong file ai_config.dart trùng với IP máy tính.\n'
             '(Chi tiết lỗi: $e)';
    }
  }
}
