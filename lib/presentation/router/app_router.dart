import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/splash_page.dart';
import '../pages/community/community_page.dart';
import '../pages/home/pet_room_page.dart';
import '../pages/main/main_shell_page.dart';
import '../pages/pet/pet_create_page.dart';
import '../pages/profile/achievement_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/settings_page.dart';
import '../pages/shop/shop_page.dart';

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
  static const String shop = '/shop';
  static const String achievements = '/achievements';
  static const String community = '/community';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String memorial = '/memorial/:id';
}

/// 认证页面白名单（无需登录即可访问）
const _authWhitelist = [
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
];

/// GoRouter 刷新流 - 监听认证状态变化
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<User?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// 应用路由配置 Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final refreshListenable = GoRouterRefreshStream(authService.authStateChanges);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshListenable,

    // 路由重定向逻辑
    redirect: (context, state) {
      final authStatus = ref.read(authStatusProvider);
      final currentPath = state.matchedLocation;

      // 初始化中，停留在 splash
      if (authStatus == AuthStatus.initial) {
        return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuthenticated = authStatus == AuthStatus.authenticated;
      final isAuthPage = _authWhitelist.contains(currentPath);

      // 未登录用户访问需要认证的页面 -> 重定向到登录页
      if (!isAuthenticated && !isAuthPage) {
        return AppRoutes.login;
      }

      // 已登录用户访问认证页面（非 splash）-> 重定向到主页
      if (isAuthenticated && isAuthPage && currentPath != AppRoutes.splash) {
        return AppRoutes.petRoom;
      }

      // 已登录用户在 splash 页 -> 重定向到主页
      if (isAuthenticated && currentPath == AppRoutes.splash) {
        return AppRoutes.petRoom;
      }

      return null;
    },

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

      // 主页面 Shell（底部导航）
      ShellRoute(
        builder: (context, state, child) => MainShellPage(child: child),
        routes: [
          // 宠物房间（主页）
          GoRoute(
            path: AppRoutes.petRoom,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PetRoomPage(),
            ),
          ),

          // 社区
          GoRoute(
            path: AppRoutes.community,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CommunityPage(),
            ),
          ),

          // 个人中心
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),

      // 创建宠物（独立页面，不在 Shell 内）
      GoRoute(
        path: AppRoutes.petCreate,
        builder: (context, state) => const PetCreatePage(),
      ),

      // 设置页面
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),

      // 商店页面
      GoRoute(
        path: AppRoutes.shop,
        builder: (context, state) => const ShopPage(),
      ),

      // 成就页面
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const AchievementPage(),
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('页面未找到: ${state.uri}'),
      ),
    ),
  );
});
