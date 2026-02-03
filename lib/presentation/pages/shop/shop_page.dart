import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/item_definitions.dart';
import '../../../data/models/item_model.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/user_provider.dart';

/// 商店页面
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ItemCategory _selectedCategory = ItemCategory.food;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedCategory = _getCategoryForIndex(_tabController.index);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ItemCategory _getCategoryForIndex(int index) {
    switch (index) {
      case 0:
        return ItemCategory.food;
      case 1:
        return ItemCategory.special;
      case 2:
        return ItemCategory.accessory;
      default:
        return ItemCategory.food;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('道具商店'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF6B6B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF6B6B),
          tabs: const [
            Tab(text: '食物'),
            Tab(text: '道具'),
            Tab(text: '配饰'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 货币栏
          userAsync.when(
            data: (user) => _buildCurrencyBar(user?.coins ?? 0, user?.diamonds ?? 0),
            loading: () => _buildCurrencyBar(0, 0),
            error: (_, __) => _buildCurrencyBar(0, 0),
          ),

          // 商品列表
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemGrid(ItemCategory.food),
                _buildItemGrid(ItemCategory.special),
                _buildItemGrid(ItemCategory.accessory),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBar(int coins, int diamonds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 金币
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFFFB300),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$coins',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8F00),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 钻石
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.diamond,
                  color: Color(0xFF00BCD4),
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$diamonds',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(ItemCategory category) {
    final items = ItemDefinitions.getItemsByCategory(category);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无商品',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    final rarityColor = Color(item.rarityColorValue);

    return GestureDetector(
      onTap: () => _showItemDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rarityColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图片区域
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Stack(
                  children: [
                    // 道具图标
                    Center(
                      child: Icon(
                        _getItemIcon(item.category),
                        size: 48,
                        color: rarityColor,
                      ),
                    ),
                    // 稀有度标签
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: rarityColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.rarityName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 信息区域
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // 价格
                    Row(
                      children: [
                        Icon(
                          item.currency == CurrencyType.coins
                              ? Icons.monetization_on
                              : Icons.diamond,
                          size: 16,
                          color: item.currency == CurrencyType.coins
                              ? const Color(0xFFFFB300)
                              : const Color(0xFF00BCD4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.currency == CurrencyType.coins
                                ? const Color(0xFFFF8F00)
                                : const Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getItemIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.food:
        return Icons.restaurant;
      case ItemCategory.special:
        return Icons.auto_awesome;
      case ItemCategory.accessory:
        return Icons.checkroom;
      case ItemCategory.clothing:
        return Icons.dry_cleaning;
      case ItemCategory.background:
        return Icons.wallpaper;
    }
  }

  void _showItemDetail(ItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ItemDetailSheet(item: item),
    );
  }
}

/// 商品详情底部弹窗
class _ItemDetailSheet extends ConsumerStatefulWidget {
  final ItemModel item;

  const _ItemDetailSheet({required this.item});

  @override
  ConsumerState<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends ConsumerState<_ItemDetailSheet> {
  bool _isPurchasing = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final rarityColor = Color(item.rarityColorValue);
    final userAsync = ref.watch(userProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动指示器
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // 道具图标
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getItemIcon(item.category),
                  size: 48,
                  color: rarityColor,
                ),
              ),
              const SizedBox(height: 16),

              // 名称和稀有度
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.rarityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 描述
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // 效果
              if (item.effects.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '效果',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: item.effects.entries.map((entry) {
                          return _buildEffectChip(entry.key, entry.value);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 购买按钮
              userAsync.when(
                data: (user) {
                  final hasEnough = item.currency == CurrencyType.coins
                      ? (user?.coins ?? 0) >= item.price
                      : (user?.diamonds ?? 0) >= item.price;

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: hasEnough && !_isPurchasing
                          ? () => _handlePurchase(item)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.currency == CurrencyType.coins
                                      ? Icons.monetization_on
                                      : Icons.diamond,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  hasEnough
                                      ? '购买 ${item.price}'
                                      : '余额不足',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEffectChip(String key, int value) {
    final effectNames = {
      'hunger': '饱腹',
      'happiness': '快乐',
      'energy': '精力',
      'health': '健康',
      'cleanliness': '清洁',
    };

    final effectIcons = {
      'hunger': Icons.restaurant,
      'happiness': Icons.favorite,
      'energy': Icons.bolt,
      'health': Icons.health_and_safety,
      'cleanliness': Icons.shower,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            effectIcons[key] ?? Icons.star,
            size: 16,
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 4),
          Text(
            '${effectNames[key] ?? key} +$value',
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getItemIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.food:
        return Icons.restaurant;
      case ItemCategory.special:
        return Icons.auto_awesome;
      case ItemCategory.accessory:
        return Icons.checkroom;
      case ItemCategory.clothing:
        return Icons.dry_cleaning;
      case ItemCategory.background:
        return Icons.wallpaper;
    }
  }

  Future<void> _handlePurchase(ItemModel item) async {
    setState(() => _isPurchasing = true);

    try {
      // 扣除货币并添加道具
      await ref.read(userNotifierProvider.notifier).purchaseItem(
            itemId: item.id,
            price: item.price,
            currency: item.currency,
          );

      // 添加到背包
      ref.read(inventoryNotifierProvider.notifier).addItem(item);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功购买 ${item.name}！'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('购买失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }
}
