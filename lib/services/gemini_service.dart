import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../helper/local_storage_service.dart';
import '../models/hotel_model.dart';
import '../models/trip_model.dart';
import '../services/api_service.dart';
import '../helper/trip_service.dart';

class GeminiService {
  static const String _apiKey = 'AQ.Ab8RN6KmNSoIVj0_A96rkoH6GJOtgIRezdCqB-8Hp7AJAjBmdw';
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<Map<String, dynamic>> getSmartChatResponse(List<Map<String, dynamic>> localMessages) async {
    final String userMessage = (localMessages.lastWhere((msg) => msg['sender'] == 'user', orElse: () => {'text': ''})['text'] ?? '').toString().trim();
    if (userMessage.isEmpty) return {"reply": "Xin chào! Tôi có thể giúp gì cho bạn hôm nay?", "action": "none"};

    try {
      final trips = await TripService().getTrips();
      final hotels = await ApiService.fetchHotels();

      // Lấy danh sách địa điểm của các tour đang chờ duyệt của người dùng hiện tại
      final userEmail = await LocalStorageService().getUserEmail();
      List<String> pendingLocations = [];
      if (userEmail != null && userEmail.isNotEmpty) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userEmail', isEqualTo: userEmail)
            .where('status', isEqualTo: 'Chờ duyệt')
            .get();
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          if (data['type'] == 'trip') {
            final tripName = data['tripName'];
            if (tripName != null) {
              try {
                final matchedTrip = trips.firstWhere((t) => t.name == tripName);
                if (matchedTrip.location.isNotEmpty) {
                  pendingLocations.add(matchedTrip.location);
                }
              } catch (_) {}
            }
          }
        }
      }

      final tripsJson = trips.map((t) => {'id': t.id, 'name': t.name, 'location': t.location, 'price': t.price, 'rating': t.rating}).toList();
      final hotelsJson = hotels.map((h) => {'id': h.id, 'name': h.name, 'address': h.address, 'price': h.pricePerNight, 'rating': h.rating}).toList();

      String contextText = '';
      if (pendingLocations.isNotEmpty) {
        final locs = pendingLocations.toSet().join(', ');
        contextText = '\nLƯU Ý QUAN TRỌNG: Người dùng hiện đang có các tour ĐÃ ĐẶT (đang chờ duyệt) tại các tỉnh/địa điểm: $locs. KHI người dùng yêu cầu "tham khảo" hoặc cần tìm khách sạn, BẠN PHẢI ƯU TIÊN tìm và hiển thị danh sách các khách sạn ở cùng các tỉnh/địa điểm đó.';
      }

      final prompt = '''
Bạn là AI Travel Assistant chuyên nghiệp của ứng dụng đặt tour và khách sạn.
Dưới đây là danh sách Tour (Trips) và Khách sạn (Hotels) hiện có trong hệ thống:
Trips: ${jsonEncode(tripsJson)}
Hotels: ${jsonEncode(hotelsJson)}

Người dùng vừa nhắn: "$userMessage"
$contextText

Nhiệm vụ của bạn:
1. Trả lời câu hỏi của người dùng một cách tự nhiên, lịch sự.
2. NẾU người dùng hỏi thông tin chi tiết về 1 tour hoặc 1 khách sạn cụ thể có trong danh sách, trả về action "show_item" (kèm "itemId" và "itemType").
3. NẾU người dùng cần THAM KHẢO hoặc HIỂN THỊ nhiều tour/khách sạn (ví dụ: gợi ý khách sạn cùng tỉnh, danh sách tour rẻ), trả về action "show_items" cùng mảng "itemIds" (danh sách các ID) và "itemType".
4. NẾU người dùng yêu cầu LƯU hoặc THÊM VÀO YÊU THÍCH, trả về action "add_favorite" và danh sách "itemIds".
5. Nếu không rơi vào các trường hợp trên, trả về action "none".

YÊU CẦU ĐỊNH DẠNG TRẢ VỀ DUY NHẤT LÀ JSON HỢP LỆ:
{
  "reply": "Câu trả lời của bạn",
  "action": "show_item" | "show_items" | "add_favorite" | "none",
  "itemId": "id của item nếu là show_item (hoặc null)",
  "itemType": "trip" hoặc "hotel" (hoặc null),
  "itemIds": ["id1", "id2"] (nếu là show_items hoặc add_favorite, ngược lại là null)
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      var text = response.text ?? '';
      
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final data = jsonDecode(text);
      return data;
    } catch (e) {
      print('AI Chat Error: \$e');
      return {
        "reply": "Xin lỗi, hiện tại hệ thống AI đang bảo trì hoặc có lỗi xảy ra. (\$e)",
        "action": "none"
      };
    }
  }

  Future<String> getChatResponse(List<Map<String, dynamic>> localMessages) async {
    final res = await getSmartChatResponse(localMessages);
    return res['reply'] ?? 'Xin lỗi, có lỗi xảy ra.';
  }
}
