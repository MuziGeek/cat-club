[根目录](../../CLAUDE.md) > **services**

# Services 模块 - 服务层

## 模块职责

封装外部服务和复杂业务逻辑，包括：

- **认证服务**：CloudBase HTTP API Auth（主要）/ Firebase Auth（备用）
- **数据库服务**：CloudBase MySQL REST API
- **存储服务**：腾讯云 COS
- **AI 生成服务**：Replicate API 调用（待实现）
- **通知服务**：推送通知（待实现）

---

## 入口与启动

服务由 Provider 层实例化和管理，无独立入口。

---

## 目录结构

```
lib/services/
├── cloudbase_auth_http_service.dart  # CloudBase HTTP API 认证 ✅
├── cloudbase_service.dart            # CloudBase MySQL REST API ✅
├── storage_service.dart              # 腾讯云 COS 存储服务 ✅
├── auth_service.dart                 # Firebase Auth（备用）
├── firestore_service.dart            # Firestore（已废弃）
├── check_in_service.dart             # 签到服务
├── ai_generation_service.dart        # AI 生成服务（待完善）
└── share_service.dart                # [待实现]
```

---

## CloudBase 服务详情

### CloudbaseAuthHttpService - 认证服务 (推荐)

**文件**: `cloudbase_auth_http_service.dart`

使用 CloudBase HTTP API 进行认证：

```dart
class CloudbaseAuthHttpService {
  // 发送验证码
  Future<OtpResult> sendPhoneOtp(String phone);
  Future<OtpResult> sendEmailOtp(String email);

  // 验证码验证
  Future<String> verifyOtp({required String verificationId, required String code});

  // 登录方式
  Future<AuthState> signInWithVerificationToken(String token);
  Future<AuthState> signInWithPassword({String? email, String? phone, required String password});
  Future<AuthState> signInAnonymously();

  // Token 管理
  Future<AuthState> refreshToken();
  Future<void> signOut();
}
```

### CloudbaseService - 数据库服务

**文件**: `cloudbase_service.dart`

使用 CloudBase MySQL REST API：

```dart
class CloudbaseService {
  // 用户操作
  Future<Map<String, dynamic>?> getUser(String id);
  Future<void> createUser(Map<String, dynamic> data);
  Future<void> updateUser(String id, Map<String, dynamic> data);

  // 宠物操作
  Future<List<Map<String, dynamic>>> getUserPets(String userId);
  Future<void> createPet(Map<String, dynamic> data);
  Future<void> updatePet(String id, Map<String, dynamic> data);

  // 成就和统计
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId);
  Future<Map<String, dynamic>?> getUserStats(String userId);
}
```

**REST API 端点**: `/v1/rdb/rest/{table}`

**MySQL 表结构**:

| 表名 | 用途 |
|------|------|
| `users` | 用户信息（coins, diamonds, inventory 等）|
| `pets` | 宠物信息（status, stats 为 JSON 字段）|
| `user_achievements` | 成就进度 |
| `user_stats` | 用户统计（喂食、清洁、玩耍次数等）|

### StorageService - 存储服务

**文件**: `storage_service.dart`

使用腾讯云 COS：

```dart
class StorageService {
  Future<File?> pickImage(ImageSource source);
  Future<File?> cropImage(File imageFile);
  Future<String> uploadImage(File file, String path);
  Future<void> deleteImage(String url);
}
```

---

## Firebase 服务（备用/待迁移）

### AuthService - Firebase 认证

**文件**: `auth_service.dart`

> ⚠️ 建议使用 `CloudbaseAuthHttpService` 替代

```dart
class AuthService {
  User? get currentUser;
  Stream<User?> get authStateChanges;
  Future<UserCredential> signInWithEmail({...});
  Future<void> signOut();
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
}
```

---

## 关键依赖与配置

### 外部依赖

- `http` - HTTP 请求（CloudBase REST API）
- `firebase_auth` - Firebase 认证（备用）
- `dio` - HTTP 请求（AI 服务使用）
- `image_picker` - 图片选择
- `image_cropper` - 图片裁剪

### 环境配置

```dart
// lib/config/cloudbase_config.dart
envId: 'cat-hub-6gcp6yje9dd382c7'
apiBaseUrl: 'https://cat-hub-6gcp6yje9dd382c7.api.tcloudbasegateway.com'
```

---

## 对外接口

### CloudBase 认证服务使用（推荐）

```dart
// 通过 Provider 获取
final authService = ref.watch(cloudbaseAuthHttpServiceProvider);

// 手机验证码登录
final result = await authService.sendPhoneOtp('13800138000');
final token = await authService.verifyOtp(
  verificationId: result.verificationId,
  code: '123456',
);
await authService.signInWithVerificationToken(token);

// 登出
await authService.signOut();
```

### CloudBase 数据库服务使用

```dart
// 通过 Provider 获取
final dbService = ref.watch(cloudbaseServiceProvider);

// 查询用户
final user = await dbService.getUser(userId);

// 查询宠物列表
final pets = await dbService.getUserPets(userId);
```

### Firebase 认证服务使用（备用）

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
| `cloudbase_auth_http_service.dart` | CloudBase HTTP API 认证 | ✅ 已实现 |
| `cloudbase_service.dart` | CloudBase MySQL REST API | ✅ 已实现 |
| `storage_service.dart` | 腾讯云 COS 存储 | ✅ 已实现 |
| `auth_service.dart` | Firebase 认证（备用）| ⚠️ 待迁移 |
| `firestore_service.dart` | Firestore（已废弃）| ❌ 已废弃 |
| `ai_generation_service.dart` | AI 图像生成 | 🔧 待完善 |

---

## 变更记录 (Changelog)

| 时间 | 变更内容 |
|------|----------|
| 2026-02-06 | 更新文档：统一使用 MySQL 关系型数据库，添加 CloudBase 服务说明 |
| 2026-01-29 09:45:35 | 初始化模块文档 |
