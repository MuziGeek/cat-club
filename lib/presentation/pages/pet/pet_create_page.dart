import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/pet_model.dart';
import '../../../providers/pet_provider.dart';
import '../../router/app_router.dart';
import '../../widgets/common/app_button.dart';

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

    // 调用 petCreateProvider 创建宠物
    final petId = await ref.read(petCreateProvider.notifier).createPet(
      name: _nameController.text.trim(),
      species: _selectedSpecies,
      appearance: appearance,
    );

    if (!mounted) return;

    if (petId != null) {
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
    return GestureDetector(
      onTap: () {
        // TODO: 实现图片选择功能
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('照片上传功能开发中，敬请期待')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
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
                  Text('上传宠物照片', style: AppTextStyles.body1),
                  Text(
                    'AI 将为你生成专属卡通形象',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
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
}
