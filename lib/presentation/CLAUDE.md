[根目录](../../CLAUDE.md) > **presentation**

# Presentation 模块 - 表示层

## 模块职责

负责用户界面的呈现和交互，包括：

- **页面 (Pages)**：完整的屏幕界面
- **组件 (Widgets)**：可复用的 UI 组件
- **路由 (Router)**：应用导航配置

---

## 入口与启动

- 路由配置入口：`router/app_router.dart`
- 由 `lib/app.dart` 的 `MaterialApp.router` 引用

---

## 目录结构

```
lib/presentation/
├── router/
│   └── app_router.dart       # go_router 路由配置
├── pages/
│   ├── auth/
│   │   ├── splash_page.dart  # 启动页
│   │   ├── login_page.dart   # 登录页
│   │   └── register_page.dart # 注册页
│   ├── home/
│   │   └── pet_room_page.dart # 宠物房间（主页）
│   ├── pet/
│   │   ├── pet_create_page.dart  # 创建宠物
│   │   ├── pet_detail_page.dart  # [待实现]
│   │   └── pet_wardrobe_page.dart # [待实现]
│   ├── community/            # [待实现]
│   ├── profile/              # [待实现]
│   └── memorial/             # [待实现]
└── widgets/
    ├── common/
    │   ├── app_button.dart   # 通用按钮
    │   └── app_text_field.dart # 通用输入框
    └── pet/
        └── pet_status_bar.dart # 宠物状态条
```

---

## 路由配置

### 路由路径常量

```dart
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String petRoom = '/pet-room';
  static const String petCreate = '/pet-create';
  static const String petDetail = '/pet/:id';
  static const String wardrobe = '/wardrobe';
  static const String community = '/community';
  static const String profile = '/profile';
  static const String memorial = '/memorial/:id';
}
```

### 路由 Provider

```dart
final appRouterProvider = Provider<GoRouter>((ref) => GoRouter(...));
```

---

## 关键依赖与配置

### 外部依赖

- `go_router` - 声明式路由
- `flutter_riverpod` - 状态管理

### 内部依赖

- `lib/core/theme/` - 主题配置
- `lib/providers/` - 状态 Provider

---

## 对外接口

### 路由导航

```dart
// 声明式导航
context.go(AppRoutes.login);
context.push(AppRoutes.petCreate);

// 带参数
context.go('/pet/$petId');
```

---

## 页面说明

| 页面 | 路径 | 状态 | 说明 |
|------|------|------|------|
| SplashPage | `/` | 已实现 | 启动页，检查登录状态 |
| LoginPage | `/login` | 已实现 | 邮箱密码登录 |
| RegisterPage | `/register` | 已实现 | 用户注册 |
| PetRoomPage | `/pet-room` | 已实现 | 宠物房间主页 |
| PetCreatePage | `/pet-create` | 已实现 | 创建新宠物 |

---

## 测试与质量

- 当前无 Widget 测试覆盖
- 建议添加：
  - 页面渲染测试
  - 用户交互测试
  - 路由导航测试

---

## 常见问题 (FAQ)

**Q: 如何添加新页面？**

A:
1. 在 `pages/` 下创建页面文件
2. 在 `app_router.dart` 添加路由定义
3. 在 `AppRoutes` 添加路径常量

**Q: 如何传递路由参数？**

A: 使用 `GoRouteData` 或 `state.extra` 传递参数。

---

## 相关文件清单

| 文件 | 用途 |
|------|------|
| `router/app_router.dart` | 路由配置 + 路径常量 |
| `pages/auth/splash_page.dart` | 启动页 |
| `pages/auth/login_page.dart` | 登录页 |
| `pages/auth/register_page.dart` | 注册页 |
| `pages/home/pet_room_page.dart` | 宠物房间主页 |
| `pages/pet/pet_create_page.dart` | 创建宠物页 |
| `widgets/common/app_button.dart` | 通用按钮组件 |
| `widgets/common/app_text_field.dart` | 通用输入框组件 |
| `widgets/pet/pet_status_bar.dart` | 宠物状态条组件 |

---

## 变更记录 (Changelog)

| 时间 | 变更内容 |
|------|----------|
| 2026-01-29 09:45:35 | 初始化模块文档 |
