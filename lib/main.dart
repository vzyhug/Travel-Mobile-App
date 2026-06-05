import 'package:flutter/material.dart';
import 'package:travel_application/screens/explore_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:travel_application/screens/login_screen.dart';
import 'package:travel_application/screens/home_screen.dart';
import 'package:travel_application/helper/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize();

  Widget initialScreen = const LoginScreen();

  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    final localStorageService = LocalStorageService();
    final userEmail = await localStorageService.getUserEmail();

    if (currentUser != null || (userEmail != null && userEmail.isNotEmpty)) {
      initialScreen = const HomeScreen();
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
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen());
  }
}
