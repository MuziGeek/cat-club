# 功能模块详细设计

## 模块 1：宠物录入与 AI 生成

### 功能流程

```
用户上传照片 → 图片预处理 → 特征提取 (GPT-4V) → 形象生成 (SDXL) → 用户选择
```

### 详细步骤

#### 1.1 照片上传
- 支持相机拍摄和相册选择
- 图片质量检测（分辨率、清晰度）
- 自动裁剪和对齐

#### 1.2 特征提取 (GPT-4 Vision)

```dart
class PetFeatureExtractor {
  Future<PetFeatures> extractFeatures(File image) async {
    // 调用 GPT-4 Vision API
    // Prompt: "分析这张宠物照片，提取以下特征：
    //  - 物种和品种
    //  - 毛色（主色、副色）
    //  - 花纹类型
    //  - 眼睛颜色
    //  - 特殊标记
    //  返回 JSON 格式"
  }
}
```

#### 1.3 卡通形象生成 (Replicate SDXL)

```dart
class CartoonGenerator {
  final styles = {
    'cute': 'chibi style, cute, kawaii, round features',
    'anime': 'anime style, detailed, expressive eyes',
    'realistic': 'semi-realistic, detailed fur, soft lighting',
  };

  Future<List<String>> generateCartoons(
    File image,
    PetFeatures features,
    String style,
  ) async {
    // 生成 4 张备选形象
    // 使用特征哈希作为 seed 保持一致性
  }
}
```

### 风格选项

| 风格 | 说明 | 适用场景 |
|------|------|----------|
| 可爱风 | Q版、圆润、大眼睛 | 日常互动 |
| 动漫风 | 日系动漫风格 | 年轻用户 |
| 写实风 | 保留更多真实特征 | 纪念模式 |

---

## 模块 2：基础陪伴互动

### 2.1 喂食系统

```dart
class FeedingInteraction {
  // 食物类型及效果
  static const foods = {
    'basic_food': {'hunger': +20, 'happiness': +5},
    'premium_food': {'hunger': +30, 'happiness': +15, 'health': +5},
    'treat': {'hunger': +5, 'happiness': +25},
  };

  Future<void> feed(Pet pet, Item food) async {
    // 1. 播放喂食动画
    // 2. 更新状态值
    // 3. 增加经验值
    // 4. 记录互动日志
  }
}
```

**喂食动画流程：**
1. 食物从屏幕边缘滑入
2. 宠物做出期待表情
3. 食物移动到宠物嘴边
4. 宠物吃食动画
5. 满足表情 + 状态条更新

### 2.2 抚摸系统

```dart
class PettingInteraction {
  // 触摸区域及反应
  static const touchZones = {
    'head': {'happiness': +10, 'animation': 'happy_purr'},
    'chin': {'happiness': +15, 'animation': 'chin_scratch'},
    'belly': {'happiness': +5, 'animation': 'belly_rub'},  // 有几率反感
    'back': {'happiness': +8, 'animation': 'back_stroke'},
  };

  void onTouch(Offset position, Pet pet) {
    // 1. 检测触摸区域
    // 2. 播放对应动画
    // 3. 飘出爱心粒子效果
    // 4. 更新心情值
  }
}
```

### 2.3 换装系统

```dart
class WardrobeManager {
  // 装备槽位
  static const slots = [
    'hat',       // 帽子
    'glasses',   // 眼镜
    'collar',    // 项圈
    'clothing',  // 服装
    'accessory', // 配饰
  ];

  Future<void> equipItem(Pet pet, Item item, String slot) async {
    // 验证物品是否适用
    // 更新装备状态
    // 刷新宠物显示
  }
}
```

### 2.4 拍照分享

```dart
class PhotoCapture {
  Future<File> captureSnapshot(Pet pet, {
    String? background,
    String? frame,
    String? sticker,
  }) async {
    // 1. 渲染当前宠物状态
    // 2. 添加背景/边框/贴纸
    // 3. 生成高清图片
    // 4. 返回可分享的文件
  }
}
```

---

## 模块 3：成长系统

### 3.1 等级系统

