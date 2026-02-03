# 开发进度记录

> 最后更新：2026-02-03 17:56

---

## 2026-02-03 开发日志（商店 + 签到 + 宠物放生）

### 概述

本次开发完成了**道具商店系统**、**每日签到系统**和**宠物放生功能**的完整实现，包括商店页面 UI、签到对话框、奖励发放逻辑、放生确认对话框等。同时完善了之前遗留的照片上传相关功能。

### 完成事项

#### Phase 1: 道具商店系统 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| ShopPage 商店页面 | 完整商店 UI，TabBar 分类（食物/道具/配饰） | ✅ |
| 货币栏显示 | 显示用户金币、钻石余额 | ✅ |
| 商品卡片 | 显示商品图标、名称、稀有度、价格 | ✅ |
| 商品详情弹窗 | 显示效果说明、购买按钮 | ✅ |
| 购买逻辑 | 扣除货币、添加道具到背包 | ✅ |
| ItemDefinitions 扩展 | 添加 `getItemsByCategory()` 方法 | ✅ |
| UserNotifier.purchaseItem | 购买道具扣款方法 | ✅ |

**新增文件：**
- `lib/presentation/pages/shop/shop_page.dart` - 商店页面（650行）

#### Phase 2: 每日签到系统 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| CheckInService | 签到服务，7天循环奖励配置 | ✅ |
| CheckInProvider | 签到状态管理 Notifier | ✅ |
| CheckInDialog | 签到对话框 UI，7天奖励展示 | ✅ |
| 奖励配置 | 金币递增 + 第7天大礼包（钻石+道具） | ✅ |
| 连续签到计算 | 支持断签重置、7天循环 | ✅ |
| Firestore 事务 | 原子更新签到数据和奖励 | ✅ |
| 调试重置功能 | 开发时重置签到状态 | ✅ |

**新增文件：**
- `lib/services/check_in_service.dart` - 签到服务（211行）
- `lib/providers/check_in_provider.dart` - 签到状态管理（157行）
- `lib/presentation/pages/home/check_in_dialog.dart` - 签到对话框（453行）

**奖励配置：**
| 天数 | 金币 | 钻石 | 道具 |
|------|------|------|------|
| 第1天 | 50 | - | - |
| 第2天 | 80 | - | - |
| 第3天 | 100 | - | 小鱼干 x2 |
| 第4天 | 120 | - | - |
| 第5天 | 150 | - | 猫零食 x2 |
| 第6天 | 180 | - | - |
| 第7天 | 300 | 10 | 高级鱼干 x1, 刷子 x1 |

#### Phase 3: 宠物放生功能 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| ReleaseConfirmDialog | 放生确认对话框，二次确认机制 | ✅ |
| 名称输入验证 | 需输入宠物名称才能确认 | ✅ |
| 宠物信息显示 | 显示头像、名称、等级、物种 | ✅ |
| PetProvider.releasePet | 放生宠物方法（删除 Firestore 数据） | ✅ |

**新增文件：**
- `lib/presentation/widgets/pet/release_confirm_dialog.dart` - 放生确认对话框（279行）

#### Phase 4: 路由与集成 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| 商店路由 | `/shop` 路由配置 | ✅ |
| PetRoomPage 签到入口 | 顶部栏添加签到按钮 | ✅ |
| ProfilePage 商店入口 | 个人中心添加商店入口 | ✅ |

### 新增/修改文件清单

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| 新建 | `lib/presentation/pages/shop/shop_page.dart` | 商店页面 |
| 新建 | `lib/services/check_in_service.dart` | 签到服务 |
| 新建 | `lib/providers/check_in_provider.dart` | 签到状态管理 |
| 新建 | `lib/presentation/pages/home/check_in_dialog.dart` | 签到对话框 |
| 新建 | `lib/presentation/widgets/pet/release_confirm_dialog.dart` | 放生确认对话框 |
| 新建 | `lib/presentation/widgets/pet/pet_selector.dart` | 宠物切换栏 |
| 新建 | `lib/data/models/item_definitions.dart` | 道具定义配置 |
| 新建 | `lib/services/storage_service.dart` | 存储服务 |
| 修改 | `lib/presentation/router/app_router.dart` | 添加商店路由 |
| 修改 | `lib/providers/user_provider.dart` | 添加 purchaseItem 方法 |
| 修改 | `lib/providers/inventory_provider.dart` | 完善背包逻辑 |
| 修改 | `lib/providers/pet_provider.dart` | 添加 releasePet 方法 |
| 修改 | `lib/services/firestore_service.dart` | 签到数据操作 |
| 修改 | `lib/services/ai_generation_service.dart` | AI 服务完善 |
| 修改 | `lib/presentation/pages/home/pet_room_page.dart` | 签到入口集成 |
| 修改 | `lib/presentation/pages/profile/profile_page.dart` | 商店入口 |

