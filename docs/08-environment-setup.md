# 开发环境配置指南

## 前置要求

| 工具 | 最低版本 | 推荐版本 |
|------|----------|----------|
| Flutter SDK | 3.16.0 | 3.19.0+ |
| Dart SDK | 3.2.0 | 3.3.0+ |
| Android SDK | API 21 | API 34 |
| Java JDK | 11 | 17 |
| VS Code / Android Studio | 最新版 | 最新版 |

---

## 方案 A：VSCode + Android SDK（推荐轻量方案）

### 1. 安装 Flutter SDK

```powershell
# 1. 下载 Flutter SDK
# 访问 https://docs.flutter.dev/get-started/install/windows
# 下载 flutter_windows_x.x.x-stable.zip

# 2. 解压到指定目录（避免中文路径和空格）
# 推荐: D:\flutter 或 C:\flutter

# 3. 配置环境变量
# 添加到系统 PATH: D:\flutter\bin
```

### 2. 安装 Android SDK（无需 Android Studio）

```powershell
# 1. 下载 Android Command-line Tools
# https://developer.android.com/studio#command-tools
# 下载 commandlinetools-win-xxxxx_latest.zip

# 2. 创建目录结构
mkdir D:\Android\cmdline-tools\latest

# 3. 解压内容到 D:\Android\cmdline-tools\latest\
# 确保 bin 目录在 D:\Android\cmdline-tools\latest\bin

# 4. 设置环境变量
# ANDROID_HOME = D:\Android
# ANDROID_SDK_ROOT = D:\Android
# PATH 添加:
#   - D:\Android\cmdline-tools\latest\bin
#   - D:\Android\platform-tools

# 5. 安装必要组件
sdkmanager --sdk_root=D:\Android "platform-tools"
sdkmanager --sdk_root=D:\Android "platforms;android-34"
sdkmanager --sdk_root=D:\Android "build-tools;34.0.0"
sdkmanager --sdk_root=D:\Android "system-images;android-34;google_apis;x86_64"

# 6. 接受许可证
sdkmanager --licenses
```

### 3. 配置 VSCode

```
# 安装扩展:
- Flutter (Dart-Code.flutter)
- Dart (Dart-Code.dart-code)
- Flutter Widget Snippets
- Awesome Flutter Snippets
```

### 4. 验证安装

```bash
flutter doctor -v
```

期望输出：
```
[✓] Flutter (Channel stable, 3.19.x)
[✓] Android toolchain - develop for Android devices
[✓] VS Code
[✓] Connected device
```

---

## 方案 B：VSCode + Android Studio（推荐新手）

### 1. 安装 Android Studio

```
1. 下载: https://developer.android.com/studio
2. 安装时选择 "Custom" 安装
3. 勾选:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device
4. 完成安装后打开 Android Studio
5. 进入 Settings > Plugins > 安装 Flutter 和 Dart 插件
```

### 2. 安装 Flutter SDK

同方案 A 的步骤 1。

### 3. 配置 VSCode

同方案 A 的步骤 3。

### 4. 验证安装

```bash
flutter doctor -v
```

---

## Firebase 配置

### 1. 创建 Firebase 项目

```
1. 访问 https://console.firebase.google.com/
2. 点击 "创建项目"
3. 输入项目名称: cat-club
4. 启用 Google Analytics（可选）
5. 创建完成
```

### 2. 添加 Android 应用

```
1. 在 Firebase 控制台点击 Android 图标
2. 输入包名: com.yourcompany.catclub
3. 下载 google-services.json
4. 放置到 android/app/ 目录
```

### 3. 安装 Firebase CLI

```bash
# 使用 npm 安装
npm install -g firebase-tools

# 登录
firebase login

# 安装 FlutterFire CLI
dart pub global activate flutterfire_cli

# 配置项目
flutterfire configure
```

### 4. 启用 Firebase 服务

在 Firebase 控制台启用：
- Authentication (Email/Password, Google)
- Cloud Firestore
- Cloud Storage
- Cloud Functions

---

## 项目初始化

### 1. 获取项目代码

```bash
cd D:\GitProject\cat-club
```

### 2. 创建 Flutter 项目

```bash
# 在现有目录结构基础上初始化 Flutter
flutter create --org com.yourcompany --project-name cat_club .
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 代码生成

```bash
# 生成 freezed/json_serializable 代码
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. 运行应用

```bash
# 列出可用设备
flutter devices

# 运行到指定设备
flutter run -d <device_id>

# 或直接运行（自动选择设备）
flutter run
```

---

## 开发工具配置

### VSCode settings.json

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.formatOnType": true,
    "editor.rulers": [80],
    "editor.selectionHighlight": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": "off"
  },
  "dart.flutterSdkPath": "D:\\flutter",
  "dart.lineLength": 80
}
```

### analysis_options.yaml

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - prefer_final_fields
    - prefer_final_locals
    - avoid_print
    - require_trailing_commas

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
```

---

## 常用命令

```bash
# 清理项目
flutter clean

# 获取依赖
flutter pub get

# 代码生成（持续监听）
flutter pub run build_runner watch

# 运行测试
flutter test

# 构建 APK
flutter build apk --release

# 构建 App Bundle
flutter build appbundle --release

# 分析代码
flutter analyze

# 格式化代码
dart format lib/
```

---

## 常见问题

### Q1: flutter doctor 显示 Android toolchain 有问题

```bash
# 接受所有 SDK 许可证
flutter doctor --android-licenses
```

### Q2: 找不到设备

```bash
# 确保 USB 调试已开启
# 或创建模拟器:
avdmanager create avd -n test_device -k "system-images;android-34;google_apis;x86_64"
```

### Q3: Gradle 下载慢

在 `android/gradle/wrapper/gradle-wrapper.properties` 中使用国内镜像：
```properties
distributionUrl=https://mirrors.cloud.tencent.com/gradle/gradle-8.4-all.zip
```

### Q4: pub get 超时

```bash
# 使用国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get
```
