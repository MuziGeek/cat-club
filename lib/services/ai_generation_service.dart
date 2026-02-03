import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI 生成服务 Provider
final aiGenerationServiceProvider = Provider<AiGenerationService>((ref) {
  return AiGenerationService();
});

/// 生成状态
enum GenerationStatus {
  idle,
  extractingFeatures,
  generating,
  completed,
  failed,
}

/// 生成进度回调
typedef GenerationProgressCallback = void Function(
  GenerationStatus status,
  double progress,
  String? message,
);

/// AI 图像生成服务
/// 使用 Replicate API 生成宠物卡通形象
class AiGenerationService {
  final Dio _dio = Dio();

  // Replicate API 配置
  // 注意：生产环境应通过 Firebase Cloud Functions 代理调用，隐藏 API Key
  static const String _replicateBaseUrl = 'https://api.replicate.com/v1';

  // SDXL 模型 - 高质量图像生成
  static const String _sdxlModel =
      'stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b';

  // 轮询间隔
  static const Duration _pollInterval = Duration(seconds: 2);

  // 最大等待时间
  static const Duration _maxWaitTime = Duration(minutes: 5);

  /// 可用的艺术风格
  static const Map<String, String> styles = {
    'cute': '可爱风',
    'anime': '动漫风',
    'realistic': '写实风',
  };

  /// 风格对应的 Prompt 模板
  static const Map<String, String> _stylePrompts = {
    'cute':
        'chibi style, cute, kawaii, round features, big sparkly eyes, soft pastel colors, adorable',
    'anime':
        'anime style, detailed, expressive eyes, soft cel shading, vibrant colors, studio ghibli inspired',
    'realistic':
        'semi-realistic digital art, detailed fur texture, soft lighting, professional portrait, artstation quality',
  };

  /// 负面提示词
  static const String _negativePrompt =
      'ugly, blurry, low quality, distorted, deformed, bad anatomy, watermark, text, signature, cropped';

  /// 从照片生成卡通形象
  ///
  /// [imageUrl] 原始照片 URL
  /// [style] 艺术风格 (cute/anime/realistic)
  /// [features] 宠物特征
  /// [apiKey] Replicate API Key
  /// [onProgress] 进度回调
  ///
  /// 返回生成的图片 URL 列表（4张候选）
  Future<List<String>> generateCartoonAvatars({
    required String imageUrl,
    required String style,
    required PetFeatures features,
    required String apiKey,
    GenerationProgressCallback? onProgress,
  }) async {
    onProgress?.call(GenerationStatus.generating, 0.0, '正在生成卡通形象...');

    try {
      final prompt = _buildPrompt(style, features);

      // 创建预测请求
      final predictionId = await _createPrediction(
        apiKey: apiKey,
        prompt: prompt,
        imageUrl: imageUrl,
        numOutputs: 4,
      );

      onProgress?.call(GenerationStatus.generating, 0.2, '已提交生成请求...');

      // 轮询等待结果
      final result = await _pollForResult(
        apiKey: apiKey,
        predictionId: predictionId,
        onProgress: (progress) {
          onProgress?.call(
            GenerationStatus.generating,
            0.2 + progress * 0.7,
            '正在生成中...',
          );
        },
      );

      onProgress?.call(GenerationStatus.completed, 1.0, '生成完成！');
      return result;
    } catch (e) {
      onProgress?.call(GenerationStatus.failed, 0.0, '生成失败: $e');
      rethrow;
    }
  }

