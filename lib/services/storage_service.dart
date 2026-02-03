import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// 图片来源类型
enum ImageSourceType {
  camera,
  gallery,
}

/// 上传进度回调
typedef UploadProgressCallback = void Function(double progress);

/// Firebase Storage 服务
///
/// 封装图片选择、裁剪和上传功能
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // ==================== 图片选择 ====================

  /// 从相册或相机选择图片
  ///
  /// [source] 图片来源（相机/相册）
  /// [maxWidth] 最大宽度（可选）
  /// [maxHeight] 最大高度（可选）
  /// [imageQuality] 图片质量 0-100（可选）
  Future<File?> pickImage({
    required ImageSourceType source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final imageSource = source == ImageSourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery;

      final pickedFile = await _picker.pickImage(
        source: imageSource,
        maxWidth: maxWidth ?? 1920,
        maxHeight: maxHeight ?? 1920,
        imageQuality: imageQuality ?? 85,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('选择图片失败: $e');
      return null;
    }
  }

  // ==================== 图片裁剪 ====================

  /// 裁剪图片
  ///
  /// [imageFile] 原始图片文件
  /// [aspectRatio] 裁剪比例（可选，默认 1:1）
  /// [maxWidth] 最大宽度（可选）
  /// [maxHeight] 最大高度（可选）
  Future<File?> cropImage({
    required File imageFile,
    CropAspectRatio? aspectRatio,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: aspectRatio ?? const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: maxWidth ?? 800,
        maxHeight: maxHeight ?? 800,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪图片',
            toolbarColor: const Color(0xFFFF6B6B),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: '裁剪图片',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      debugPrint('裁剪图片失败: $e');
      return null;
    }
  }

  // ==================== 图片上传 ====================

  /// 上传宠物照片
  ///
  /// [userId] 用户 ID
  /// [imageFile] 图片文件
  /// [onProgress] 上传进度回调（可选）
  ///
  /// 返回上传后的下载 URL
  Future<String?> uploadPetPhoto({
    required String userId,
    required File imageFile,
    UploadProgressCallback? onProgress,
  }) async {
    return _uploadImage(
      folder: 'pets/$userId/photos',
      imageFile: imageFile,
      onProgress: onProgress,
    );
  }

  /// 上传宠物头像
  ///
  /// [userId] 用户 ID
  /// [petId] 宠物 ID
  /// [imageFile] 图片文件
  /// [onProgress] 上传进度回调（可选）
  ///
  /// 返回上传后的下载 URL
  Future<String?> uploadPetAvatar({
    required String userId,
    required String petId,
    required File imageFile,
    UploadProgressCallback? onProgress,
  }) async {
    return _uploadImage(
      folder: 'pets/$userId/avatars',
      fileName: petId,
      imageFile: imageFile,
      onProgress: onProgress,
    );
  }

  /// 上传用户头像
  ///
  /// [userId] 用户 ID
  /// [imageFile] 图片文件
  /// [onProgress] 上传进度回调（可选）
  ///
  /// 返回上传后的下载 URL
  Future<String?> uploadUserAvatar({
    required String userId,
    required File imageFile,
    UploadProgressCallback? onProgress,
  }) async {
    return _uploadImage(
      folder: 'users/$userId',
      fileName: 'avatar',
      imageFile: imageFile,
      onProgress: onProgress,
    );
  }

  /// 通用图片上传方法
  Future<String?> _uploadImage({
    required String folder,
    required File imageFile,
    String? fileName,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      // 生成文件名
      final extension = path.extension(imageFile.path).toLowerCase();
      final validExtension =
          ['.jpg', '.jpeg', '.png', '.webp'].contains(extension)
              ? extension
              : '.jpg';
      final finalFileName = fileName ?? _uuid.v4();
      final storagePath = '$folder/$finalFileName$validExtension';

      // 创建上传引用
      final ref = _storage.ref().child(storagePath);

      // 设置元数据
      final metadata = SettableMetadata(
        contentType: 'image/${validExtension.substring(1)}',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 执行上传
      final uploadTask = ref.putFile(imageFile, metadata);

      // 监听上传进度
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((event) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        });
      }

      // 等待上传完成
      await uploadTask;

      // 获取下载 URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('上传图片失败: $e');
      return null;
    }
  }

  // ==================== 图片删除 ====================

  /// 删除图片
  ///
  /// [url] 图片的下载 URL
  Future<bool> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('删除图片失败: $e');
      return false;
    }
  }

  // ==================== 便捷方法 ====================

  /// 选择并裁剪图片（一站式）
  ///
  /// [source] 图片来源
  /// [aspectRatio] 裁剪比例（可选）
  Future<File?> pickAndCropImage({
    required ImageSourceType source,
    CropAspectRatio? aspectRatio,
  }) async {
    final pickedFile = await pickImage(source: source);
    if (pickedFile == null) return null;

    return cropImage(
      imageFile: pickedFile,
      aspectRatio: aspectRatio,
    );
  }

  /// 选择、裁剪并上传宠物照片（一站式）
  ///
  /// [userId] 用户 ID
  /// [source] 图片来源
  /// [onProgress] 上传进度回调（可选）
  Future<String?> pickCropAndUploadPetPhoto({
    required String userId,
    required ImageSourceType source,
    UploadProgressCallback? onProgress,
  }) async {
    final croppedFile = await pickAndCropImage(source: source);
    if (croppedFile == null) return null;

    return uploadPetPhoto(
      userId: userId,
      imageFile: croppedFile,
      onProgress: onProgress,
    );
  }
}

