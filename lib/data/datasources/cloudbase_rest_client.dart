import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/cloudbase_config.dart';
import '../../core/exceptions/cloudbase_exception.dart';
import '../../services/cloudbase_auth_http_service.dart';

/// CloudBase REST API 客户端
///
/// 封装所有 HTTP 请求逻辑，提供统一的错误处理和认证管理
class CloudbaseRestClient {
  final CloudbaseAuthHttpService _authService;

  CloudbaseRestClient(this._authService);

  String get _baseUrl => CloudbaseConfig.apiBaseUrl;

  /// 生成 UUID v4
  String generateUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// 获取认证 Token
  Future<String> _getAuthToken() async {
    final token = await _authService.getAccessToken();
    return token ?? CloudbaseConfig.publishableKey;
  }

  /// GET 请求 - 获取列表
  Future<Result<List<Map<String, dynamic>>>> getList(
    String table, {
    Map<String, String>? filters,
    String? select,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    try {
      final token = await _getAuthToken();
      final queryParams = <String, String>{};

      if (select != null) queryParams['select'] = select;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (orderBy != null) queryParams['order'] = orderBy;
      if (filters != null) queryParams.addAll(filters);

      var uri = Uri.parse('$_baseUrl/v1/rdb/rest/$table');
      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return const Success([]);
        final data = jsonDecode(response.body);
        if (data is List) {
          return Success(data.cast<Map<String, dynamic>>());
        }
        return const Success([]);
      } else {
        debugPrint('[CloudBase REST] GET $table failed: ${response.statusCode}');
        debugPrint('[CloudBase REST] Response: ${response.body}');
        return Failure(DatabaseException(
          'GET $table failed: ${response.statusCode}',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      debugPrint('[CloudBase REST] Network error: $e');
      return Failure(NetworkException('Network error: $e', originalError: e));
    }
  }

  /// GET 请求 - 获取单条记录
  Future<Result<Map<String, dynamic>?>> getOne(String table, String id) async {
    final result = await getList(table, filters: {'id': 'eq.$id'}, limit: 1);
    return result.map((list) => list.isNotEmpty ? list.first : null);
  }

  /// POST 请求 - 创建记录
  Future<Result<String?>> create(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _getAuthToken();
      final uri = Uri.parse('$_baseUrl/v1/rdb/rest/$table');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          final result = jsonDecode(response.body);
          if (result is List && result.isNotEmpty) {
            return Success(result.first['id']?.toString());
          }
        }
        return Success(data['id']?.toString());
      } else {
        debugPrint('[CloudBase REST] POST $table failed: ${response.statusCode}');
        debugPrint('[CloudBase REST] Response: ${response.body}');
        return Failure(DatabaseException(
          'POST $table failed: ${response.statusCode} - ${response.body}',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      debugPrint('[CloudBase REST] Network error: $e');
      return Failure(NetworkException('Network error: $e', originalError: e));
    }
  }

  /// PATCH 请求 - 更新记录
  Future<Result<void>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await _getAuthToken();
      final uri = Uri.parse('$_baseUrl/v1/rdb/rest/$table?id=eq.$id');

      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Prefer': 'return=minimal',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      } else {
        debugPrint('[CloudBase REST] PATCH $table failed: ${response.statusCode}');
        debugPrint('[CloudBase REST] Response: ${response.body}');
        return Failure(DatabaseException(
          'PATCH $table failed: ${response.statusCode} - ${response.body}',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      debugPrint('[CloudBase REST] Network error: $e');
      return Failure(NetworkException('Network error: $e', originalError: e));
    }
  }

  /// DELETE 请求 - 删除记录
  Future<Result<void>> delete(String table, String id) async {
    try {
      final token = await _getAuthToken();
      final uri = Uri.parse('$_baseUrl/v1/rdb/rest/$table?id=eq.$id');

      final response = await http.delete(uri, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      } else {
        debugPrint('[CloudBase REST] DELETE $table failed: ${response.statusCode}');
        debugPrint('[CloudBase REST] Response: ${response.body}');
        return Failure(DatabaseException(
          'DELETE $table failed: ${response.statusCode}',
          code: response.statusCode.toString(),
        ));
      }
    } catch (e) {
      debugPrint('[CloudBase REST] Network error: $e');
      return Failure(NetworkException('Network error: $e', originalError: e));
    }
  }
}
