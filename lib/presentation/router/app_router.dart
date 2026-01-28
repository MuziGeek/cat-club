import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/auth/splash_page.dart';
import '../../presentation/pages/home/pet_room_page.dart';
import '../../presentation/pages/pet/pet_create_page.dart';

/// 路由路径常量
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String petRoom = '/pet-room';
  static const String petCreate = '/pet-create';
  static const String petDetail = '/pet/:id';
  static const String wardrobe = '/wardrobe';
  static const String community = '/community';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String memorial = '/memorial/:id';
}

/// 应用路由配置 Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // 启动页
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // 登录页
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),

      // 注册页
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),

      // 宠物房间（主页）
      GoRoute(
        path: AppRoutes.petRoom,
        builder: (context, state) => const PetRoomPage(),
      ),

      // 创建宠物
      GoRoute(
        path: AppRoutes.petCreate,
        builder: (context, state) => const PetCreatePage(),
      ),

      // TODO: 添加更多路由
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('页面未找到: ${state.uri}'),
      ),
    ),
  );
});