| 等级区间 | 升级所需经验 | 解锁内容 |
|----------|--------------|----------|
| 1-10 | 100 * level | 基础互动 |
| 11-30 | 200 * level | 更多食物、配饰 |
| 31-50 | 350 * level | 高级服装、特殊背景 |
| 51-70 | 500 * level | 稀有道具、特殊动画 |
| 71-99 | 800 * level | 传说道具、专属称号 |

### 3.2 经验获取

| 行为 | 基础经验 | 冷却时间 |
|------|----------|----------|
| 喂食 | 10 | 10分钟 |
| 抚摸 | 5 | 5分钟 |
| 换装 | 3 | 无 |
| 拍照 | 5 | 1分钟 |
| 签到 | 50 | 每日一次 |

### 3.3 亲密度系统

```dart
class IntimacySystem {
  // 亲密度等级
  static const levels = {
    0: '初识',      // 0-500
    1: '熟悉',      // 500-1500
    2: '亲近',      // 1500-3000
    3: '信赖',      // 3000-5000
    4: '挚友',      // 5000-7500
    5: '灵魂伴侣',  // 7500-10000
  };

  // 不同亲密度解锁不同互动反应
}
```

### 3.4 成就系统

```dart
class AchievementDefinitions {
  static const achievements = [
    // 互动类
    Achievement(id: 'first_feeding', name: '初次喂食', requirement: {'feedings': 1}),
    Achievement(id: 'feeding_100', name: '美食家', requirement: {'feedings': 100}),
    Achievement(id: 'petting_master', name: '抚摸达人', requirement: {'pettings': 500}),

    // 成长类
    Achievement(id: 'level_10', name: '初露锋芒', requirement: {'level': 10}),
    Achievement(id: 'level_50', name: '资深铲屎官', requirement: {'level': 50}),
    Achievement(id: 'max_intimacy', name: '灵魂伴侣', requirement: {'intimacy': 10000}),

    // 收集类
    Achievement(id: 'wardrobe_10', name: '小小收藏家', requirement: {'items': 10}),
    Achievement(id: 'all_styles', name: '百变造型', requirement: {'styles': 'all'}),

    // 社交类
    Achievement(id: 'first_post', name: '初次分享', requirement: {'posts': 1}),
    Achievement(id: 'popular', name: '人气之星', requirement: {'likes': 100}),

    // 签到类
    Achievement(id: 'week_streak', name: '一周坚持', requirement: {'streak': 7}),
    Achievement(id: 'month_streak', name: '月度铲屎官', requirement: {'streak': 30}),
  ];
}
```

---

## 模块 4：社交分享

### 4.1 社区动态流

```dart
class CommunityFeed {
  // 动态类型
  enum PostType {
    photo,       // 宠物照片
    milestone,   // 成长里程碑
    achievement, // 成就解锁
    outfit,      // 新造型展示
  }

  // 支持无限滚动分页
  Stream<List<Post>> getFeed({
    int limit = 20,
    String? cursor,
  });
}
```

### 4.2 分享卡片生成

```dart
class ShareCardGenerator {
  Future<File> generateCard(Pet pet, ShareCardTemplate template) async {
    // 模板类型：
    // - 日常分享卡
    // - 成就卡
    // - 纪念卡
    // - 节日卡
  }
}
```

---

## 模块 5：纪念模式

### 5.1 UI 风格变化

```dart
class MemorialTheme {
  static const colors = {
    'background': Color(0xFFFFF8E7),  // 温暖米色
    'primary': Color(0xFFD4A574),     // 柔和棕色
    'accent': Color(0xFFE8C4A0),      // 淡金色
    'text': Color(0xFF5C4033),        // 深棕色
  };

  // 柔和的动画过渡
  // 轻柔的背景音乐选项
}
```

### 5.2 回忆相册

```dart
class MemoryAlbum {
  // 按时间线展示照片
  // 支持添加文字描述
  // 自动生成回忆视频
}
```

### 5.3 纪念日提醒

```dart
class MemorialReminder {
  // 生日提醒
  // 相识纪念日
  // 离世周年
  // 支持自定义日期
}
```

### 5.4 星座化

```dart
class ConstellationFeature {
  // 将宠物形象转化为星座图案
  // 夜空动画背景
  // 点击闪烁效果
}
```
