# 数据模型设计

## 核心实体

### 1. Pet（宠物）

```dart
class Pet {
  final String id;
  final String userId;
  final String name;
  final PetSpecies species;      // 物种：cat, dog, rabbit 等
  final String? breed;           // 品种

  // 外观特征
  final PetAppearance appearance;

  // 图片
  final String? originalPhotoUrl;    // 原始照片
  final String? cartoonAvatarUrl;    // AI 生成的卡通形象
  final List<String> generatedAvatars; // 备选形象列表

  // 状态值 (0-100)
  final PetStatus status;

  // 成长数据
  final PetStats stats;

  // 装备
  final List<String> equippedItems;  // 当前装备的道具 ID
  final List<String> ownedItems;     // 拥有的道具 ID

  // 纪念模式
  final bool isMemorial;
  final String? memorialNote;
  final DateTime? memorialDate;

  // 时间戳
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastInteractionAt;
}

class PetAppearance {
  final String furColor;         // 毛色
  final String? furPattern;      // 花纹
  final String eyeColor;         // 眼睛颜色
  final String? specialMarks;    // 特殊标记
}

class PetStatus {
  final int happiness;    // 心情值 0-100
  final int hunger;       // 饱腹度 0-100
  final int energy;       // 精力值 0-100
  final int health;       // 健康值 0-100
}

class PetStats {
  final int level;        // 等级 1-99
  final int experience;   // 当前经验值
  final int intimacy;     // 亲密度 0-10000
  final int totalFeedings;     // 累计喂食次数
  final int totalInteractions; // 累计互动次数
}
```

### 2. User（用户）

```dart
class User {
  final String id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;

  // 用户数据
  final int coins;                // 虚拟货币
  final int diamonds;             // 高级货币
  final List<String> petIds;      // 拥有的宠物
  final List<String> achievements;// 已解锁成就

  // 社交
  final List<String> following;   // 关注列表
  final List<String> followers;   // 粉丝列表

  // 签到
  final int consecutiveDays;      // 连续签到天数
  final DateTime? lastSignInDate;

  // 设置
  final UserSettings settings;

  final DateTime createdAt;
}

class UserSettings {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final String language;
  final String theme;
}
```

### 3. Item（道具）

```dart
class Item {
  final String id;
  final String name;
  final String description;
  final ItemCategory category;    // food, accessory, clothing, background
  final ItemRarity rarity;        // common, rare, epic, legendary

  final String imageUrl;
  final int price;
  final CurrencyType currency;    // coins, diamonds

  // 效果
  final Map<String, int> effects; // 如 {"happiness": 10, "hunger": 20}

  // 限制
  final List<PetSpecies>? applicableSpecies;
  final bool isLimited;
  final DateTime? availableUntil;
}

enum ItemCategory {
  food,       // 食物
  accessory,  // 配饰
  clothing,   // 服装
  background, // 背景
  special,    // 特殊道具
}

enum ItemRarity {
  common,     // 普通
  rare,       // 稀有
  epic,       // 史诗
  legendary,  // 传说
}
```

### 4. Post（社区动态）

```dart
class Post {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;

  final String content;
  final List<String> imageUrls;
  final String? petId;

  final int likeCount;
  final int commentCount;
  final List<String> likedBy;

  final DateTime createdAt;
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
}
```

### 5. Achievement（成就）

```dart
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final AchievementCategory category;

  // 解锁条件
  final Map<String, dynamic> requirements;

  // 奖励
  final int rewardCoins;
  final int rewardDiamonds;
  final String? rewardItemId;
}
```

## 状态衰减规则

| 状态 | 衰减速度 | 最低值影响 |
|------|----------|------------|
| 饱腹度 (hunger) | -1 / 30分钟 | < 20 时心情加速下降 |
| 心情 (happiness) | -1 / 60分钟 | < 20 时经验获取减少 |
| 精力 (energy) | -1 / 45分钟 | < 20 时互动效果减半 |
| 健康 (health) | 仅在饱腹度 < 10 时 -1 / 120分钟 | < 50 时所有属性上限降低 |

### 状态计算逻辑

```dart
PetStatus calculateCurrentStatus(Pet pet, DateTime now) {
  final elapsed = now.difference(pet.lastInteractionAt);
  final minutes = elapsed.inMinutes;

  return PetStatus(
    hunger: max(0, pet.status.hunger - (minutes ~/ 30)),
    happiness: max(0, pet.status.happiness - (minutes ~/ 60)),
    energy: max(0, pet.status.energy - (minutes ~/ 45)),
    health: calculateHealth(pet, minutes),
  );
}
```

## Firebase 数据结构

```
firestore/
├── users/
│   └── {userId}/
│       ├── profile (document)
│       ├── settings (document)
│       └── achievements/ (subcollection)
│
├── pets/
│   └── {petId}/
│       ├── data (document)
│       ├── inventory/ (subcollection)
│       └── interactions/ (subcollection - 最近记录)
│
├── items/
│   └── {itemId} (document)
│
├── posts/
│   └── {postId}/
│       ├── data (document)
│       └── comments/ (subcollection)
│
└── achievements/
    └── {achievementId} (document)
```
