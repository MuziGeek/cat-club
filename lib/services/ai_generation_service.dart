/// AI 图像生成服务
/// 使用 Replicate API 生成宠物卡通形象
class AiGenerationService {
  // TODO: 配置 Replicate API Key
  static const String _baseUrl = 'https://api.replicate.com/v1';

  /// 可用的艺术风格
  static const Map<String, String> styles = {
    'cute': '可爱风',
    'anime': '动漫风',
    'realistic': '写实风',
  };

  /// 风格对应的 Prompt
  static const Map<String, String> _stylePrompts = {
    'cute': 'chibi style, cute, kawaii, round features, big eyes',
    'anime': 'anime style, detailed, expressive eyes, soft shading',
    'realistic': 'semi-realistic, detailed fur, soft lighting, portrait',
  };

  /// 从照片生成卡通形象
  ///
  /// [imageUrl] 原始照片 URL
  /// [style] 艺术风格 (cute/anime/realistic)
  /// [features] 宠物特征（从 GPT-4V 提取）
  ///
  /// 返回生成的图片 URL 列表（4张）
  Future<List<String>> generateCartoonAvatars({
    required String imageUrl,
    required String style,
    required PetFeatures features,
  }) async {
    final prompt = _buildPrompt(style, features);

    // TODO: 实现 Replicate API 调用
    // 1. 创建 prediction
    // 2. 轮询获取结果
    // 3. 返回生成的图片 URL

    throw UnimplementedError('AI 生成服务待实现');
  }

  /// 构建生成 Prompt
  String _buildPrompt(String style, PetFeatures features) {
    final stylePrompt = _stylePrompts[style] ?? _stylePrompts['cute']!;

    return '''
$stylePrompt ${features.species},
${features.furColor} fur color,
${features.eyeColor} eyes,
${features.furPattern != null ? '${features.furPattern} pattern,' : ''}
${features.specialMarks != null ? '${features.specialMarks},' : ''}
high quality, detailed, centered composition, white background
''';
  }

  /// 提取宠物特征（使用 GPT-4 Vision）
  Future<PetFeatures> extractFeatures(String imageUrl) async {
    // TODO: 实现 GPT-4 Vision API 调用
    // Prompt: 分析宠物照片，提取特征

    throw UnimplementedError('特征提取服务待实现');
  }
}

/// 宠物特征数据
class PetFeatures {
  final String species;
  final String? breed;
  final String furColor;
  final String? furPattern;
  final String eyeColor;
  final String? specialMarks;

  PetFeatures({
    required this.species,
    this.breed,
    required this.furColor,
    this.furPattern,
    required this.eyeColor,
    this.specialMarks,
  });

  factory PetFeatures.fromJson(Map<String, dynamic> json) {
    return PetFeatures(
      species: json['species'] as String,
      breed: json['breed'] as String?,
      furColor: json['furColor'] as String,
      furPattern: json['furPattern'] as String?,
      eyeColor: json['eyeColor'] as String,
      specialMarks: json['specialMarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'breed': breed,
      'furColor': furColor,
      'furPattern': furPattern,
      'eyeColor': eyeColor,
      'specialMarks': specialMarks,
    };
  }
}
