import 'dart:io';

/// 腾讯云 COS 配置
///
/// 用于配置对象存储服务的连接参数
///
/// ⚠️ 安全提醒：
/// - 密钥从环境变量读取，不要硬编码
/// - 生产环境应使用 STS 临时密钥服务
/// - 开发时请设置环境变量或创建 .env 文件
class CosConfig {
  CosConfig._();

  /// 存储桶名称
  static const String bucket = 'cathub-1309463551';

  /// 地域
  static const String region = 'ap-shanghai';

  /// SecretId - 从环境变量读取
  static String get secretId =>
      Platform.environment['TENCENT_COS_SECRET_ID'] ?? '';

  /// SecretKey - 从环境变量读取
  static String get secretKey =>
      Platform.environment['TENCENT_COS_SECRET_KEY'] ?? '';

  /// COS 访问域名
  static String get endpoint => 'https://$bucket.cos.$region.myqcloud.com';

  /// 验证配置是否有效
  static bool get isConfigured =>
      secretId.isNotEmpty && secretKey.isNotEmpty;
}
