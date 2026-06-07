import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const String apiKey = 'AQ.Ab8RN6KmNSoIVj0_A96rkoH6GJOtgIRezdCqB-8Hp7AJAjBmdw';
  final model = GenerativeModel(
    model: 'gemma-4-31b-it',
    apiKey: apiKey,
  );

  final reviewsData = [
    {
      "id": "review1",
      "content": {
        "comment": "Chuyến đi tuyệt vời, tôi rất thích!",
        "userName": "Nam"
      }
    },
    {
      "id": "review2",
      "content": {
        "comment": "Khách sạn quá tệ, phòng bẩn thỉu.",
        "userName": "Hoa"
      }
    }
  ];

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
\${jsonEncode(reviewsData)}
''';

  try {
    final response = await model.generateContent([Content.text(prompt)]);
    print('RAW RESPONSE:');
    print(response.text);

    String rawText = response.text ?? '[]';
    final RegExp regex = RegExp(r'\[.*\]', dotAll: true);
    final Match? match = regex.firstMatch(rawText);
    String jsonStr = match != null ? match.group(0)! : '[]';
    print('EXTRACTED JSON:');
    print(jsonStr);

    List<dynamic> evaluations = jsonDecode(jsonStr);
    print('PARSED SUCCESSFULLY: \$evaluations');
  } catch (e) {
    print('ERROR: \$e');
  }
}