### 功能状态总结

| 功能 | 状态 | 说明 |
|------|------|------|
| 道具商店 | ✅ 完成 | 完整购买流程 |
| 商品分类 | ✅ 完成 | 食物/道具/配饰 三类 |
| 每日签到 | ✅ 完成 | 7天循环奖励 |
| 连续签到奖励 | ✅ 完成 | 递增金币 + 第7天大礼包 |
| 宠物放生 | ✅ 完成 | 二次确认机制 |
| 宠物切换 | ✅ 完成 | 多宠物管理 |

### 后续计划

| 优先级 | 任务 | 说明 |
|--------|------|------|
| P1 | Firebase Storage 启用 | 升级 Blaze 计划后启用照片上传 |
| P1 | Rive 动画升级 | 替换静态图标为动画 |
| P2 | 成就系统 | 解锁成就获取奖励 |
| P2 | 社区功能 | 动态发布、点赞评论 |
| P3 | AI 卡通形象生成 | Replicate API 集成 |

---

## 2026-02-03 开发日志（照片上传功能）

### 概述

本次开发完成了照片上传功能的**代码实现**，包括照片选择、裁剪、预览等完整 UI 流程。但由于 Firebase Storage 需要 Blaze 付费计划，照片上传到云端功能**暂时跳过**，待后续启用。

### 完成事项

#### Phase 1: Provider 层实现 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| PhotoUploadProvider | 照片上传状态管理（选择、裁剪、上传进度） | ✅ |
| StorageService Provider | 已存在于 `storage_service.dart` | ✅ |

**新增文件：**
- `lib/providers/photo_upload_provider.dart` - 照片上传状态管理

**PhotoUploadState 字段：**
```dart
@freezed
class PhotoUploadState {
  File? selectedFile;      // 选中的文件
  File? croppedFile;       // 裁剪后的文件
  bool isUploading;        // 是否正在上传
  double progress;         // 上传进度 (0.0 - 1.0)
  String? uploadedUrl;     // 上传后的 URL
  String? error;           // 错误信息
}
```

#### Phase 2: UI 组件实现 ✅

| 组件 | 文件 | 功能 |
|------|------|------|
| PhotoPickerSheet | `photo_picker_sheet.dart` | 照片来源选择底部弹窗（相机/相册） |
| PhotoPreviewDialog | `photo_preview_dialog.dart` | 照片预览确认对话框（含上传进度） |

**新增文件：**
- `lib/presentation/widgets/photo/photo_picker_sheet.dart`
- `lib/presentation/widgets/photo/photo_preview_dialog.dart`

#### Phase 3: 宠物创建流程集成 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| PetCreatePage 照片选择 | 点击"上传宠物照片"触发选择流程 | ✅ |
| 照片预览显示 | 选中后显示缩略图和清除按钮 | ✅ |
| 上传功能 | ⏸️ 暂时跳过（需 Firebase Blaze 计划） | ⏸️ |

#### Phase 4: 现有宠物照片更新 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| InteractivePetWidget 改造 | 支持显示真实照片、添加 onAvatarTap 回调 | ✅ |
| PetRoomPage 头像更新 | 长按宠物头像触发照片更新流程 | ✅ |
| PetInteractionNotifier.updatePetPhoto | 更新宠物照片方法 | ✅ |

#### Phase 5: 权限配置 ✅

| 平台 | 配置 | 状态 |
|------|------|------|
| Android | CAMERA, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE, READ_MEDIA_IMAGES | ✅ |
| Android | UCropActivity 声明 | ✅ |
| iOS | NSCameraUsageDescription, NSPhotoLibraryUsageDescription | ✅ |