  /// 创建 Replicate 预测
  Future<String> _createPrediction({
    required String apiKey,
    required String prompt,
    required String imageUrl,
    int numOutputs = 4,
  }) async {
    final response = await _dio.post(
      '$_replicateBaseUrl/predictions',
      options: Options(
        headers: {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'version': _sdxlModel.split(':').last,
        'input': {
          'prompt': prompt,
          'negative_prompt': _negativePrompt,
          'image': imageUrl,
          'num_outputs': numOutputs,
          'width': 768,
          'height': 768,
          'num_inference_steps': 30,
          'guidance_scale': 7.5,
          'scheduler': 'K_EULER',
        },
      },
    );

    if (response.statusCode != 201) {
      throw Exception('创建预测失败: ${response.statusCode}');
    }

    final data = response.data as Map<String, dynamic>;
    return data['id'] as String;
  }

  /// 轮询获取预测结果
  Future<List<String>> _pollForResult({
    required String apiKey,
    required String predictionId,
    void Function(double progress)? onProgress,
  }) async {
    final startTime = DateTime.now();

    while (true) {
      // 检查超时
      if (DateTime.now().difference(startTime) > _maxWaitTime) {
        throw TimeoutException('生成超时，请稍后重试');
      }

      final response = await _dio.get(
        '$_replicateBaseUrl/predictions/$predictionId',
        options: Options(
          headers: {
            'Authorization': 'Token $apiKey',
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String;

      switch (status) {
        case 'succeeded':
          final output = data['output'];
          if (output is List) {
            return output.cast<String>();
          }
          throw Exception('无效的输出格式');

        case 'failed':
        case 'canceled':
          final error = data['error'] ?? '未知错误';
          throw Exception('生成失败: $error');

        case 'processing':
          // 计算进度
          final logs = data['logs'] as String? ?? '';
          final progressMatch = RegExp(r'(\d+)%').firstMatch(logs);
          if (progressMatch != null) {
            final percent = int.parse(progressMatch.group(1)!) / 100;
            onProgress?.call(percent);
          }
          break;

        default:
          // starting 或其他状态
          break;
      }

      await Future.delayed(_pollInterval);
    }
  }

  /// 构建生成 Prompt
  String _buildPrompt(String style, PetFeatures features) {
    final stylePrompt = _stylePrompts[style] ?? _stylePrompts['cute']!;

    final parts = <String>[
      stylePrompt,
      'a ${features.species}',
      '${features.furColor} fur color',
      '${features.eyeColor} eyes',
    ];

    if (features.breed != null) {
      parts.add('${features.breed} breed');
    }

    if (features.furPattern != null) {
      parts.add('${features.furPattern} pattern');
    }

    if (features.specialMarks != null) {
      parts.add(features.specialMarks!);
    }

    parts.addAll([
      'high quality',
      'detailed',
      'centered composition',
      'clean white background',
      'single character',
      'full body',
    ]);

    return parts.join(', ');
  }

  /// 提取宠物特征（使用 GPT-4 Vision）
  ///
  /// [imageUrl] 图片 URL
  /// [openAiApiKey] OpenAI API Key
  Future<PetFeatures> extractFeatures({
    required String imageUrl,
    required String openAiApiKey,
    GenerationProgressCallback? onProgress,
  }) async {
    onProgress?.call(GenerationStatus.extractingFeatures, 0.0, '正在分析照片...');

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $openAiApiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a pet photo analyzer. Analyze the pet in the image and extract its features.
Return a JSON object with these fields:
- species: "cat" or "dog" or other animal type
- breed: specific breed if identifiable, null otherwise
- furColor: main fur color (e.g., "orange", "black", "white", "brown")
- furPattern: pattern type if any (e.g., "tabby", "spotted", "solid"), null if solid color
- eyeColor: eye color (e.g., "yellow", "green", "blue", "brown")
- specialMarks: any unique markings or features, null if none

Respond with ONLY the JSON object, no other text.'''
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': imageUrl},
                },
                {
                  'type': 'text',
                  'text': 'Analyze this pet photo and extract its features.',
                },
              ],
            },
          ],
          'max_tokens': 500,
        },
      );

      onProgress?.call(GenerationStatus.extractingFeatures, 0.8, '正在解析特征...');

      final data = response.data as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;

      // 解析 JSON
      final jsonStr = _extractJson(content);
      final featuresJson = jsonDecode(jsonStr) as Map<String, dynamic>;

      onProgress?.call(GenerationStatus.extractingFeatures, 1.0, '特征提取完成');

      return PetFeatures.fromJson(featuresJson);
    } catch (e) {
      debugPrint('特征提取失败: $e');
      onProgress?.call(GenerationStatus.failed, 0.0, '特征提取失败');

      // 返回默认特征
      return PetFeatures(
        species: 'cat',
        furColor: 'orange',
        eyeColor: 'yellow',
      );
    }
  }

  /// 从文本中提取 JSON
  String _extractJson(String text) {
    // 尝试找到 JSON 对象
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');

    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }

    return text;
  }

  /// 快速生成（不需要特征提取，使用用户选择的预设）
  ///
  /// [species] 物种
  /// [style] 风格
  /// [furColor] 毛色
  /// [apiKey] Replicate API Key
  Future<List<String>> quickGenerate({
    required String species,
    required String style,
    required String furColor,
    required String apiKey,
    String? eyeColor,
    GenerationProgressCallback? onProgress,
  }) async {
    final features = PetFeatures(
      species: species,
      furColor: furColor,
      eyeColor: eyeColor ?? 'yellow',
    );

    // 使用一个默认的参考图片 URL（可以是应用内置的示例图）
    return generateCartoonAvatars(
      imageUrl: '', // 不使用参考图，纯文本生成
      style: style,
      features: features,
      apiKey: apiKey,
      onProgress: onProgress,
    );
  }

  /// 使用本地 Firebase Functions 代理调用（推荐生产环境使用）
  ///
  /// 这样可以隐藏 API Key，在服务端安全调用
  Future<List<String>> generateViaCloudFunction({
    required String imageUrl,
    required String style,
    required PetFeatures features,
    required String userId,
    GenerationProgressCallback? onProgress,
  }) async {
    onProgress?.call(GenerationStatus.generating, 0.0, '正在生成卡通形象...');

    try {
      // 调用 Firebase Cloud Functions
      final response = await _dio.post(
        'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/generatePetAvatar',
        data: {
          'imageUrl': imageUrl,
          'style': style,
          'features': features.toJson(),
          'userId': userId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Cloud Function 调用失败: ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final images = (data['images'] as List).cast<String>();

      onProgress?.call(GenerationStatus.completed, 1.0, '生成完成！');
      return images;
    } catch (e) {
      onProgress?.call(GenerationStatus.failed, 0.0, '生成失败: $e');
      rethrow;
    }
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
      species: json['species'] as String? ?? 'cat',
      breed: json['breed'] as String?,
      furColor: json['furColor'] as String? ?? 'orange',
      furPattern: json['furPattern'] as String?,
      eyeColor: json['eyeColor'] as String? ?? 'yellow',
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

  /// 创建副本
  PetFeatures copyWith({
    String? species,
    String? breed,
    String? furColor,
    String? furPattern,
    String? eyeColor,
    String? specialMarks,
  }) {
    return PetFeatures(
      species: species ?? this.species,
      breed: breed ?? this.breed,
      furColor: furColor ?? this.furColor,
      furPattern: furPattern ?? this.furPattern,
      eyeColor: eyeColor ?? this.eyeColor,
      specialMarks: specialMarks ?? this.specialMarks,
    );
  }
}
