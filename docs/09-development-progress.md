# 开发进度记录

> 最后更新：2026-01-30 15:35

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
