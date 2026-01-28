# UI 设计规范

## 设计理念

- **温暖治愈**：柔和的配色，圆润的形状
- **简洁直观**：清晰的信息层级，易于操作
- **情感化设计**：细节动效增强情感连接

## 颜色系统

### 主色调

```dart
class AppColors {
  // 主色 - 温暖橙色
  static const primary = Color(0xFFFF9F5A);
  static const primaryLight = Color(0xFFFFBE8A);
  static const primaryDark = Color(0xFFE8823D);

  // 辅助色 - 柔和粉色
  static const secondary = Color(0xFFFFB5C5);
  static const secondaryLight = Color(0xFFFFD4DE);
  static const secondaryDark = Color(0xFFE8909F);

  // 强调色 - 活力蓝
  static const accent = Color(0xFF5BC0EB);

  // 背景色
  static const background = Color(0xFFFFF8F0);
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFFAF5);

  // 文字颜色
  static const textPrimary = Color(0xFF3D3D3D);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);

  // 状态颜色
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFE57373);

  // 状态条颜色
  static const happinessColor = Color(0xFFFFD700);  // 金色
  static const hungerColor = Color(0xFFFF7043);     // 橙红
  static const energyColor = Color(0xFF42A5F5);     // 蓝色
  static const healthColor = Color(0xFF66BB6A);     // 绿色
}
```

### 纪念模式色调

```dart
class MemorialColors {
  static const background = Color(0xFFFFF8E7);   // 温暖米色
  static const primary = Color(0xFFD4A574);      // 柔和棕色
  static const accent = Color(0xFFE8C4A0);       // 淡金色
  static const text = Color(0xFF5C4033);         // 深棕色
  static const starlight = Color(0xFFFFFACD);    // 柠檬绸色（星光）
}
```

## 字体系统

```dart
class AppTextStyles {
  // 标题
  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // 正文
  static const body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // 按钮
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // 标签
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );

  // 宠物名称
  static const petName = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
}
```

## 间距系统

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
```

## 圆角系统

```dart
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double round = 999;  // 完全圆形
}
```

## 阴影系统

```dart
class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const button = [
    BoxShadow(
      color: Color(0x33FF9F5A),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];
}
```

## 核心组件规范

### 按钮

```dart
// 主按钮
class PrimaryButton extends StatelessWidget {
  // 高度: 48-56dp
  // 圆角: 24dp (完全圆角)
  // 内边距: 24dp 水平
  // 带有轻微阴影
  // 点击时有缩放动效
}

// 次要按钮
class SecondaryButton extends StatelessWidget {
  // 边框样式
  // 透明背景
}

// 图标按钮
class IconActionButton extends StatelessWidget {
  // 圆形，带背景色
  // 尺寸: 48dp
}
```

### 卡片

```dart
class AppCard extends StatelessWidget {
  // 圆角: 16dp
  // 内边距: 16dp
  // 背景: 白色
  // 阴影: card shadow
}
```

### 状态条

```dart
class StatusBar extends StatelessWidget {
  // 高度: 8dp
  // 圆角: 4dp
  // 背景: 灰色轨道
  // 前景: 渐变色填充
  // 动画: 数值变化时平滑过渡
}
```

### 宠物卡片

```dart
class PetCard extends StatelessWidget {
  // 包含: 宠物头像、名称、等级、状态摘要
  // 点击进入详情
  // 长按显示快捷操作
}
```

## 页面布局规范

### 宠物房间页面

```
┌─────────────────────────────────┐
│  状态栏 (SafeArea)               │
├─────────────────────────────────┤
│  顶部信息条                       │
│  [货币] [等级] [设置]             │
├─────────────────────────────────┤
│                                 │
│                                 │
│     宠物展示区域                  │
│     (可触摸互动)                  │
│                                 │
│                                 │
├─────────────────────────────────┤
│  状态条区域                       │
│  [心情] [饱腹] [精力] [健康]       │
├─────────────────────────────────┤
│  快捷操作栏                       │
│  [喂食] [抚摸] [换装] [拍照]       │
├─────────────────────────────────┤
│  底部导航栏                       │
│  [首页] [社区] [背包] [我的]       │
└─────────────────────────────────┘
```

## 动效规范

### 通用动效

| 动效类型 | 时长 | 曲线 |
|----------|------|------|
| 页面切换 | 300ms | easeInOut |
| 按钮点击 | 100ms | easeOut |
| 卡片展开 | 250ms | easeOutCubic |
| 状态条变化 | 500ms | easeInOutCubic |
| 弹窗出现 | 200ms | easeOutBack |

### 宠物专属动效

| 动效 | 说明 |
|------|------|
| 待机呼吸 | 轻微上下浮动 + 眨眼 |
| 开心摇尾 | 尾巴左右摆动 |
| 吃东西 | 嘴巴张合 + 眼睛眯起 |
| 被抚摸 | 眼睛眯起 + 发出心形粒子 |
| 困倦 | 眼睛半闭 + 打哈欠 |
| 饥饿 | 肚子咕噜 + 眼神期待 |

### 粒子效果

| 场景 | 粒子类型 |
|------|----------|
| 抚摸 | 爱心飘散 |
| 喂食 | 星星闪烁 |
| 升级 | 彩色纸屑 |
| 成就解锁 | 金色光芒 |

## 图标规范

- 风格：线性 + 圆润
- 尺寸：24dp (标准) / 20dp (小) / 32dp (大)
- 颜色：跟随主题色或使用 textSecondary

## 响应式设计

```dart
class Breakpoints {
  static const double mobile = 375;
  static const double tablet = 768;
  static const double desktop = 1024;
}

// 根据屏幕宽度调整布局
// Mobile: 单列布局
// Tablet: 可选双列
```

## 无障碍设计

- 所有可交互元素有足够的触摸区域 (最小 48x48dp)
- 图片提供语义化描述
- 支持系统字体缩放
- 色彩对比度符合 WCAG AA 标准
