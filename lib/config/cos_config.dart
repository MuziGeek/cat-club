/// 腾讯云 COS 配置
///
/// 用于配置对象存储服务的连接参数
///
/// ⚠️ 安全提醒：
/// - 当前配置仅用于开发测试
/// - 生产环境应使用 STS 临时密钥服务
/// - 发布前应将密钥移至环境变量或后端服务
class CosConfig {
  CosConfig._();

  /// 存储桶名称
  static const String bucket = 'cathub-1309463551';

  /// 地域
  static const String region = 'ap-shanghai';

  /// SecretId
  static const String secretId = 'PLACEHOLDER_SECRET_ID';

  /// SecretKey
  /// TODO: 生产环境应迁移至 STS 临时密钥
  static const String secretKey = 'PLACEHOLDER_SECRET_KEY';

  /// COS 访问域名
  static String get endpoint => 'https://$bucket.cos.$region.myqcloud.com';

  /// 验证配置是否有效
  static bool get isConfigured => secretKey.isNotEmpty;
}
