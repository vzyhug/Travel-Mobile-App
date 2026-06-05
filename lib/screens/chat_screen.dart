import 'package:flutter/material.dart';
import '../helper/navigation_helper.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'saved_trips_screen.dart';
import 'profile_screen.dart';
import '../services/gemini_service.dart';

const Color tealColor = Color(0xFF059AA6);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final int selectedBottomIndex = 2;

  // State for active thread detail view
  Map<String, dynamic>? activeThread;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    activeThread = threads.firstWhere(
      (t) => t['id'] == 't2',
      orElse: () => threads[1],
    );
  }

  List<Map<String, dynamic>> threads = [
    {
      "id": "t1",
      "name": "Elena (Tour Guide)",
      "avatar":
          "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=150&q=80",
      "status": "Online",
      "role": "Hướng dẫn viên địa phương",
      "lastMessage":
          "Hôm nay thời tiết ở Sa Pa rất đẹp để đi leo núi Fansipan đó bạn!",
      "time": "10:42 AM",
      "messages": [
        {
          "sender": "other",
          "text": "Xin chào! Mình là Elena, hướng dẫn viên du lịch của bạn.",
        },
        {
          "sender": "other",
          "text":
              "Hôm nay thời tiết ở Sa Pa rất đẹp để đi leo núi Fansipan đó bạn! Bạn cần mình tư vấn lịch trình chi tiết không?",
        },
      ],
    },
    {
      "id": "t2",
      "name": "AI Travel Assistant",
      "avatar":
          "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=150&q=80",
      "status": "Active",
      "role": "Hỗ trợ thông minh 24/7",
      "lastMessage":
          "Tôi có thể gợi ý các địa điểm ăn uống đặc sản tốt nhất tại Đà Nẵng.",
      "time": "Hôm qua",
      "messages": [
        {
          "sender": "other",
          "text":
              "Xin chào! Tôi là trợ lý ảo AI. Tôi có thể giúp bạn lập kế hoạch, tìm khách sạn và khám phá các món ăn đặc sản tại Việt Nam!",
        },
        {
          "sender": "user",
          "text": "Chào bạn, hãy gợi ý cho mình địa điểm du lịch đẹp.",
        },
        {
          "sender": "other",
          "text":
              "Tuyệt vời! Nếu bạn thích leo núi săn mây, tôi khuyên bạn nên đi Sa Pa hoặc Đà Lạt. Nếu thích biển xanh cát trắng, Phú Quốc và Nha Trang là sự lựa chọn số một đó!",
        },
      ],
    },
    {
      "id": "t3",
      "name": "John (Support Desk)",
      "avatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80",
      "status": "Away",
      "role": "Chăm sóc khách hàng",
      "lastMessage": "Yêu cầu hoàn trả đặt phòng của bạn đang được xử lý.",
      "time": "2 ngày trước",
      "messages": [
        {
          "sender": "other",
          "text":
              "Chào bạn, mình là John hỗ trợ kỹ thuật và thanh toán của TravelApp.",
        },
        {
          "sender": "user",
          "text":
              "Mình vừa thanh toán thành công chuyển khoản nhưng muốn đổi ngày đi có được không?",
        },
        {
          "sender": "other",
          "text":
              "Dạ hoàn toàn được ạ. Yêu cầu hoàn trả đặt phòng cũ hoặc đổi lịch trình đang được xử lý. Bạn đợi mình kiểm tra trong 5 phút nhé.",
        },
      ],
    },
  ];

  bool isTyping = false;

  void selectThread(Map<String, dynamic> thread) {
    setState(() {
      activeThread = thread;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || activeThread == null) return;

    setState(() {
      activeThread!['messages'].add({"sender": "user", "text": text});
      activeThread!['lastMessage'] = text;
      activeThread!['time'] = "Vừa xong";
      _messageController.clear();
      isTyping = true;
    });

    _scrollToBottom();

    String reply = "";
    final name = activeThread!['name'];

    try {
      if (name.contains("AI")) {
        // Sao chép lịch sử để truyền ngữ cảnh cho Gemini
        final localMessages = List<Map<String, dynamic>>.from(
          activeThread!['messages'],
        );
        reply = await GeminiService().getChatResponse(localMessages);
      } else {
        // Đợi 2 giây để giả lập người thật trả lời
        await Future.delayed(const Duration(seconds: 2));
        if (name.contains("Elena")) {
          reply =
              "Cảm ơn bạn đã nhắn tin cho Elena! Mình đang dẫn đoàn trekking bản Cát Cát một lát, mình sẽ tư vấn chi tiết lịch trình du lịch cho bạn ngay nhé! 🌲✨";
        } else {
          reply =
              "Cảm ơn bạn. Bộ phận CSKH đã xác nhận thông tin. Chúng tôi sẽ cập nhật trạng thái đặt phòng của bạn trong mục Booked Tours trong giây lát.";
        }
      }
    } catch (e) {
      reply = "Có lỗi xảy ra trong quá trình nhận phản hồi: $e";
    }

    if (!mounted || activeThread == null) return;

    setState(() {
      activeThread!['messages'].add({"sender": "other", "text": reply});
      activeThread!['lastMessage'] = reply;
      isTyping = false;
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildChatAppBar(),
      body: _buildChatWindow(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildChatAppBar() {
    return AppBar(
      elevation: 1,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(activeThread!['avatar']),
            radius: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activeThread!['name'],
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  activeThread!['status'],
                  style: TextStyle(
                    color:
                        activeThread!['status'] == "Online" ||
                            activeThread!['status'] == "Active"
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadList() {
    return Column(
      children: [
        // Quick search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search chats, guides...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // Active Guides List (Avatars horizontal)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tour Guides Active',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final t = threads[index];
                    return GestureDetector(
                      onTap: () => selectThread(t),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: NetworkImage(t['avatar']),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color:
                                        t['status'] == "Online" ||
                                            t['status'] == "Active"
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t['name'].split(' ')[0],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 20, thickness: 1),

        // Threads list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            itemBuilder: (context, index) {
              final thread = threads[index];
              return InkWell(
                onTap: () => selectThread(thread),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(thread['avatar']),
                        radius: 26,
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
                                  thread['name'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  thread['time'],
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              thread['role'],
                              style: const TextStyle(
                                color: tealColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              thread['lastMessage'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatWindow() {
    final messages = activeThread!['messages'] as List<dynamic>;

    return Column(
      children: [
        // Role Info Banner
        Container(
          width: double.infinity,
          color: tealColor.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            'Bạn đang trò chuyện với ${activeThread!['role']}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: tealColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Message bubbles list
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['sender'] == 'user';

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? tealColor : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Typing indicator
        if (isTyping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    '${activeThread!['name'].split(' ')[0]} đang gõ...',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: tealColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: tealColor),
                onPressed: () {},
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: tealColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final icons = [
      Icons.home,
      Icons.location_on,
      Icons.chat_bubble,
      Icons.favorite,
      Icons.person,
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (index) {
          final selected = selectedBottomIndex == index;

          return GestureDetector(
            onTap: () {
              if (selected) return;

              if (index == 0) {
                navigateToTab(context, const HomeScreen());
              } else if (index == 1) {
                navigateToTab(context, const ExploreScreen());
              } else if (index == 3) {
                navigateToTab(context, const SavedTripsScreen());
              } else if (index == 4) {
                navigateToTab(context, const ProfileScreen());
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[index],
                  color: selected ? tealColor : Colors.grey,
                  size: 27,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? tealColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
