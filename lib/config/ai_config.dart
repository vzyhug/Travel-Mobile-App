class AiConfig {
  // IP 10.0.2.2 là địa chỉ IP đặc biệt để máy ảo Android Emulator kết nối với localhost của máy tính.
  // Nếu bạn chạy bằng máy ảo iOS hoặc thiết bị thật kết nối cùng Wifi, hãy đổi thành IP thực tế của máy tính
  // (ví dụ: 'http://192.168.1.x:5000/api/chat' với x là số IP máy tính của bạn).
  static const String backendUrl = 'http://10.0.2.2:5000/api/chat';
}