### 新增/修改文件清单

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| 新建 | `lib/providers/photo_upload_provider.dart` | 照片上传状态管理 |
| 新建 | `lib/presentation/widgets/photo/photo_picker_sheet.dart` | 照片来源选择弹窗 |
| 新建 | `lib/presentation/widgets/photo/photo_preview_dialog.dart` | 照片预览对话框 |
| 修改 | `lib/presentation/pages/pet/pet_create_page.dart` | 集成照片选择功能 |
| 修改 | `lib/providers/pet_provider.dart` | 添加 updatePetPhoto 方法 |
| 修改 | `lib/presentation/widgets/pet/interactive_pet_widget.dart` | 支持照片显示和头像点击 |
| 修改 | `lib/presentation/pages/home/pet_room_page.dart` | 集成头像更新功能 |
| 修改 | `android/app/src/main/AndroidManifest.xml` | 相机/存储权限 + UCropActivity |
| 修改 | `ios/Runner/Info.plist` | 相机/相册权限说明 |

### 功能状态总结

| 功能 | 状态 | 说明 |
|------|------|------|
| 照片选择（相机） | ✅ 完成 | 调用系统相机拍照 |
| 照片选择（相册） | ✅ 完成 | 从相册选择图片 |
| 照片裁剪（1:1） | ✅ 完成 | UCrop 裁剪组件 |
| 照片预览 | ✅ 完成 | 显示裁剪后预览 |
| 照片清除/重选 | ✅ 完成 | 支持清除和重新选择 |
| 照片上传到 Storage | ⏸️ 暂停 | 需要 Firebase Blaze 计划 |
| 宠物创建（无照片） | ✅ 完成 | 使用预设形象创建 |
| 头像更新（长按） | ⏸️ 暂停 | UI 完成，上传需 Blaze |

### ⚠️ 重要说明：Firebase Storage 限制

#### 问题描述

Firebase Storage 需要启用 **Blaze 付费计划**（按需付费）才能使用。当前项目使用免费的 Spark 计划，无法使用 Storage 服务。

#### 错误信息

```
[firebase_storage/object-not-found] No object exists at the desired reference.
StorageException: Code: -13010 HttpResult: 404
```

#### 临时解决方案

在 `pet_create_page.dart` 中**暂时跳过照片上传**：
- 用户仍可选择和预览照片（完整 UI 体验）
- 创建宠物时提示"照片功能暂未开放"
- 宠物使用预设形象创建

#### 后续启用步骤

