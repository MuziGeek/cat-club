import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/cloudbase_auth_http_service.dart';
import '../pages/auth/auth_page.dart';
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
  static const String auth = '/auth';
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

  // 兼容性别名（逐步废弃）
  @Deprecated('使用 auth 替代')
  static const String login = '/auth';
  @Deprecated('使用 auth 替代')
  static const String register = '/auth';
}

/// 认证页面白名单（无需登录即可访问）
const _authWhitelist = [
  AppRoutes.splash,
  AppRoutes.auth,
];

/// GoRouter 刷新流 - 监听认证状态变化
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<CloudbaseAuthState?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<CloudbaseAuthState?> _subscription;

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
      final authService = ref.read(authServiceProvider);
      final currentPath = state.matchedLocation;

      // 使用同步方式检查登录状态，不依赖流状态
      final isAuthenticated = authService.isSignedIn;
      final isAuthPage = _authWhitelist.contains(currentPath);

      // 未登录用户访问需要认证的页面 -> 重定向到认证页
      if (!isAuthenticated && !isAuthPage) {
        return AppRoutes.auth;
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

      // 统一认证页（登录/注册一体化）
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthPage(),
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
