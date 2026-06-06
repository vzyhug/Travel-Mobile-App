import 'package:flutter/material.dart';
import 'package:travel_application/screens/explore_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:travel_application/screens/login_screen.dart';
import 'package:travel_application/screens/home_screen.dart';
import 'package:travel_application/screens/admin_screen.dart';
import 'package:travel_application/helper/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:travel_application/helper/security_config.dart';

// MitM (tan cong) & Phong thu
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // Ép toàn bộ request chạy qua IP của Laptop 2 (Thay IP mạng của bạn vào đây)
      ..findProxy = (uri) {
        return "PROXY 192.168.239.1:8080;";
      }
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) {
            if (SecurityConfig.isMitMDefenseEnabled) {
              // Phòng thủ: Từ chối chứng chỉ không hợp lệ
              print("🚨 [PHÒNG THỦ MitM] Từ chối chứng chỉ giả mạo từ \$host. Ngắt kết nối!");
              return false;
            } else {
              // Tấn công: Chấp nhận mọi chứng chỉ
              print("⚠️ [CẢNH BÁO MitM] Chấp nhận chứng chỉ giả mạo từ \$host.");
              return true;
            }
          };
  }
}

void main() async {
  // MitM
  HttpOverrides.global = MyHttpOverrides();
  //
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();

  Widget initialScreen = const LoginScreen();

  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    final localStorageService = LocalStorageService();
    final userEmail = await localStorageService.getUserEmail();
    final userRole = await localStorageService.getUserRole();

    if (currentUser != null || (userEmail != null && userEmail.isNotEmpty)) {
      if (userRole == 'admin' || userEmail == 'admin@gmail.com') {
        initialScreen = const AdminScreen();
      } else {
        initialScreen = const HomeScreen();
      }
    }
  } catch (e) {
    debugPrint("Lỗi kiểm tra trạng thái đăng nhập: $e");
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: initialScreen);
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
