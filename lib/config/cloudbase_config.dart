/// 腾讯云 CloudBase 配置
///
/// 云开发环境配置参数
class CloudbaseConfig {
  CloudbaseConfig._();

  /// 环境 ID
  static const String envId = 'cat-hub-6gcp6yje9dd382c7';

  /// 区域
  static const String region = 'ap-shanghai';

  /// HTTP API 基础 URL
  static const String apiBaseUrl =
      'https://$envId.api.tcloudbasegateway.com';

  /// Publishable Key (用于客户端认证)
  static const String publishableKey =
      'eyJhbGciOiJSUzI1NiIsImtpZCI6IjlkMWRjMzFlLWI0ZDAtNDQ4Yi1hNzZmLWIwY2M2M2Q4MTQ5OCJ9.eyJpc3MiOiJodHRwczovL2NhdC1odWItNmdjcDZ5amU5ZGQzODJjNy5hcC1zaGFuZ2hhaS50Y2ItYXBpLnRlbmNlbnRjbG91ZGFwaS5jb20iLCJzdWIiOiJhbm9uIiwiYXVkIjoiY2F0LWh1Yi02Z2NwNnlqZTlkZDM4MmM3IiwiZXhwIjo0MDczODgxMTkxLCJpYXQiOjE3NzAxOTc5OTEsIm5vbmNlIjoiNzdlaHhUbDZReldTWms5TFVCWjVLZyIsImF0X2hhc2giOiI3N2VoeFRsNlF6V1NaazlMVUJaNUtnIiwibmFtZSI6IkFub255bW91cyIsInNjb3BlIjoiYW5vbnltb3VzIiwicHJvamVjdF9pZCI6ImNhdC1odWItNmdjcDZ5amU5ZGQzODJjNyIsIm1ldGEiOnsicGxhdGZvcm0iOiJQdWJsaXNoYWJsZUtleSJ9LCJ1c2VyX3R5cGUiOiIiLCJjbGllbnRfdHlwZSI6ImNsaWVudF91c2VyIiwiaXNfc3lzdGVtX2FkbWluIjpmYWxzZX0.oMPK5dW_3brw3YvixNFfgSeMF6FxxINprJUCyQpgDmD72cuvhadFX_5MXn8r8LtNBZa5D2OzSZ991TGSIPBI46Cwk_8EZJSJ328DZ8RP4VhA6NW8lhMwAAnTRgV79WUv8OFVcHve4zLylnx-xb3pnzfw3vxPWxv0C7SD29lJNJElLu53KQx6i86FahoKQKCtiX3bJkbBQ8HU-agKYmIardpK6bueb7RtQJVkclXxwA1a7WbBqn-ESgArBOfI5Itsz_4JC2WqKGzzekxJAO6QpnyC1MDQSL9oAoMHXx_ZWvJSYM2j-ycrWZVZKo35hRGhNhzmvXWqnTI9HBYJ_waYCg';

  /// 请求超时时间（毫秒）
  static const int timeout = 30000;

  /// 是否启用调试模式
  static const bool debug = true;
}
