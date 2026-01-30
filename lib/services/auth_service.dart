import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 认证服务 - 封装 Firebase Auth 操作
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 当前用户
  User? get currentUser => _auth.currentUser;

  /// 用户状态流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 邮箱密码注册
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 更新用户显示名称
    if (displayName != null && credential.user != null) {
      await credential.user!.updateDisplayName(displayName);
    }

    return credential;
  }

  /// 邮箱密码登录
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// 发送密码重置邮件
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 登出
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Google 登录
  Future<UserCredential?> signInWithGoogle() async {
    // 触发 Google 登录流程
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      // 用户取消了登录
      return null;
    }

    // 获取认证信息
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // 创建 Firebase 凭证
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 使用凭证登录 Firebase
    return await _auth.signInWithCredential(credential);
  }

  /// 删除账户
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  /// 更新用户资料
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
  }
}
