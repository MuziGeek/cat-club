import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../services/storage_service.dart';

part 'photo_upload_provider.freezed.dart';

/// 照片上传状态
@freezed
class PhotoUploadState with _$PhotoUploadState {
  const factory PhotoUploadState({
    /// 选中的文件
    File? selectedFile,

    /// 裁剪后的文件
    File? croppedFile,

    /// 是否正在上传
    @Default(false) bool isUploading,

    /// 上传进度 (0.0 - 1.0)
    @Default(0.0) double progress,

    /// 上传后的 URL
    String? uploadedUrl,

    /// 错误信息
    String? error,
  }) = _PhotoUploadState;
}

/// 照片上传状态扩展
extension PhotoUploadStateX on PhotoUploadState {
  /// 是否有待上传的照片
  bool get hasPhoto => croppedFile != null || selectedFile != null;

  /// 获取预览文件（优先裁剪后的）
  File? get previewFile => croppedFile ?? selectedFile;

  /// 上传进度百分比
  int get progressPercent => (progress * 100).round();
}

/// 照片上传 Notifier
class PhotoUploadNotifier extends StateNotifier<PhotoUploadState> {
  final StorageService _storageService;

  PhotoUploadNotifier(this._storageService) : super(const PhotoUploadState());

  /// 从相机选择照片
  Future<bool> pickFromCamera() async {
    try {
      state = state.copyWith(error: null);

      final file = await _storageService.pickImage(
        source: ImageSourceType.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return false;

      state = state.copyWith(selectedFile: file, croppedFile: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: '选择照片失败: $e');
      return false;
    }
  }

  /// 从相册选择照片
  Future<bool> pickFromGallery() async {
    try {
      state = state.copyWith(error: null);

      final file = await _storageService.pickImage(
        source: ImageSourceType.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return false;

      state = state.copyWith(selectedFile: file, croppedFile: null);
      return true;
    } catch (e) {
      state = state.copyWith(error: '选择照片失败: $e');
      return false;
    }
  }

  /// 裁剪当前选中的照片
  Future<bool> cropImage() async {
    final file = state.selectedFile;
    if (file == null) {
      state = state.copyWith(error: '没有选中的照片');
      return false;
    }

    try {
      state = state.copyWith(error: null);

      final croppedFile = await _storageService.cropImage(
        imageFile: file,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (croppedFile == null) return false;

      state = state.copyWith(croppedFile: croppedFile);
      return true;
    } catch (e) {
      state = state.copyWith(error: '裁剪照片失败: $e');
      return false;
    }
  }

  /// 选择并裁剪照片（一站式）
  Future<bool> pickAndCrop(ImageSourceType source) async {
    try {
      state = state.copyWith(error: null);

      final croppedFile = await _storageService.pickAndCropImage(
        source: source,
      );

      if (croppedFile == null) return false;

      state = state.copyWith(
        selectedFile: croppedFile,
        croppedFile: croppedFile,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: '选择照片失败: $e');
      return false;
    }
  }

  /// 上传宠物照片
  ///
  /// [userId] 用户 ID
  /// [petId] 宠物 ID（可选，更新时使用）
  Future<String?> uploadPetPhoto({
    required String userId,
    String? petId,
  }) async {
    final file = state.previewFile;
    if (file == null) {
      state = state.copyWith(error: '没有待上传的照片');
      return null;
    }

    try {
      state = state.copyWith(
        isUploading: true,
        progress: 0.0,
        error: null,
      );

      String? url;

      if (petId != null) {
        // 更新现有宠物头像
        url = await _storageService.uploadPetAvatar(
          userId: userId,
          petId: petId,
          imageFile: file,
          onProgress: (progress) {
            state = state.copyWith(progress: progress);
          },
        );
      } else {
        // 新宠物照片
        url = await _storageService.uploadPetPhoto(
          userId: userId,
          imageFile: file,
          onProgress: (progress) {
            state = state.copyWith(progress: progress);
          },
        );
      }

      if (url == null) {
        state = state.copyWith(
          isUploading: false,
          error: '上传失败，请重试',
        );
        return null;
      }

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        uploadedUrl: url,
      );

      return url;
    } catch (e) {
      debugPrint('上传宠物照片失败: $e');
      state = state.copyWith(
        isUploading: false,
        error: '上传失败: $e',
      );
      return null;
    }
  }

  /// 清除选中的照片
  void clearPhoto() {
    state = state.copyWith(
      selectedFile: null,
      croppedFile: null,
      uploadedUrl: null,
    );
  }

  /// 重置所有状态
  void reset() {
    state = const PhotoUploadState();
  }
}

/// 照片上传 Provider
final photoUploadProvider =
    StateNotifierProvider<PhotoUploadNotifier, PhotoUploadState>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return PhotoUploadNotifier(storageService);
});
