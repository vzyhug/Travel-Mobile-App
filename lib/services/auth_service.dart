import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Đăng nhập bằng Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Bước 1: Xác thực người dùng (thay thế signIn cũ)
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();
      if (googleUser == null) return null;

      // Bước 2: Lấy accessToken qua authorizationClient (QUAN TRỌNG)
      const List<String> scopes = ['email', 'profile'];
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(
        scopes,
      );

      // Bước 3: Lấy idToken từ authentication (accessToken lấy từ clientAuth)
      final googleAuth = await googleUser.authentication;

      // Bước 4: Tạo credential cho Firebase
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: clientAuth.accessToken, //  accessToken hợp lệ
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      return null;
    }
  }

  // Đăng nhập bằng Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Kích hoạt luồng đăng nhập Facebook
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        // Tạo credential mới cho Firebase
        final OAuthCredential credential = FacebookAuthProvider.credential(
          result.accessToken!.tokenString,
        );

        // Đăng nhập vào Firebase
        return await _auth.signInWithCredential(credential);
      } else {
        print('Trạng thái đăng nhập Facebook: ${result.status}');
        print('Lỗi: ${result.message}');
        return null;
      }
    } catch (e) {
      print('Lỗi đăng nhập Facebook: $e');
      return null;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }
}

//
// extension on GoogleSignInAuthentication {
//   String? get accessToken => null;
// }
