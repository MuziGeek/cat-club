[根目录](../../CLAUDE.md) > **data**

# Data 模块 - 数据层

## 模块职责

负责数据的定义、存储和获取，包括：

- **数据模型**：使用 freezed 定义不可变数据类
- **仓库实现**：实现领域层定义的仓库接口（待实现）
- **数据源**：本地存储和远程 API 交互（待实现）

---

## 入口与启动

本模块无独立入口，由 Provider 和 Service 层引用。

---

## 目录结构

```
lib/data/
├── models/
│   ├── pet_model.dart      # 宠物数据模型
│   ├── user_model.dart     # 用户数据模型
│   └── item_model.dart     # 道具数据模型
├── repositories/           # [待实现]
│   ├── pet_repository_impl.dart
│   ├── user_repository_impl.dart
│   └── community_repository_impl.dart
└── datasources/            # [待实现]
    ├── local/
    │   └── local_storage.dart
    └── remote/
        ├── firebase_auth_source.dart
        ├── firestore_source.dart
        └── storage_source.dart
```

---

## 数据模型

### PetModel - 宠物模型

```dart
@freezed
class PetModel {
  final String id;
  final String userId;
  final String name;
  final PetSpecies species;     // cat, dog, rabbit...
  final PetAppearance appearance;
  final PetStatus status;       // happiness, hunger, energy, health
  final PetStats stats;         // level, experience, intimacy
  final bool isMemorial;        // 纪念模式
  // ...
}
```

**关键扩展方法**：
- `expToNextLevel` - 升级所需经验
- `intimacyLevelName` - 亲密度等级名称
- `moodDescription` - 心情描述

### UserModel - 用户模型

```dart
@freezed
class UserModel {
  final String id;
  final String? email;
  final String? displayName;
  final int coins;              // 虚拟货币
  final int diamonds;           // 高级货币
  final List<String> petIds;    // 拥有的宠物
  final UserSettings settings;
  // ...
}
```

### ItemModel - 道具模型

包含道具类别（食物、配饰、服装、背景）和稀有度定义。

---

## 关键依赖与配置

### 外部依赖

- `freezed_annotation` - 不可变数据类注解
- `json_annotation` - JSON 序列化注解

### 代码生成

修改模型后需运行：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

生成文件：`*.freezed.dart`、`*.g.dart`

---

## 对外接口

### 模型工厂方法

```dart
PetModel.fromJson(Map<String, dynamic> json);
UserModel.fromJson(Map<String, dynamic> json);
ItemModel.fromJson(Map<String, dynamic> json);
```

### 模型序列化

```dart
petModel.toJson();
userModel.toJson();
```

---

## 测试与质量

- 当前无测试覆盖
- 建议添加：
  - 模型 JSON 序列化/反序列化测试
  - 扩展方法单元测试

---

## 常见问题 (FAQ)

**Q: 修改模型后编译报错？**

A: 运行 `flutter pub run build_runner build --delete-conflicting-outputs` 重新生成代码。

**Q: 如何添加新字段？**

A: 在 freezed 类中添加字段，运行 build_runner，注意 Firebase 数据迁移。

---

## 相关文件清单

| 文件 | 用途 |
|------|------|
| `models/pet_model.dart` | 宠物数据模型 + 扩展方法 |
| `models/user_model.dart` | 用户数据模型 + 扩展方法 |
| `models/item_model.dart` | 道具数据模型 |

---

## 变更记录 (Changelog)

| 时间 | 变更内容 |
|------|----------|
| 2026-01-29 09:45:35 | 初始化模块文档 |
