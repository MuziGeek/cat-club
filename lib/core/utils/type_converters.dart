import 'dart:convert';

/// CloudBase MySQL 数据类型转换工具
///
/// 处理 MySQL 与 Dart 类型之间的转换，特别是：
/// - tinyint(1) -> bool
/// - JSON 字符串 -> Map/List
/// - 日期字符串 -> DateTime
class TypeConverters {
  TypeConverters._();

  /// MySQL tinyint(1) -> bool
  ///
  /// MySQL 的 tinyint(1) 返回 0/1，需要转换为 bool
  static bool parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  /// 安全解析 DateTime，带默认值
  static DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback ?? DateTime.now();
  }

  /// 安全解析可空 DateTime
  static DateTime? parseDateTimeNullable(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// 解析 JSON 字符串或对象为 List<String>
  ///
  /// 支持：
  /// - null -> []
  /// - JSON 字符串 '["a","b"]' -> ["a", "b"]
  /// - List 对象 -> List<String>
  static List<String> parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        final parsed = jsonDecode(value);
        if (parsed is List) {
          return List<String>.from(parsed.map((e) => e?.toString() ?? ''));
        }
      } catch (_) {}
      return [];
    }
    if (value is List) {
      return List<String>.from(value.map((e) => e?.toString() ?? ''));
    }
    return [];
  }

  /// 解析 JSON 字符串或对象为 Map<String, int>
  ///
  /// 用于背包 inventory 等字段
  static Map<String, int> parseIntMap(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      if (value.isEmpty) return {};
      try {
        final parsed = jsonDecode(value);
        if (parsed is Map) {
          return Map<String, int>.from(
            parsed.map((k, v) => MapEntry(
              k.toString(),
              v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0,
            )),
          );
        }
      } catch (_) {}
      return {};
    }
    if (value is Map) {
      return Map<String, int>.from(
        value.map((k, v) => MapEntry(
          k.toString(),
          v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0,
        )),
      );
    }
    return {};
  }

  /// 解析 JSON 字符串或对象为 Map<String, dynamic>
  ///
  /// 用于 status, stats, appearance 等嵌套 JSON 字段
  static Map<String, dynamic> parseJsonMap(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      if (value.isEmpty) return {};
      try {
        final parsed = jsonDecode(value);
        if (parsed is Map) {
          return Map<String, dynamic>.from(parsed);
        }
      } catch (_) {}
      return {};
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  /// 安全获取 int 值
  static int parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  /// 安全获取 String 值
  static String? parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  /// 将 List 编码为 JSON 字符串（用于存储）
  static String encodeList(List<dynamic> list) {
    return jsonEncode(list);
  }

  /// 将 Map 编码为 JSON 字符串（用于存储）
  static String encodeMap(Map<String, dynamic> map) {
    return jsonEncode(map);
  }
}
