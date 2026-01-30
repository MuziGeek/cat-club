[根目录](../../CLAUDE.md) > **core**

# Core 模块 - 核心基础设施

## 模块职责

提供应用级别的基础设施支持，包括：

- **常量定义**：应用常量、资源路径
- **主题配置**：颜色、文字样式、主题数据
- **工具类**：扩展方法、验证器、辅助函数（待实现）
- **网络层**：API 客户端、异常处理（待实现）

---

## 入口与启动

本模块无独立入口，由 `lib/app.dart` 引用主题配置。

---

## 目录结构

```
lib/core/
├── constants/
│   ├── app_constants.dart    # 应用常量
│   └── asset_constants.dart  # 资源路径常量
├── theme/
│   ├── app_theme.dart        # 主题定义（亮/暗）
│   ├── app_colors.dart       # 颜色常量
│   └── app_text_styles.dart  # 文字样式
├── utils/                    # [待实现]
│   ├── extensions.dart       # Dart 扩展
│   ├── validators.dart       # 验证器
│   └── helpers.dart          # 辅助函数
└── network/                  # [待实现]
    ├── api_client.dart       # API 客户端
    └── api_exceptions.dart   # 异常定义
```

---

## 关键依赖与配置

### 外部依赖

无外部依赖，仅使用 Flutter SDK。

### 内部引用

- `app_theme.dart` 引用 `app_colors.dart` 和 `app_text_styles.dart`

---

## 对外接口

### AppTheme

```dart
class AppTheme {
  static ThemeData get lightTheme;  // 亮色主题
  static ThemeData get darkTheme;   // 暗色主题（待完善）
}
```

### AppColors

提供应用级颜色常量：`primary`、`secondary`、`background`、`surface` 等。

### AppTextStyles

提供文字样式常量：`h1`-`h4`、`body1`、`body2`、`button` 等。

---

## 测试与质量

- 当前无测试覆盖
- 建议添加：主题渲染测试

---

## 常见问题 (FAQ)

**Q: 如何修改主题颜色？**

A: 编辑 `lib/core/theme/app_colors.dart` 中的颜色常量。

**Q: 如何添加暗色主题支持？**

A: 完善 `AppTheme.darkTheme` 实现，在 `app.dart` 中配置 `themeMode`。

---

## 相关文件清单

| 文件 | 用途 |
|------|------|
| `constants/app_constants.dart` | 应用全局常量 |
| `constants/asset_constants.dart` | 资源路径常量 |
| `theme/app_theme.dart` | 主题配置入口 |
| `theme/app_colors.dart` | 颜色定义 |
| `theme/app_text_styles.dart` | 文字样式定义 |

---

## 变更记录 (Changelog)

| 时间 | 变更内容 |
|------|----------|
| 2026-01-29 09:45:35 | 初始化模块文档 |
