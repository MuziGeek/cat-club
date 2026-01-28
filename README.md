# Cat Club - 虚拟宠物陪伴应用

一款通过 AI 生成独特卡通宠物形象的虚拟养宠应用，让你与宠物的陪伴永不结束。

## ✨ 特色功能

- 🎨 **AI 智能生成** - 上传宠物照片，AI 自动生成专属卡通形象
- 🐱 **沉浸式互动** - 喂食、抚摸、换装等丰富互动体验
- 📈 **成长系统** - 等级、亲密度、成就收集
- 👥 **社交分享** - 社区动态、分享卡片
- 💫 **纪念模式** - 为已故宠物提供温馨的永久纪念

## 🛠 技术栈

- **前端框架**: Flutter
- **状态管理**: Riverpod
- **路由**: go_router
- **后端服务**: Firebase (Auth + Firestore + Storage + Functions)
- **AI 生成**: Replicate API (Stable Diffusion)
- **动画引擎**: Rive + Lottie

## 📁 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # App 配置
├── core/                     # 核心基础设施
│   ├── constants/            # 常量定义
│   ├── theme/                # 主题配置
│   ├── utils/                # 工具类
│   └── network/              # 网络层
├── config/                   # 配置文件
├── data/                     # 数据层
│   ├── models/               # 数据模型
│   ├── repositories/         # 仓库实现
│   └── datasources/          # 数据源
├── domain/                   # 领域层
│   ├── entities/             # 领域实体
│   ├── usecases/             # 用例
│   └── repositories/         # 仓库接口
├── presentation/             # 表示层
│   ├── providers/            # 状态管理
│   ├── pages/                # 页面
│   ├── widgets/              # 通用组件
│   └── router/               # 路由配置
└── services/                 # 服务层
```

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0
- Android SDK (API 21+)

### 安装步骤

1. **克隆项目**
```bash
git clone <repository-url>
cd cat-club
```

2. **安装依赖**
```bash
flutter pub get
```

3. **配置 Firebase**
```bash
# 安装 FlutterFire CLI
dart pub global activate flutterfire_cli

# 配置 Firebase
flutterfire configure
```

4. **代码生成**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

5. **运行应用**
```bash
flutter run
```

## 📚 文档

详细文档请查看 [docs/](./docs/) 目录：

- [项目概述](./docs/01-project-overview.md)
- [技术架构](./docs/02-technical-architecture.md)
- [数据模型](./docs/03-data-models.md)
- [功能模块](./docs/04-feature-modules.md)
- [API 设计](./docs/05-api-design.md)
- [UI 设计规范](./docs/06-ui-design-spec.md)
- [开发计划](./docs/07-development-plan.md)
- [环境配置](./docs/08-environment-setup.md)

## 📝 开发计划

- [x] Phase 1: 项目初始化与架构搭建
- [ ] Phase 1: 用户认证与宠物创建
- [ ] Phase 1: 宠物房间与基础互动
- [ ] Phase 1: AI 形象生成集成
- [ ] Phase 2: 成长系统与成就
- [ ] Phase 2: 换装系统与商店
- [ ] Phase 3: 社区功能

## 📄 License

MIT License
