import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/photo_upload_provider.dart';
import '../../../services/storage_service.dart';

/// 照片预览确认对话框
///
/// 显示裁剪后的照片预览，支持确认、重新选择和上传进度显示
class PhotoPreviewDialog extends ConsumerWidget {
  /// 确认后的回调，返回上传后的 URL
  final void Function(String? url)? onConfirm;

  /// 取消回调
  final VoidCallback? onCancel;

  /// 重新选择回调
  final VoidCallback? onReselect;

  /// 用户 ID（用于上传）
  final String userId;

  /// 宠物 ID（可选，更新时使用）
  final String? petId;

  /// 是否自动上传
  final bool autoUpload;

  const PhotoPreviewDialog({
    super.key,
    required this.userId,
    this.petId,
    this.onConfirm,
    this.onCancel,
    this.onReselect,
    this.autoUpload = false,
  });

  /// 显示照片预览对话框
  ///
  /// 返回上传后的 URL，如果取消则返回 null
  static Future<String?> show(
    BuildContext context, {
    required String userId,
    String? petId,
    bool autoUpload = false,
  }) async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PhotoPreviewDialog(
        userId: userId,
        petId: petId,
        autoUpload: autoUpload,
        onConfirm: (url) => Navigator.of(context).pop(url),
        onCancel: () => Navigator.of(context).pop(null),
        onReselect: () => Navigator.of(context).pop('reselect'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(photoUploadProvider);
    final previewFile = uploadState.previewFile;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              uploadState.isUploading ? '正在上传' : '预览照片',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 16),

            // 照片预览
            if (previewFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        previewFile,
                        fit: BoxFit.cover,
                      ),

                      // 上传进度遮罩
                      if (uploadState.isUploading)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CircularProgressIndicator(
                                        value: uploadState.progress,
                                        strokeWidth: 4,
                                        backgroundColor: Colors.white24,
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          '${uploadState.progressPercent}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '正在上传...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 错误提示
            if (uploadState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        uploadState.error!,
                        style: AppTextStyles.caption.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 按钮区域
            if (!uploadState.isUploading) ...[
              // 确认按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: previewFile != null
                      ? () => _handleConfirm(context, ref)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '确认使用',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 重新选择和取消
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _handleReselect(context, ref),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '重新选择',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _handleCancel(context, ref),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '取消',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirm(BuildContext context, WidgetRef ref) async {
    if (autoUpload) {
      // 自动上传模式
      final url = await ref.read(photoUploadProvider.notifier).uploadPetPhoto(
            userId: userId,
            petId: petId,
          );
      onConfirm?.call(url);
    } else {
      // 不自动上传，直接确认
      onConfirm?.call(null);
    }
  }

  void _handleReselect(BuildContext context, WidgetRef ref) {
    ref.read(photoUploadProvider.notifier).clearPhoto();
    onReselect?.call();
  }

  void _handleCancel(BuildContext context, WidgetRef ref) {
    ref.read(photoUploadProvider.notifier).clearPhoto();
    onCancel?.call();
  }
}

/// 照片选择和预览的完整流程
///
/// 返回选中并裁剪后的文件，如果取消返回 null
Future<File?> showPhotoPickerFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  // 显示来源选择弹窗
  final selected = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _PhotoSourceSheet(
      onCameraSelected: () async {
        final success = await ref
            .read(photoUploadProvider.notifier)
            .pickAndCrop(ImageSourceType.camera);
        if (context.mounted) {
          Navigator.of(context).pop(success);
        }
      },
      onGallerySelected: () async {
        final success = await ref
            .read(photoUploadProvider.notifier)
            .pickAndCrop(ImageSourceType.gallery);
        if (context.mounted) {
          Navigator.of(context).pop(success);
        }
      },
      onCancel: () => Navigator.of(context).pop(false),
    ),
  );

  if (selected != true) return null;

  // 获取选中的文件
  final state = ref.read(photoUploadProvider);
  return state.previewFile;
}

/// 照片来源选择弹窗（内部使用）
class _PhotoSourceSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;
  final VoidCallback onCancel;

  const _PhotoSourceSheet({
    required this.onCameraSelected,
    required this.onGallerySelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择照片来源', style: AppTextStyles.h4),
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: const Text('拍照'),
              subtitle: const Text('使用相机拍摄'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onCameraSelected,
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('从相册选择'),
              subtitle: const Text('选择已有照片'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onGallerySelected,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('取消'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
