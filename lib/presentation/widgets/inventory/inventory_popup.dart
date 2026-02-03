import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/inventory_provider.dart';
import 'draggable_item_card.dart';

/// 道具选择弹窗
///
/// 展示用户背包中的道具，支持拖拽到宠物
class InventoryPopup extends ConsumerWidget {
  final VoidCallback onClose;

  const InventoryPopup({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 inventoryNotifierProvider 实现实时更新
    final inventory = ref.watch(inventoryNotifierProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.backpack, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text('背包', style: AppTextStyles.h3),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
                color: AppColors.textSecondary,
              ),
            ],
          ),

          const Divider(height: 16),

          // 使用提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '拖拽道具到宠物身上使用',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 道具列表
          inventory.isEmpty ? _buildEmptyState() : _buildItemGrid(inventory),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              '背包空空如也',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Text(
              '去商店购买道具吧',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid(Map<ItemModel, int> inventory) {
    final items = inventory.entries.toList();

    // 按类别分组
    final foodItems = items.where((e) => e.key.category == ItemCategory.food).toList();
    final otherItems = items.where((e) => e.key.category != ItemCategory.food).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 食物类
        if (foodItems.isNotEmpty) ...[
          _buildCategoryLabel('食物', Icons.restaurant),
          const SizedBox(height: 8),
          _buildItemRow(foodItems),
        ],

        // 其他道具
        if (otherItems.isNotEmpty) ...[
          if (foodItems.isNotEmpty) const SizedBox(height: 16),
          _buildCategoryLabel('道具', Icons.inventory_2),
          const SizedBox(height: 8),
          _buildItemRow(otherItems),
        ],
      ],
    );
  }

  Widget _buildCategoryLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(List<MapEntry<ItemModel, int>> items) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final entry = items[index];
          return DraggableItemCard(
            item: entry.key,
            quantity: entry.value,
          );
        },
      ),
    );
  }
}
