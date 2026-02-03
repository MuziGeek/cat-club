import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/photo_upload_provider.dart';
import '../../../services/storage_service.dart';

/// 照片来源选择底部弹窗
///
/// 提供相机和相册两个选项，选择后自动进入裁剪流程
class PhotoPickerSheet extends ConsumerWidget {
  /// 选择照片后的回调
  final VoidCallback? onPhotoSelected;

  /// 取消选择的回调
  final VoidCallback? onCancel;

  const PhotoPickerSheet({
    super.key,
    this.onPhotoSelected,
    this.onCancel,
  });

  /// 显示照片选择弹窗
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PhotoPickerSheet(
        onPhotoSelected: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadState = ref.watch(photoUploadProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '选择照片来源',
                style: AppTextStyles.h4,
              ),
            ),

            // 选项列表
            if (uploadState.isUploading)
              _buildUploadingState(uploadState)
            else
              _buildOptions(context, ref),

            // 取消按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: uploadState.isUploading ? null : onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '取消',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 相机选项
          _OptionTile(
            icon: Icons.camera_alt,
            iconColor: AppColors.primary,
            title: '拍照',
            subtitle: '使用相机拍摄宠物照片',
            onTap: () => _handlePickFromCamera(context, ref),
          ),

          const Divider(height: 1),

          // 相册选项
          _OptionTile(
            icon: Icons.photo_library,
            iconColor: Colors.green,
            title: '从相册选择',
            subtitle: '选择已有的宠物照片',
            onTap: () => _handlePickFromGallery(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState(PhotoUploadState state) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '正在处理照片...',
            style: AppTextStyles.body1,
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickFromCamera(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(photoUploadProvider.notifier);
    final success = await notifier.pickAndCrop(ImageSourceType.camera);

    if (success) {
      onPhotoSelected?.call();
    }
  }

  Future<void> _handlePickFromGallery(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(photoUploadProvider.notifier);
    final success = await notifier.pickAndCrop(ImageSourceType.gallery);

    if (success) {
      onPhotoSelected?.call();
    }
  }
}

/// 选项卡片
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
