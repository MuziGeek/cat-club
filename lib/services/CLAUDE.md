[根目录](../../CLAUDE.md) > **services**

# Services 模块 - 服务层

## 模块职责

封装外部服务和复杂业务逻辑，包括：

- **认证服务**：Firebase Auth 封装
- **AI 生成服务**：Replicate API 调用（待实现）
- **通知服务**：推送通知（待实现）
- **分享服务**：社交分享（待实现）

---

## 入口与启动

服务由 Provider 层实例化和管理，无独立入口。

---

## 目录结构

```
lib/services/
├── auth_service.dart           # 认证服务（已实现）
├── ai_generation_service.dart  # AI 生成服务（待完善）
├── notification_service.dart   # [待实现]
├── analytics_service.dart      # [待实现]
└── share_service.dart          # [待实现]
```

---

## 服务详情

### AuthService - 认证服务

封装 Firebase Auth 操作：

```dart
class AuthService {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<UserCredential> registerWithEmail({...});
  Future<UserCredential> signInWithEmail({...});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
  Future<void> updateProfile({...});
}
```

### AiGenerationService - AI 生成服务

使用 Replicate API 生成宠物卡通形象：

```dart
class AiGenerationService {
  static const Map<String, String> styles = {
    'cute': '可爱风',
    'anime': '动漫风',
    'realistic': '写实风',
  };

  Future<List<String>> generateCartoonAvatars({...}); // 待实现
  Future<PetFeatures> extractFeatures(String imageUrl); // 待实现
}
```

**支持的风格**：
- `cute` - Q版可爱风格
- `anime` - 日系动漫风格
- `realistic` - 半写实风格

---

## 关键依赖与配置

### 外部依赖

- `firebase_auth` - Firebase 认证
- `dio` - HTTP 请求（AI 服务使用）

### 环境配置

AI 服务需要配置 Replicate API Key（待实现）。

---

## 对外接口

### 认证服务使用

```dart
// 通过 Provider 获取
final authService = ref.watch(authServiceProvider);

// 登录
await authService.signInWithEmail(
  email: 'user@example.com',
  password: 'password',
);

// 登出
await authService.signOut();
```

---

## 测试与质量

- 当前无测试覆盖
- 建议添加：
  - AuthService 单元测试（Mock FirebaseAuth）
  - AiGenerationService 集成测试

---

## 常见问题 (FAQ)

**Q: 如何实现 AI 生成功能？**

A: 需要：
1. 配置 Replicate API Key
2. 实现 `generateCartoonAvatars` 方法
3. 实现 GPT-4 Vision 特征提取

**Q: 登录失败如何处理？**

A: `signInWithEmail` 会抛出 `FirebaseAuthException`，在 Provider 层捕获并处理。

---

## 相关文件清单

| 文件 | 用途 | 状态 |
|------|------|------|
| `auth_service.dart` | Firebase 认证封装 | 已实现 |
| `ai_generation_service.dart` | AI 图像生成 | 待完善 |

---

## 变更记录 (Changelog)

| 时间 | 变更内容 |
|------|----------|
| 2026-01-29 09:45:35 | 初始化模块文档 |
