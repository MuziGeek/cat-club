/// CloudBase 异常体系
///
/// 使用 sealed class 实现类型安全的异常分类
sealed class CloudbaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const CloudbaseException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'CloudbaseException($code): $message';
}

/// 网络异常
class NetworkException extends CloudbaseException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 认证异常
class AuthException extends CloudbaseException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 数据库异常
class DatabaseException extends CloudbaseException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 资源未找到异常
class NotFoundException extends CloudbaseException {
  const NotFoundException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// 验证异常
class ValidationException extends CloudbaseException {
  const ValidationException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Result 模式 - 统一成功/失败处理
///
/// 使用 sealed class 实现类型安全的结果处理
sealed class Result<T> {
  const Result();

  /// 创建成功结果
  factory Result.success(T data) = Success<T>;

  /// 创建失败结果
  factory Result.failure(CloudbaseException exception) = Failure<T>;
}

/// 成功结果
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// 失败结果
class Failure<T> extends Result<T> {
  final CloudbaseException exception;
  const Failure(this.exception);
}

/// Result 扩展方法
extension ResultExtension<T> on Result<T> {
  /// 是否成功
  bool get isSuccess => this is Success<T>;

  /// 是否失败
  bool get isFailure => this is Failure<T>;

  /// 获取数据（失败时返回 null）
  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;

  /// 获取异常（成功时返回 null）
  CloudbaseException? get exceptionOrNull =>
      isFailure ? (this as Failure<T>).exception : null;

  /// 折叠处理
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(CloudbaseException e) onFailure,
  }) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Failure(:final exception) => onFailure(exception),
    };
  }

  /// 映射成功值
  Result<R> map<R>(R Function(T data) mapper) {
    return switch (this) {
      Success(:final data) => Success(mapper(data)),
      Failure(:final exception) => Failure(exception),
    };
  }

  /// 异步映射成功值
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) mapper) async {
    return switch (this) {
      Success(:final data) => Success(await mapper(data)),
      Failure(:final exception) => Failure(exception),
    };
  }

  /// 获取数据或抛出异常
  T getOrThrow() {
    return switch (this) {
      Success(:final data) => data,
      Failure(:final exception) => throw exception,
    };
  }

  /// 获取数据或返回默认值
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success(:final data) => data,
      Failure() => defaultValue,
    };
  }
}