1. **升级 Firebase 计划**
   - 访问 [Firebase Console](https://console.firebase.google.com/project/cat-club-9b0cb)
   - 升级到 Blaze 计划（按需付费，有免费额度）

2. **启用 Storage 服务**
   - Build → Storage → Get Started
   - 选择 Storage 位置

3. **配置安全规则**
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

4. **取消代码注释**
   - 打开 `lib/presentation/pages/pet/pet_create_page.dart`
   - 找到 `_handleCreate()` 方法
   - 取消 `TODO: 启用 Blaze 计划后取消注释` 下方代码的注释
   - 恢复 `originalPhotoUrl: photoUrl` 参数

#### Firebase Storage 免费额度（Blaze 计划下）

| 项目 | 免费额度/月 |
|------|-------------|
| 存储空间 | 5 GB |
| 下载流量 | 1 GB/天 |
| 上传操作 | 50,000 次/天 |
| 下载操作 | 50,000 次/天 |

对于开发测试和小型应用**完全够用，不会产生费用**。

---

## 2026-02-02 开发日志（背包持久化 + 多宠物切换）

### 概述

本次开发完成了背包系统持久化和多宠物切换功能，将本地模拟背包升级为 Firestore 存储，并实现了用户多宠物管理的 UI 组件。共完成 8 个开发任务。

### 完成事项

#### Phase 1: 状态衰减同步优化 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| 添加状态衰减同步公开方法 | `PetInteractionNotifier.syncDecayedStatusIfNeeded()` 供外部调用 | ✅ |
| 添加生命周期监听 | `PetRoomPage` 实现 `WidgetsBindingObserver`，应用启动/恢复时同步衰减状态 | ✅ |

**技术细节：**
- `_syncStatusOnInit()`: 应用启动时同步状态
- `_syncStatusOnResume()`: 应用从后台恢复时同步状态
- `didChangeAppLifecycleState()`: 监听 `AppLifecycleState.resumed` 事件

#### Phase 2: 背包数据层实现 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| UserModel 添加 inventory 字段 | `Map<String, int>` 类型，存储道具ID到数量的映射 | ✅ |
| FirestoreService 背包 CRUD | `getInventory()`, `addInventoryItem()`, `removeInventoryItem()`, `setInventoryItem()` | ✅ |
| ItemDefinitions 静态配置 | 道具定义类，包含所有可用道具的静态配置 | ✅ |

**新增文件：**
- `lib/data/models/item_definitions.dart` - 道具定义静态配置

**道具配置示例：**
```dart
static const Map<String, ItemModel> items = {
  'fish_snack': ItemModel(id: 'fish_snack', name: '小鱼干', ...),
  'premium_can': ItemModel(id: 'premium_can', name: '高级罐头', ...),
  // ...
};
```

#### Phase 3: 背包 Provider 重构 + 宠物切换 ✅

| 任务 | 详情 | 状态 |
|------|------|------|
| InventoryProvider 重构 | 从本地模拟数据改为 Firestore 持久化存储 | ✅ |
| PetSelector 组件 | 宠物切换栏，显示头像列表，支持点击切换 | ✅ |
| 集成到 PetRoomPage | 在顶部栏下方添加宠物切换栏 | ✅ |

**新增文件：**
- `lib/presentation/widgets/pet/pet_selector.dart` - 宠物切换栏组件

**PetSelector 功能：**
- 显示用户所有宠物头像（最多5只）
- 点击头像切换当前选中宠物
- 选中宠物有高亮边框和阴影效果
- 未达上限时显示添加按钮
- 无宠物或仅1只时自动隐藏

### 新增/修改文件清单

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| 新建 | `lib/data/models/item_definitions.dart` | 道具定义静态配置 |
| 新建 | `lib/presentation/widgets/pet/pet_selector.dart` | 宠物切换栏组件 |
| 修改 | `lib/data/models/user_model.dart` | 添加 inventory 字段 |
| 修改 | `lib/services/firestore_service.dart` | 添加背包 CRUD 方法 |
| 修改 | `lib/providers/inventory_provider.dart` | 重构为 Firestore 持久化 |
| 修改 | `lib/providers/pet_provider.dart` | 添加 `syncDecayedStatusIfNeeded()` 公开方法 |
| 修改 | `lib/presentation/pages/home/pet_room_page.dart` | 生命周期监听 + PetSelector 集成 |

### 数据流架构

```
┌─────────────────────────────────────────────────────────────┐
│                      PetRoomPage                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  TopBar     │  │ PetSelector │  │ InteractivePetWidget│ │
│  └─────────────┘  └──────┬──────┘  └──────────┬──────────┘ │
│                          │                     │            │
└──────────────────────────┼─────────────────────┼────────────┘
                           │                     │
                           ▼                     ▼
              ┌────────────────────┐  ┌────────────────────┐
              │ selectedPetIdProvider│ │petInteractionProvider│
              └─────────┬──────────┘  └──────────┬─────────┘
                        │                        │
                        ▼                        ▼
              ┌────────────────────────────────────────────┐
              │            FirestoreService                │
              │  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
              │  │ pets     │  │ users    │  │inventory │ │
              │  └──────────┘  └──────────┘  └──────────┘ │
              └────────────────────────────────────────────┘
```

### 后续计划更新

| 优先级 | 任务 | 说明 | 状态 |
|--------|------|------|------|
| ~~P0~~ | ~~衰减状态同步到 Firestore~~ | ~~应用启动/恢复时同步~~ | ✅ 完成 |
| ~~P1~~ | ~~背包持久化（Firestore）~~ | ~~用户道具存储~~ | ✅ 完成 |
| ~~P1~~ | ~~多宠物切换~~ | ~~PetSelector 组件~~ | ✅ 完成 |
| P1 | Rive 动画升级 | 学习 Rive 后替换静态图标 | ⏳ |
| P1 | 照片上传功能 | 上传宠物照片到 Firebase Storage | ⏳ |
| P1 | 每日签到系统 | 签到获取奖励 | ⏳ |
| P2 | 道具商店 | 购买道具功能 | ⏳ |
| P2 | 用户资料编辑 | 头像、昵称修改 | ⏳ |
| P3 | AI 卡通形象生成 | Replicate API 集成 | ⏳ |
| P3 | 社区功能 | 动态发布、点赞评论 | ⏳ |

---

## 2026-01-30 开发日志（沉浸式宠物交互重构）

### 概述

本次开发完成了沉浸式宠物交互重构，将传统按钮式交互升级为手势交互体验。新增点击抚摸、长按休息、双击玩耍、拖拽喂食/清洁等交互方式，显著提升用户沉浸感。

### 完成事项

#### 1. InteractivePetWidget 可交互宠物组件 ✅

| 功能 | 详情 | 状态 |
|------|------|------|
| 点击抚摸 | GestureDetector.onTap，心情+15，亲密度+10 | ✅ |
| 长按休息 | GestureDetector.onLongPress，精力+30 | ✅ |
| 双击玩耍 | GestureDetector.onDoubleTap，心情+20，精力-10 | ✅ |
| 拖拽接收 | DragTarget<ItemModel>，接受道具拖放 | ✅ |
| 动画反馈 | 缩放+弹跳动画，HapticFeedback 触感反馈 | ✅ |
| 状态驱动显示 | 根据心情/饥饿/行为状态切换图标 | ✅ |
| 拖拽高亮 | 道具悬停时边框高亮+提示文字 | ✅ |

#### 2. 背包系统组件 ✅

| 组件 | 文件 | 功能 |
|------|------|------|
| InventoryFAB | `inventory_fab.dart` | 背包悬浮按钮，带旋转动画 |
| InventoryPopup | `inventory_popup.dart` | 道具选择弹窗，按类别分组 |
| DraggableItemCard | `draggable_item_card.dart` | 可拖拽道具卡片，支持稀有度颜色 |

#### 3. InventoryProvider 背包状态管理 ✅

| 功能 | 详情 | 状态 |
|------|------|------|
| inventoryProvider | FutureProvider，返回 Map<ItemModel, int> | ✅ |
| inventoryNotifierProvider | StateNotifier，管理道具增删 | ✅ |
| useItem() | 使用道具，数量-1 | ✅ |
| addItem() | 添加道具 | ✅ |
| 模拟数据 | 5种测试道具（鱼干、罐头、肉条、毛巾、刷子） | ✅ |

#### 4. PetInteractionNotifier 扩展 ✅

| 方法 | 效果 | 状态 |
|------|------|------|
| play(petId) | 心情+20, 精力-10, 经验+10, 亲密度+15 | ✅ 新增 |
| clean(petId, cleanlinessGain) | 支持自定义清洁度增益 | ✅ 改进 |
| feed(petId, hungerGain) | 支持自定义饱腹度增益 | ✅ 已有 |

#### 5. PetRoomPage 重构 ✅

| 改动 | 详情 | 状态 |
|------|------|------|
| 移除按钮操作栏 | 删除 _buildActionBar() | ✅ |
| 集成 InteractivePetWidget | 替代原有宠物区域 | ✅ |
| 集成 InventoryFAB | 右下角背包悬浮按钮 | ✅ |
| 集成 InventoryPopup | 底部道具选择弹窗 | ✅ |
| 道具拖放处理 | _handleItemDropped() 完整逻辑 | ✅ |
| 优化反馈弹窗 | 带图标和详细信息的 SnackBar | ✅ |

### 新增/修改文件清单

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| 新建 | `lib/presentation/widgets/pet/interactive_pet_widget.dart` | 可交互宠物组件 |
| 新建 | `lib/presentation/widgets/inventory/inventory_fab.dart` | 背包悬浮按钮 |
| 新建 | `lib/presentation/widgets/inventory/inventory_popup.dart` | 道具选择弹窗 |
| 新建 | `lib/presentation/widgets/inventory/draggable_item_card.dart` | 可拖拽道具卡片 |
| 新建 | `lib/providers/inventory_provider.dart` | 背包状态管理 |
| 修改 | `lib/providers/pet_provider.dart` | 添加 play() 方法 |
| 重构 | `lib/presentation/pages/home/pet_room_page.dart` | 沉浸式交互布局 |

### 交互方式总结

| 交互 | 手势 | 效果 |
|------|------|------|
| 抚摸 | 单击宠物 | 心情+15, 亲密度+10 |
| 休息 | 长按宠物 | 精力+30 |
| 玩耍 | 双击宠物 | 心情+20, 精力-10 |
| 喂食 | 拖拽食物到宠物 | 饱腹度+N (根据道具) |
| 清洁 | 拖拽毛巾到宠物 | 清洁度+N (根据道具) |

### 后续计划

| 优先级 | 任务 | 说明 |
|--------|------|------|
| P1 | Rive 动画升级 | 学习 Rive 后替换静态图标为动画 |
| P1 | 背包持久化 | Firestore 存储用户道具 |
| P2 | 道具商店 | 购买道具功能 |
| P2 | 道具效果扩展 | 支持更多道具类型和效果 |

---

## 2026-01-30 开发日志（第一阶段核心功能）

### 概述

本次开发完成了第一阶段核心养成功能，包括：路由守卫、底部导航栏重构、个人中心页面、清洁互动功能、状态衰减机制。同时修复了多个 Firestore 序列化和权限问题。

### 完成事项

#### 1. 路由守卫实现 ✅

| 功能 | 详情 | 状态 |
|------|------|------|
| GoRouterRefreshStream | 监听认证状态变化，自动刷新路由 | ✅ |
| redirect 回调 | 根据登录状态重定向页面 | ✅ |
| 认证页面白名单 | splash、login、register 无需登录 | ✅ |
| 未登录重定向 | 未登录访问受保护页面自动跳转登录页 | ✅ |

#### 2. 底部导航栏重构 ✅

| 功能 | 详情 | 状态 |
|------|------|------|
| MainShellPage | 导航 Shell 容器，包含底部导航栏 | ✅ |
| ShellRoute | 使用 go_router ShellRoute 包裹主页面 | ✅ |
| 导航项 | 首页、社区、我的 三个 Tab | ✅ |
| CommunityPage | 社区占位页面 | ✅ |

#### 3. 个人中心页面 ✅

| 功能 | 详情 | 状态 |
|------|------|------|
| ProfilePage | 用户信息、货币、统计数据展示 | ✅ |
| SettingsPage | 设置页面（通知、显示、关于） | ✅ |
| 退出登录 | 确认弹窗 + 跳转登录页 | ✅ |
| 菜单列表 | 我的宠物、背包、成就、设置 | ✅ |

#### 4. 清洁互动功能 ✅

| 功能 | 详情 | 状态 |
|------|------|------|
| PetStatus.cleanliness | 宠物状态添加清洁度字段 | ✅ |
| cleanlinessColor | 清洁度状态条颜色 | ✅ |
| clean() 方法 | 清洁度+25, 心情+10, 健康+5, 经验+8, 亲密度+8 | ✅ |
| 清洁按钮 | PetRoomPage 添加清洁按钮 | ✅ |
| 清洁状态条 | 显示在状态条区域 | ✅ |

#### 5. 状态衰减机制 ✅

| 功能 | 详情 | 状态 |
|------|------|------|
| StatusDecayCalculator | 离线衰减计算器 | ✅ |
| 衰减速率 | 心情-2/h, 饥饿-3/h, 精力-1.5/h, 清洁-2/h, 健康-0.5/h | ✅ |
| 特殊规则 | 纪念模式不衰减，最大计算24小时 | ✅ |
| selectedPetWithDecayProvider | 带衰减计算的宠物 Provider | ✅ |

#### 6. Firestore 问题修复 ✅

| 问题 | 解决方案 | 状态 |
|------|----------|------|
| API 未启用 | 指导用户启用 Firestore API | ✅ |
| 数据库未创建 | 指导用户创建 Firestore 数据库 | ✅ |
| 权限拒绝 | 修改安全规则为测试模式 | ✅ |
| 索引缺失 | 移除 orderBy 查询避免复合索引 | ✅ |
| 序列化失败 | 手动构建 Firestore 数据结构 | ✅ |
| 用户文档不存在 | 使用 set(merge: true) 替代 update | ✅ |
| 反序列化类型错误 | 重写 _petFromFirestore 手动构建对象 | ✅ |

### 新增/修改文件清单

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| 新建 | `lib/core/utils/status_decay_calculator.dart` | 状态衰减计算器 |
| 新建 | `lib/presentation/pages/main/main_shell_page.dart` | 导航 Shell 容器 |
| 新建 | `lib/presentation/pages/community/community_page.dart` | 社区占位页 |
| 新建 | `lib/presentation/pages/profile/profile_page.dart` | 个人中心页面 |
| 新建 | `lib/presentation/pages/profile/settings_page.dart` | 设置页面 |
| 修改 | `lib/data/models/pet_model.dart` | PetStatus 添加 cleanliness |
| 修改 | `lib/services/firestore_service.dart` | 序列化/反序列化修复 |
| 修改 | `lib/providers/pet_provider.dart` | 添加 clean() 和衰减 Provider |
| 修改 | `lib/presentation/router/app_router.dart` | 路由守卫 + ShellRoute |
| 修改 | `lib/presentation/pages/home/pet_room_page.dart` | 清洁按钮 + 移除底部导航 |
| 修改 | `lib/presentation/pages/pet/pet_create_page.dart` | 返回按钮 + 上传提示 |
| 修改 | `lib/core/theme/app_colors.dart` | 添加 cleanlinessColor |

### 测试验证结果

| 测试项 | 预期结果 | 实际结果 |
|--------|----------|----------|
| 未登录访问 /pet-room | 重定向到 /login | ✅ 通过 |
| 已登录访问 /login | 重定向到 /pet-room | ✅ 通过 |
| 底部导航切换 | 正确切换页面 | ✅ 通过 |
| 个人中心显示 | 显示用户信息和货币 | ✅ 通过 |
| 退出登录 | 跳转到登录页 | ✅ 通过 |
| 创建宠物 | 成功创建并跳转首页 | ✅ 通过 |
| 抚摸互动 | 心情 +15 | ✅ 通过 |
| 喂食互动 | 饱腹度 +20 | ✅ 通过 |
| 清洁互动 | 清洁度 +25 | ✅ 通过 |
| 清洁状态条 | 正确显示 | ✅ 通过 |

---

## 当前功能完成状态

### 已完成功能 ✅

| 模块 | 功能 | 状态 |
|------|------|------|
| 认证 | 邮箱注册/登录 | ✅ |
| 认证 | Google 登录 | ✅ |
| 认证 | 路由守卫 | ✅ |
| 导航 | 底部导航栏 | ✅ |
| 导航 | ShellRoute 架构 | ✅ |
| 宠物 | 创建宠物（预设形象） | ✅ |
| 宠物 | 宠物展示 | ✅ |
| 互动 | 点击抚摸（手势） | ✅ |
| 互动 | 长按休息（手势） | ✅ |
| 互动 | 双击玩耍（手势） | ✅ |
| 互动 | 拖拽喂食（手势） | ✅ |
| 互动 | 拖拽清洁（手势） | ✅ |
| 背包 | 背包悬浮按钮 | ✅ |
| 背包 | 道具选择弹窗 | ✅ |
| 背包 | 可拖拽道具卡片 | ✅ |
| 背包 | 背包状态管理（本地） | ✅ |
| 状态 | 五维状态条显示 | ✅ |
| 状态 | 状态衰减计算 | ✅ |
| 用户 | 个人中心页面 | ✅ |
| 用户 | 设置页面 | ✅ |
| 用户 | 退出登录 | ✅ |

### 待开发功能

| 优先级 | 模块 | 功能 | 状态 |
|--------|------|------|------|
| P0 | 状态 | 衰减状态同步到 Firestore | ⏳ |
| P1 | 动画 | Rive 宠物动画升级 | ⏳ |
| P1 | 背包 | 背包持久化（Firestore） | ⏳ |
| P1 | 宠物 | 照片上传功能 | ⏳ |
| P1 | 宠物 | 多宠物切换 | ⏳ |
| P1 | 签到 | 每日签到系统 | ⏳ |
| P2 | 商店 | 道具商店 | ⏳ |
| P2 | 用户 | 资料编辑 | ⏳ |
| P3 | AI | 卡通形象生成 | ⏳ |
| P3 | 社区 | 社区功能 | ⏳ |
| P3 | 纪念 | 纪念模式 | ⏳ |

---

## 2026-01-29 开发日志

### 概述

本次开发完成了项目的首次运行调试，解决了多个环境配置和依赖兼容性问题，并成功实现了 Google 登录功能的代码集成。

### 完成事项

#### 1. 环境配置与依赖修复

| 问题 | 解决方案 | 状态 |
|------|----------|------|
| Firebase 依赖版本过旧 | 升级 `firebase_core` 到 4.4.0，`firebase_auth` 到 6.1.0，`cloud_firestore` 到 6.1.0，`firebase_storage` 到 13.0.0 | ✅ |
| `image_cropper` 版本不兼容 | 升级到 11.0.0 | ✅ |
| Flutter widgets 导入缺失 | `app_router.dart` 添加 `import 'package:flutter/material.dart'` | ✅ |
| `CardTheme` API 变更 | `app_theme.dart` 改为 `CardThemeData` | ✅ |
| Google Services 插件版本冲突 | `build.gradle.kts` 版本 4.4.4 → 4.3.15 | ✅ |
| Kotlin 版本不存在 | `settings.gradle.kts` 版本 2.2.20 → 2.0.21 | ✅ |
| Maven 仓库网络问题 | 配置阿里云镜像源 | ✅ |
| Firebase 重复初始化崩溃 | `main.dart` 添加 try-catch 处理 | ✅ |

#### 2. Google 登录功能实现

| 步骤 | 详情 | 状态 |
|------|------|------|
| 获取 SHA-1 指纹 | `81:E0:2F:F3:C5:AB:C6:9B:EA:88:CB:40:4C:A6:9B:5C:15:36:41:73` | ✅ |
| Firebase Console 配置 | 启用 Google 登录、添加 SHA-1 | ✅ |
| 下载 google-services.json | 更新到项目 `android/app/` 目录 | ✅ |
| 添加依赖 | `google_sign_in: ^6.2.1` | ✅ |
| AuthService 代码 | 添加 `signInWithGoogle()` 方法 | ✅ |
| Provider 代码 | LoginNotifier 添加 Google 登录 | ✅ |
| 页面代码 | 登录页面连接 Google 按钮 | ✅ |

---

## 项目概览

| 项目信息 | 值 |
|----------|-----|
| 项目名称 | Cat Club (猫咪俱乐部) |
| 技术栈 | Flutter 3.38.8 + Dart 3.10.7 |
| 状态管理 | Riverpod |
| 路由 | Go Router |
| 后端服务 | Firebase (Auth, Firestore, Storage) |
| 当前阶段 | Phase 1: MVP - Week 2 |

---

## 项目结构

```
cat-club/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       └── status_decay_calculator.dart
│   ├── data/
│   │   └── models/
│   │       ├── pet_model.dart
│   │       ├── user_model.dart
│   │       └── item_model.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── user_provider.dart
│   │   ├── pet_provider.dart
│   │   └── inventory_provider.dart          # 新增 - 背包状态管理
│   ├── services/
│   │   ├── auth_service.dart
│   │   └── firestore_service.dart
│   └── presentation/
│       ├── router/
│       │   └── app_router.dart
│       ├── pages/
│       │   ├── auth/
│       │   │   ├── splash_page.dart
│       │   │   ├── login_page.dart
│       │   │   └── register_page.dart
│       │   ├── main/
│       │   │   └── main_shell_page.dart
│       │   ├── home/
│       │   │   └── pet_room_page.dart        # 重构 - 沉浸式交互
│       │   ├── pet/
│       │   │   └── pet_create_page.dart
│       │   ├── community/
│       │   │   └── community_page.dart
│       │   └── profile/
│       │       ├── profile_page.dart
│       │       └── settings_page.dart
│       └── widgets/
│           ├── common/
│           │   ├── app_button.dart
│           │   └── app_text_field.dart
│           ├── pet/
│           │   ├── pet_status_bar.dart
│           │   └── interactive_pet_widget.dart  # 新增 - 可交互宠物组件
│           └── inventory/                       # 新增 - 背包组件目录
│               ├── inventory_fab.dart           # 新增 - 背包悬浮按钮
│               ├── inventory_popup.dart         # 新增 - 道具选择弹窗
│               └── draggable_item_card.dart     # 新增 - 可拖拽道具卡片
├── docs/
└── test/
```

---

## 运行项目

```bash
# 1. 安装依赖
cd D:\GitProject\cat-club
flutter pub get

# 2. 生成 Freezed 代码
flutter.bat pub run build_runner build --delete-conflicting-outputs

# 3. 运行应用
flutter.bat run -d emulator-5554
```

---

## 相关文档

- [01-project-overview.md](./01-project-overview.md) - 项目概述
- [02-technical-architecture.md](./02-technical-architecture.md) - 技术架构
- [03-data-models.md](./03-data-models.md) - 数据模型设计
- [04-feature-modules.md](./04-feature-modules.md) - 功能模块
- [05-api-design.md](./05-api-design.md) - API 设计
- [06-ui-design-spec.md](./06-ui-design-spec.md) - UI 设计规范
- [07-development-plan.md](./07-development-plan.md) - 开发计划
- [08-environment-setup.md](./08-environment-setup.md) - 环境配置指南
