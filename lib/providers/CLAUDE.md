[根目录](../../CLAUDE.md) > **providers**

# Providers 模块 - 状态管理

## 模块职责

使用 Riverpod 管理应用状态，包括：

- **认证状态**：用户登录/登出状态
- **宠物状态**：宠物数据和交互状态（待实现）
- **社区状态**：社区动态和互动（待实现）

---

## 入口与启动

由 `lib/main.dart` 的 `ProviderScope` 初始化。

---

## 目录结构

```
lib/providers/
├── auth_provider.dart      # 认证状态管理（已实现）
├── pet_provider.dart       # [待实现]
├── interaction_provider.dart # [待实现]
└── community_provider.dart # [待实现]
```

---

## Provider 详情

### 认证相关 Provider

```dart
// AuthService 实例
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// 用户状态流
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// 认证状态枚举
enum AuthStatus { initial, authenticated, unauthenticated }

final authStatusProvider = Provider<AuthStatus>((ref) {
  // 根据 authStateProvider 返回状态
});
```

### 登录 Notifier

```dart
class LoginNotifier extends StateNotifier<AsyncValue<void>> {
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  });
  void reset();
}

final loginProvider = StateNotifierProvider<LoginNotifier, AsyncValue<void>>(...);
```

### 注册 Notifier

```dart
class RegisterNotifier extends StateNotifier<AsyncValue<void>> {
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  });
  void reset();
}

final registerProvider = StateNotifierProvider<RegisterNotifier, AsyncValue<void>>(...);
```

---

## 关键依赖与配置

### 外部依赖

- `flutter_riverpod` - 状态管理框架
- `firebase_auth` - Firebase 用户类型

### 内部依赖

- `lib/services/auth_service.dart` - 认证服务

---

## 使用示例

### 监听认证状态

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);

    switch (authStatus) {
      case AuthStatus.authenticated:
        return HomePage();
      case AuthStatus.unauthenticated:
        return LoginPage();
      default:
        return SplashPage();
    }
  }
}
```

### 执行登录

```dart
final success = await ref.read(loginProvider.notifier).signInWithEmail(
  email: email,
  password: password,
);

if (success) {
  context.go(AppRoutes.petRoom);
}
```

---

## 测试与质量

- 当前无测试覆盖
- 建议添加：
  - Provider 单元测试
  - StateNotifier 状态变化测试

---

## 常见问题 (FAQ)

**Q: 如何在 Provider 中处理错误？**

A: 使用 `AsyncValue.error` 包装错误，在 UI 层通过 `.when()` 处理。

**Q: 如何添加新的 Provider？**

A: 遵循现有模式，使用 `StateNotifierProvider` 管理有状态逻辑。

---

## 相关文件清单

| 文件 | 用途 | 状态 |
|------|------|------|
| `auth_provider.dart` | 认证状态管理 | 已实现 |

---

## 变更记录 (Changelog)

| 时间 | 变更内容 |
|------|----------|
| 2026-01-29 09:45:35 | 初始化模块文档 |
