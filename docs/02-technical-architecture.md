# 技术架构

## 技术选型

| 层级 | 技术方案 | 选择理由 |
|------|----------|----------|
| 前端框架 | Flutter | 跨平台、高性能、丰富生态 |
| 状态管理 | Riverpod | 类型安全、可测试性强 |
| 路由 | go_router | 声明式路由、深链接支持 |
| 后端服务 | Firebase | 快速开发、实时同步、免运维 |
| AI生成 | Replicate API | 灵活的模型选择、按需付费 |
| 动画引擎 | Rive + Lottie | 专业动画工具、性能优秀 |

## 架构设计

采用 **Clean Architecture** 分层架构：

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Pages, Widgets, Providers)                            │
├─────────────────────────────────────────────────────────┤
│                      Domain Layer                        │
│  (Entities, Use Cases, Repository Interfaces)           │
├─────────────────────────────────────────────────────────┤
│                       Data Layer                         │
│  (Models, Repository Impl, Data Sources)                │
├─────────────────────────────────────────────────────────┤
│                     External Services                    │
│  (Firebase, Replicate API, Local Storage)               │
└─────────────────────────────────────────────────────────┘
```

## 目录结构

```
cat-club/
├── lib/
│   ├── main.dart                     # 应用入口
│   ├── app.dart                      # App 配置
│   │
│   ├── core/                         # 核心基础设施
│   │   ├── constants/                # 常量定义
│   │   │   ├── app_constants.dart    # 应用常量
│   │   │   ├── api_constants.dart    # API 常量
│   │   │   └── asset_constants.dart  # 资源路径常量
│   │   ├── theme/                    # 主题配置
│   │   │   ├── app_theme.dart        # 主题定义
│   │   │   ├── app_colors.dart       # 颜色定义
│   │   │   └── app_text_styles.dart  # 文字样式
│   │   ├── utils/                    # 工具类
│   │   │   ├── extensions.dart       # Dart 扩展
│   │   │   ├── validators.dart       # 验证器
│   │   │   └── helpers.dart          # 辅助函数
│   │   └── network/                  # 网络层
│   │       ├── api_client.dart       # API 客户端
│   │       └── api_exceptions.dart   # 异常定义
│   │
│   ├── config/                       # 配置文件
│   │   ├── firebase_options.dart     # Firebase 配置
│   │   └── env_config.dart           # 环境配置
│   │
│   ├── data/                         # 数据层
│   │   ├── models/                   # 数据模型（JSON 序列化）
│   │   │   ├── pet_model.dart
│   │   │   ├── user_model.dart
│   │   │   ├── item_model.dart
│   │   │   └── post_model.dart
│   │   ├── repositories/             # 仓库实现
│   │   │   ├── pet_repository_impl.dart
│   │   │   ├── user_repository_impl.dart
│   │   │   └── community_repository_impl.dart
│   │   └── datasources/              # 数据源
│   │       ├── local/                # 本地数据源
│   │       │   └── local_storage.dart
│   │       └── remote/               # 远程数据源
│   │           ├── firebase_auth_source.dart
│   │           ├── firestore_source.dart
│   │           └── storage_source.dart
│   │
│   ├── domain/                       # 领域层
│   │   ├── entities/                 # 领域实体
│   │   │   ├── pet.dart
│   │   │   ├── user.dart
│   │   │   └── interaction.dart
│   │   ├── usecases/                 # 用例
│   │   │   ├── pet/
│   │   │   │   ├── create_pet.dart
│   │   │   │   ├── feed_pet.dart
│   │   │   │   └── update_pet_status.dart
│   │   │   ├── auth/
│   │   │   │   ├── sign_in.dart
│   │   │   │   └── sign_up.dart
│   │   │   └── community/
│   │   │       ├── create_post.dart
│   │   │       └── like_post.dart
│   │   └── repositories/             # 仓库接口
│   │       ├── pet_repository.dart
│   │       ├── user_repository.dart
│   │       └── community_repository.dart
│   │
│   ├── presentation/                 # 表示层
│   │   ├── providers/                # Riverpod Providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── pet_provider.dart
│   │   │   ├── interaction_provider.dart
│   │   │   └── community_provider.dart
│   │   ├── pages/                    # 页面
│   │   │   ├── auth/
│   │   │   │   ├── login_page.dart
│   │   │   │   ├── register_page.dart
│   │   │   │   └── splash_page.dart
│   │   │   ├── home/
│   │   │   │   └── pet_room_page.dart
│   │   │   ├── pet/
│   │   │   │   ├── pet_create_page.dart
│   │   │   │   ├── pet_detail_page.dart
│   │   │   │   └── pet_wardrobe_page.dart
│   │   │   ├── community/
│   │   │   │   ├── community_page.dart
│   │   │   │   └── post_detail_page.dart
│   │   │   ├── profile/
│   │   │   │   ├── profile_page.dart
│   │   │   │   └── settings_page.dart
│   │   │   └── memorial/
│   │   │       ├── memorial_page.dart
│   │   │       └── memory_album_page.dart
│   │   ├── widgets/                  # 通用组件
│   │   │   ├── common/
│   │   │   │   ├── app_button.dart
│   │   │   │   ├── app_card.dart
│   │   │   │   └── loading_widget.dart
│   │   │   ├── pet/
│   │   │   │   ├── pet_avatar.dart
│   │   │   │   ├── pet_status_bar.dart
│   │   │   │   └── pet_animation.dart
│   │   │   └── interactions/
│   │   │       ├── feed_button.dart
│   │   │       ├── pet_touch_area.dart
│   │   │       └── heart_animation.dart
│   │   └── router/                   # 路由配置
│   │       └── app_router.dart
│   │
│   ├── services/                     # 服务层
│   │   ├── ai_generation_service.dart    # AI 图像生成
│   │   ├── notification_service.dart     # 通知服务
│   │   ├── analytics_service.dart        # 数据分析
│   │   └── share_service.dart            # 分享服务
│   │
│   └── di/                           # 依赖注入
│       └── injection.dart
│
├── assets/                           # 静态资源
│   ├── images/
│   │   ├── pets/                     # 预设宠物图片
│   │   ├── items/                    # 道具图片
│   │   ├── backgrounds/              # 背景图片
│   │   └── ui/                       # UI 图片
│   ├── animations/
│   │   ├── rive/                     # Rive 动画文件
│   │   └── lottie/                   # Lottie 动画文件
│   └── fonts/                        # 字体文件
│
├── test/                             # 测试
│   ├── unit/                         # 单元测试
│   ├── widget/                       # Widget 测试
│   └── integration/                  # 集成测试
│
├── pubspec.yaml                      # 依赖配置
├── analysis_options.yaml             # 代码分析配置
└── README.md                         # 项目说明
```

## 状态管理架构

使用 Riverpod 进行状态管理：

```dart
// Provider 层级
┌─────────────────────────────────────┐
│     UI (ConsumerWidget)             │
├─────────────────────────────────────┤
│     StateNotifierProvider           │
│     (业务逻辑 + 状态管理)            │
├─────────────────────────────────────┤
│     Provider                        │
│     (Use Cases / Services)          │
├─────────────────────────────────────┤
│     Provider                        │
│     (Repositories)                  │
└─────────────────────────────────────┘
```

## 数据流

```
用户操作 → Provider → Use Case → Repository → Data Source
                                      ↓
UI 更新 ← Provider ← Entity ← Model ←─┘
```
