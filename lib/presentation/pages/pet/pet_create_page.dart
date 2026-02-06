import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/pet_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/photo_upload_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/photo/photo_picker_sheet.dart';

/// 创建宠物页面
class PetCreatePage extends ConsumerStatefulWidget {
  const PetCreatePage({super.key});

  @override
  ConsumerState<PetCreatePage> createState() => _PetCreatePageState();
}

class _PetCreatePageState extends ConsumerState<PetCreatePage> {
  final _nameController = TextEditingController();
  PetSpecies _selectedSpecies = PetSpecies.cat;
  int _selectedPresetIndex = 0;
  File? _selectedPhoto;
  bool _isUploadingPhoto = false;
  bool _hasCheckedLimit = false;

  // 预设宠物形象
  final List<Map<String, dynamic>> _presets = [
    {'name': '橘猫', 'color': Colors.orange, 'furColor': 'orange', 'eyeColor': 'yellow'},
    {'name': '白猫', 'color': Colors.grey.shade200, 'furColor': 'white', 'eyeColor': 'blue'},
    {'name': '黑猫', 'color': Colors.black87, 'furColor': 'black', 'eyeColor': 'green'},
    {'name': '花猫', 'color': Colors.brown, 'furColor': 'brown', 'eyeColor': 'amber'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPetLimit();
    });
  }

  /// 检查宠物数量上限
  Future<void> _checkPetLimit() async {
    if (_hasCheckedLimit) return;
    _hasCheckedLimit = true;

    final userId = ref.read(currentUserIdProvider);

    if (userId != null) {
      final (canCreate, currentCount, maxCount) =
          await ref.read(petCreateProvider.notifier).canCreatePet(userId);

      if (!canCreate && mounted) {
        // 已达上限，提示用户
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('宠物数量已达上限'),
              ],
            ),
            content: Text(
              '你最多可以拥有 $maxCount 只宠物（当前 $currentCount 只）。\n\n如需创建新宠物，请先放生现有宠物。',
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.petRoom);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('返回'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请给你的宠物起个名字')),
      );
      return;
    }

    // 获取选中的预设
    final preset = _presets[_selectedPresetIndex];

    // 构建 PetAppearance
    final appearance = PetAppearance(
      furColor: preset['furColor'] as String,
      eyeColor: preset['eyeColor'] as String,
    );

    // 暂时跳过照片上传（Firebase Storage 需要 Blaze 计划）
    // TODO: 启用 Blaze 计划后取消注释以下代码
    /*
    String? photoUrl;
    if (_selectedPhoto != null) {
      setState(() => _isUploadingPhoto = true);

      final authState = ref.read(authStateProvider);
      final userId = authState.valueOrNull?.uid;

      if (userId != null) {
        photoUrl = await ref.read(photoUploadProvider.notifier).uploadPetPhoto(
              userId: userId,
            );
      }

      setState(() => _isUploadingPhoto = false);

      if (photoUrl == null && _selectedPhoto != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('照片上传失败，请重试')),
        );
        return;
      }
    }
    */

    // 如果选择了照片但无法上传，提示用户
    if (_selectedPhoto != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('照片功能暂未开放，将使用默认形象创建宠物'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 调用 petCreateProvider 创建宠物（不带照片）
    final petId = await ref.read(petCreateProvider.notifier).createPet(
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          appearance: appearance,
          // originalPhotoUrl: photoUrl,  // 暂时禁用
        );

    if (!mounted) return;

    if (petId != null) {
      // 清理照片上传状态
      ref.read(photoUploadProvider.notifier).reset();
      // 设置选中的宠物 ID
      ref.read(selectedPetIdProvider.notifier).state = petId;
      // 导航到宠物房间
      context.go(AppRoutes.petRoom);
    } else {
      // 显示错误
      final error = ref.read(petCreateProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: ${error ?? '未知错误'}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听创建状态
    final createState = ref.watch(petCreateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('创建宠物'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.petRoom),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 提示文字
            Text(
              '让我们创建你的第一只虚拟宠物吧！',
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: 32),

            // 物种选择
            Text('选择物种', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            _buildSpeciesSelector(),
            const SizedBox(height: 24),

            // 形象选择
            Text('选择形象', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            _buildPresetSelector(),
            const SizedBox(height: 24),

            // 上传照片入口
            _buildUploadOption(),
            const SizedBox(height: 24),

            // 宠物名称
            Text('宠物名称', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '给你的宠物起个名字吧',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 创建按钮
            AppButton(
              text: '创建宠物',
              onPressed: _handleCreate,
              isLoading: createState.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesSelector() {
    final species = [
      {'type': PetSpecies.cat, 'name': '猫咪', 'icon': Icons.pets},
      {'type': PetSpecies.dog, 'name': '狗狗', 'icon': Icons.pets},
      {'type': PetSpecies.rabbit, 'name': '兔子', 'icon': Icons.cruelty_free},
      {'type': PetSpecies.hamster, 'name': '仓鼠', 'icon': Icons.pets},
    ];

    return Row(
      children: species.map((s) {
        final isSelected = _selectedSpecies == s['type'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedSpecies = s['type'] as PetSpecies);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s['name'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPresetSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        itemBuilder: (context, index) {
          final preset = _presets[index];
          final isSelected = _selectedPresetIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedPresetIndex = index);
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: preset['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset['name'] as String,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUploadOption() {
    final photoState = ref.watch(photoUploadProvider);
    final hasPhoto = _selectedPhoto != null;

    return GestureDetector(
      onTap: _isUploadingPhoto ? null : _handleSelectPhoto,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasPhoto ? AppColors.primary.withOpacity(0.05) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPhoto ? AppColors.primary : AppColors.border,
            width: hasPhoto ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 照片预览或图标
            if (hasPhoto && _selectedPhoto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.file(
                    _selectedPhoto!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: AppColors.primary,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPhoto ? '已选择照片' : '上传宠物照片',
                    style: AppTextStyles.body1.copyWith(
                      color: hasPhoto ? AppColors.primary : null,
                      fontWeight: hasPhoto ? FontWeight.w600 : null,
                    ),
                  ),
                  Text(
                    hasPhoto ? '点击重新选择' : 'AI 将为你生成专属卡通形象',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (hasPhoto)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.textSecondary,
                onPressed: _handleClearPhoto,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textHint,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  /// 处理照片选择
  Future<void> _handleSelectPhoto() async {
    final selected = await PhotoPickerSheet.show(context);

    if (selected && mounted) {
      final previewFile = ref.read(photoUploadProvider).previewFile;
      if (previewFile != null) {
        setState(() {
          _selectedPhoto = previewFile;
        });
      }
    }
  }

  /// 清除已选择的照片
  void _handleClearPhoto() {
    ref.read(photoUploadProvider.notifier).clearPhoto();
    setState(() {
      _selectedPhoto = null;
    });
  }
}
