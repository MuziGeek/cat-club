# API 设计文档

## Firebase 数据结构

### Collections 设计

```
firestore-root/
│
├── users/{userId}
│   ├── email: string
│   ├── displayName: string
│   ├── avatarUrl: string?
│   ├── coins: number
│   ├── diamonds: number
│   ├── petIds: string[]
│   ├── achievements: string[]
│   ├── following: string[]
│   ├── followers: string[]
│   ├── consecutiveDays: number
│   ├── lastSignInDate: timestamp
│   ├── settings: map
│   │   ├── notificationsEnabled: boolean
│   │   ├── soundEnabled: boolean
│   │   ├── language: string
│   │   └── theme: string
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
│
├── pets/{petId}
│   ├── userId: string
│   ├── name: string
│   ├── species: string
│   ├── breed: string?
│   ├── appearance: map
│   │   ├── furColor: string
│   │   ├── furPattern: string?
│   │   ├── eyeColor: string
│   │   └── specialMarks: string?
│   ├── originalPhotoUrl: string?
│   ├── cartoonAvatarUrl: string?
│   ├── generatedAvatars: string[]
│   ├── status: map
│   │   ├── happiness: number
│   │   ├── hunger: number
│   │   ├── energy: number
│   │   └── health: number
│   ├── stats: map
│   │   ├── level: number
│   │   ├── experience: number
│   │   ├── intimacy: number
│   │   ├── totalFeedings: number
│   │   └── totalInteractions: number
│   ├── equippedItems: string[]
│   ├── ownedItems: string[]
│   ├── isMemorial: boolean
│   ├── memorialNote: string?
│   ├── memorialDate: timestamp?
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   └── lastInteractionAt: timestamp
│
├── items/{itemId}
│   ├── name: string
│   ├── description: string
│   ├── category: string (food|accessory|clothing|background|special)
│   ├── rarity: string (common|rare|epic|legendary)
│   ├── imageUrl: string
│   ├── price: number
│   ├── currency: string (coins|diamonds)
│   ├── effects: map<string, number>
│   ├── applicableSpecies: string[]?
│   ├── isLimited: boolean
│   └── availableUntil: timestamp?
│
├── posts/{postId}
│   ├── userId: string
│   ├── userName: string
│   ├── userAvatar: string?
│   ├── content: string
│   ├── imageUrls: string[]
│   ├── petId: string?
│   ├── likeCount: number
│   ├── commentCount: number
│   ├── likedBy: string[]
│   ├── createdAt: timestamp
│   └── comments/{commentId}
│       ├── userId: string
│       ├── userName: string
│       ├── userAvatar: string?
│       ├── content: string
│       └── createdAt: timestamp
│
└── achievements/{achievementId}
    ├── name: string
    ├── description: string
    ├── iconUrl: string
    ├── category: string
    ├── requirements: map
    ├── rewardCoins: number
    ├── rewardDiamonds: number
    └── rewardItemId: string?
```

## Cloud Functions API

### 认证相关

```typescript
// 用户注册后初始化
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  // 创建用户文档
  // 发放新手奖励
});

// 用户删除后清理
exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  // 清理用户数据
});
```

### AI 生成相关

```typescript
// 生成卡通形象
exports.generateCartoonAvatar = functions.https.onCall(async (data, context) => {
  // 参数: { imageUrl: string, style: string }
  // 返回: { avatars: string[], features: PetFeatures }
});

// 特征提取
exports.extractPetFeatures = functions.https.onCall(async (data, context) => {
  // 参数: { imageUrl: string }
  // 返回: { species, breed, furColor, ... }
});
```

### 宠物相关

```typescript
// 创建宠物
exports.createPet = functions.https.onCall(async (data, context) => {
  // 参数: PetCreateData
  // 返回: { petId: string, pet: Pet }
});

// 互动
exports.interactWithPet = functions.https.onCall(async (data, context) => {
  // 参数: { petId: string, action: string, itemId?: string }
  // 返回: { pet: Pet, rewards?: Reward[] }
});

// 状态同步（离线后重新上线）
exports.syncPetStatus = functions.https.onCall(async (data, context) => {
  // 计算离线期间的状态衰减
  // 返回更新后的状态
});
```

### 社交相关

```typescript
// 创建动态
exports.createPost = functions.https.onCall(async (data, context) => {
  // 参数: { content: string, imageUrls: string[], petId?: string }
});

// 点赞（使用事务保证原子性）
exports.likePost = functions.https.onCall(async (data, context) => {
  // 参数: { postId: string }
});
```

### 定时任务

```typescript
// 每日重置（签到状态等）
exports.dailyReset = functions.pubsub.schedule('0 0 * * *').onRun(async () => {
  // 重置每日任务
});

// 清理过期数据
exports.cleanupExpiredData = functions.pubsub.schedule('0 3 * * *').onRun(async () => {
  // 清理过期的临时数据
});
```

## Replicate API 集成

### 图像生成请求

```dart
class ReplicateService {
  static const String baseUrl = 'https://api.replicate.com/v1';

  Future<List<String>> generateImages({
    required String imageUrl,
    required String style,
    required PetFeatures features,
  }) async {
    final prompt = _buildPrompt(style, features);

    final response = await http.post(
      Uri.parse('$baseUrl/predictions'),
      headers: {
        'Authorization': 'Token $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'version': 'sdxl-model-version',
        'input': {
          'image': imageUrl,
          'prompt': prompt,
          'negative_prompt': 'realistic photo, human, text, watermark',
          'num_outputs': 4,
          'guidance_scale': 7.5,
          'num_inference_steps': 30,
        },
      }),
    );

    // 轮询获取结果...
  }

  String _buildPrompt(String style, PetFeatures features) {
    final stylePrompt = {
      'cute': 'chibi, kawaii, cute cartoon',
      'anime': 'anime style, detailed eyes',
      'realistic': 'semi-realistic, detailed fur',
    }[style];

    return '''
      $stylePrompt ${features.species}, ${features.furColor} fur,
      ${features.eyeColor} eyes, ${features.furPattern ?? ''},
      high quality, detailed, centered composition
    ''';
  }
}
```

## 安全规则

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 用户数据
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // 宠物数据
    match /pets/{petId} {
      allow read: if request.auth != null;
      allow create: if request.auth.uid == request.resource.data.userId;
      allow update, delete: if request.auth.uid == resource.data.userId;
    }

    // 道具数据（只读）
    match /items/{itemId} {
      allow read: if true;
      allow write: if false;
    }

    // 社区动态
    match /posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.userId
                    || request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['likeCount', 'likedBy']);
      allow delete: if request.auth.uid == resource.data.userId;

      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow delete: if request.auth.uid == resource.data.userId;
      }
    }

    // 成就定义（只读）
    match /achievements/{achievementId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // 用户头像
    match /users/{userId}/avatar/{fileName} {
      allow read: if true;
      allow write: if request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }

    // 宠物照片
    match /pets/{petId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }

    // 动态图片
    match /posts/{postId}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```
