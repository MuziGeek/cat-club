import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/item_model.dart';

/// 可拖拽道具卡片
///
/// 支持从背包拖拽到宠物区域
class DraggableItemCard extends StatelessWidget {
  final ItemModel item;
  final int quantity;
  final VoidCallback? onTap;

  const DraggableItemCard({
    super.key,
    required this.item,
    this.quantity = 1,
    this.onTap,
  });

  /// 获取道具图标
  IconData _getItemIcon() {
    switch (item.category) {
      case ItemCategory.food:
        return Icons.restaurant;
      case ItemCategory.accessory:
        return Icons.auto_awesome;
      case ItemCategory.clothing:
        return Icons.checkroom;
      case ItemCategory.background:
        return Icons.wallpaper;
      case ItemCategory.special:
        return Icons.star;
    }
  }

  /// 获取道具颜色
  Color _getItemColor() {
    return Color(item.rarityColorValue);
  }

  @override
  Widget build(BuildContext context) {
    final color = _getItemColor();

    return Draggable<ItemModel>(
      data: item,
      onDragStarted: () {
        HapticFeedback.selectionClick();
      },
      feedback: Material(
        color: Colors.transparent,
        child: _buildCard(color, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCard(color),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: _buildCard(color),
      ),
    );
  }

  Widget _buildCard(Color color, {bool isDragging = false}) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isDragging ? 1 : 0.5),
          width: isDragging ? 2 : 1,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 道具图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getItemIcon(),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          // 道具名称
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          // 数量标签
          if (quantity > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'x$quantity',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
