import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/pet_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../services/storage_service.dart';
import '../../router/app_router.dart';
import 'release_confirm_dialog.dart';

/// 宠物切换栏组件
///
/// 显示用户所有宠物的头像，支持：
/// - 点击切换当前宠物
/// - 长按宠物头像显示放生菜单
/// - 始终显示添加按钮（达到上限时点击提示）
class PetSelector extends ConsumerWidget {
  const PetSelector({super.key});

  /// 最大宠物数量（与 UserModel.maxPets 默认值一致）
  static const int maxPets = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(userPetsProvider);
    final selectedId = ref.watch(selectedPetIdProvider);

    return petsAsync.when(
      data: (pets) => _buildSelector(context, ref, pets, selectedId),
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSelector(
    BuildContext context,
    WidgetRef ref,
    List<PetModel> pets,
    String? selectedId,
  ) {
    if (pets.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 宠物头像列表
          ...pets.map((pet) => _buildPetAvatar(
                context,
                ref,
                pet: pet,
                isSelected: pet.id == selectedId,
              )),

          // 添加按钮（始终显示，达到上限时点击提示）
          _buildAddButton(context, pets.length),
        ],
      ),
    );
  }

  /// 构建宠物头像
  Widget _buildPetAvatar(
    BuildContext context,
    WidgetRef ref, {
    required PetModel pet,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          ref.read(selectedPetIdProvider.notifier).state = pet.id;
        }
      },
      // 长按显示放生菜单
      onLongPress: () => _showReleaseMenu(context, ref, pet),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: _buildAvatarContent(pet, isSelected),
      ),
    );
  }

  /// 构建头像内容
  Widget _buildAvatarContent(PetModel pet, bool isSelected) {
    final size = isSelected ? 44.0 : 40.0;

    // 如果有卡通头像，显示头像
    if (pet.cartoonAvatarUrl != null && pet.cartoonAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(pet.cartoonAvatarUrl!),
        backgroundColor: AppColors.card,
      );
    }

    // 否则显示宠物种类图标
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: isSelected
          ? AppColors.primary.withOpacity(0.2)
          : AppColors.card,
      child: Icon(
        _getSpeciesIcon(pet.species),
        size: size * 0.5,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }

  /// 获取宠物种类图标
  IconData _getSpeciesIcon(PetSpecies species) {
    switch (species) {
      case PetSpecies.cat:
        return Icons.pets;
      case PetSpecies.dog:
        return Icons.pets;
      case PetSpecies.rabbit:
        return Icons.cruelty_free;
      case PetSpecies.hamster:
        return Icons.pets;
      case PetSpecies.bird:
        return Icons.flutter_dash;
      case PetSpecies.other:
        return Icons.pets;
    }
  }

  /// 构建添加按钮
  Widget _buildAddButton(BuildContext context, int currentPetCount) {
    final isAtLimit = currentPetCount >= maxPets;

    return GestureDetector(
      onTap: () {
        if (isAtLimit) {
          // 已达上限，显示提示
          _showPetLimitDialog(context, currentPetCount);
        } else {
          // 未达上限，跳转创建页面
          context.push(AppRoutes.petCreate);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAtLimit ? Colors.grey.shade200 : AppColors.card,
          border: Border.all(
            color: isAtLimit ? Colors.grey.shade300 : AppColors.border,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: isAtLimit ? Colors.grey.shade400 : AppColors.textSecondary,
        ),
      ),
    );
  }

  /// 显示宠物数量上限提示对话框
  void _showPetLimitDialog(BuildContext context, int currentCount) {
    showDialog(
      context: context,
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
          '你最多可以拥有 $maxPets 只宠物（当前 $currentCount 只）。\n\n如需创建新宠物，请先放生现有宠物。',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  /// 显示放生操作菜单
  Future<void> _showReleaseMenu(
    BuildContext context,
    WidgetRef ref,
    PetModel pet,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动指示条
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 宠物信息
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildMenuPetAvatar(pet),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Lv.${pet.stats.level}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 放生选项
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.spa, color: Colors.pink.shade400),
                ),
                title: const Text('放生'),
                subtitle: const Text('永久删除此宠物'),
                onTap: () => Navigator.pop(context, 'release'),
              ),
              // 取消选项
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close, color: Colors.grey.shade600),
                ),
                title: const Text('取消'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (action == 'release' && context.mounted) {
      await _handleRelease(context, ref, pet);
    }
  }

  /// 构建菜单中的宠物头像
  Widget _buildMenuPetAvatar(PetModel pet) {
    if (pet.cartoonAvatarUrl != null && pet.cartoonAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(pet.cartoonAvatarUrl!),
        backgroundColor: AppColors.card,
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: Icon(
        _getSpeciesIcon(pet.species),
        color: AppColors.primary,
        size: 24,
      ),
    );
  }

  /// 处理放生操作
  Future<void> _handleRelease(
    BuildContext context,
    WidgetRef ref,
    PetModel pet,
  ) async {
    // 二次确认
    final confirmed = await ReleaseConfirmDialog.show(context, pet);

    if (confirmed && context.mounted) {
      final userId = ref.read(currentUserIdProvider);

      if (userId != null) {
        // 显示加载提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('正在放生...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );

        final storageService = ref.read(storageServiceProvider);
        final success = await ref.read(petInteractionProvider.notifier).releasePet(
          petId: pet.id,
          userId: userId,
          storageService: storageService,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Text(success ? '${pet.name} 已放生' : '操作失败，请重试'),
                ],
              ),
              backgroundColor: success ? Colors.green : Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }
}
