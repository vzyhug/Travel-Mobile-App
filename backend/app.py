import os
from flask import Flask, request, jsonify
from groq import Groq

app = Flask(__name__)

# API Key của Groq được điền trực tiếp để chạy thử nghiệm nhanh nhất
GROQ_API_KEY = "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"

# Khởi tạo Client kết nối với Groq
client = Groq(api_key=GROQ_API_KEY)

@app.route('/api/chat', methods=['POST'])
def chat_with_ai():
    try:
        # 1. Lấy dữ liệu tin nhắn từ Flutter gửi lên
        data = request.get_json()
        if not data or 'message' not in data:
            return jsonify({"error": "Không tìm thấy nội dung tin nhắn!"}), 400
        
        user_message = data['message']
        
        # 2. Gọi API của Groq để xử lý với mô hình llama-3.3-70b-specdec siêu mạnh
        completion = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                # System prompt cấu hình ngữ cảnh tư vấn du lịch phù hợp 100% với dự án TravelApp
                {
                    "role": "system", 
                    "content": "Bạn là trợ lý ảo thông minh chuyên tư vấn du lịch của ứng dụng TravelApp. Hãy trả lời thân thiện, ngắn gọn, lịch sự, hỗ trợ khách hàng giải đáp thắc mắc về các chuyến đi, khách sạn, điểm đến du lịch, hoặc hướng dẫn thanh toán VietQR trên app."
                },
                # Nội dung tin nhắn của người dùng
                {
                    "role": "user", 
                    "content": user_message
                }
            ],
            temperature=0.7, # Độ sáng tạo của câu trả lời (0.0 đến 1.0)
        )
        
        # 3. Trích xuất câu trả lời của AI
        ai_response = completion.choices[0].message.content
        
        # 4. Trả kết quả dạng JSON về cho Flutter App
        return jsonify({
            "status": "success",
            "response": ai_response
        }), 200

    except Exception as e:
        import traceback
        error_msg = f"Lỗi Python: {str(e)}\n{traceback.format_exc()}"
        print(error_msg)
        return jsonify({
            "status": "error",
            "message": error_msg
        }), 500

if __name__ == '__main__':
    # Chạy server ở port 5000 công khai để Flutter trong cùng mạng Wifi có thể gọi vào
    app.run(host='0.0.0.0', port=5000, debug=True)
