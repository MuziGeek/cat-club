import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/pet/pet_status_bar.dart';

/// 宠物房间主页面
class PetRoomPage extends ConsumerStatefulWidget {
  const PetRoomPage({super.key});

  @override
  ConsumerState<PetRoomPage> createState() => _PetRoomPageState();
}

class _PetRoomPageState extends ConsumerState<PetRoomPage> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部信息栏
            _buildTopBar(),

            // 宠物展示区域
            Expanded(
              child: _buildPetArea(),
            ),

            // 状态条区域
            _buildStatusBars(),

            // 快捷操作栏
            _buildActionBar(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  /// 顶部信息栏
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 货币显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('1,000', style: AppTextStyles.numberSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond, color: Colors.blue, size: 20),
                const SizedBox(width: 4),
                Text('50', style: AppTextStyles.numberSmall),
              ],
            ),
          ),

          const Spacer(),

          // 等级显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 20),
                const SizedBox(width: 4),
                Text('Lv.5', style: AppTextStyles.numberSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
            onPressed: () {
              // TODO: 打开设置
            },
          ),
        ],
      ),
    );
  }

  /// 宠物展示区域
  Widget _buildPetArea() {
    return GestureDetector(
      onTapDown: (details) {
        // TODO: 处理触摸互动
        _showHeartAnimation(details.localPosition);
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 背景装饰
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryLight.withOpacity(0.1),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 宠物名称
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Text('小橘', style: AppTextStyles.petName),
                    const SizedBox(height: 4),
                    Text('心情不错 ♪', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),

            // 宠物形象（占位）
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '点击宠物进行抚摸',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 状态条区域
  Widget _buildStatusBars() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PetStatusBar(
                  label: '心情',
                  value: 75,
                  color: AppColors.happinessColor,
                  icon: Icons.sentiment_satisfied_alt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PetStatusBar(
                  label: '饱腹',
                  value: 60,
                  color: AppColors.hungerColor,
                  icon: Icons.restaurant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PetStatusBar(
                  label: '精力',
                  value: 85,
                  color: AppColors.energyColor,
                  icon: Icons.bolt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PetStatusBar(
                  label: '健康',
                  value: 90,
                  color: AppColors.healthColor,
                  icon: Icons.favorite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 快捷操作栏
  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.restaurant,
            label: '喂食',
            color: AppColors.hungerColor,
            onTap: () {
              // TODO: 喂食逻辑
              _showSnackBar('已喂食，饱腹度 +20');
            },
          ),
          _buildActionButton(
            icon: Icons.pets,
            label: '抚摸',
            color: AppColors.happinessColor,
            onTap: () {
              // TODO: 抚摸逻辑
              _showSnackBar('抚摸成功，心情 +10');
            },
          ),
          _buildActionButton(
            icon: Icons.checkroom,
            label: '换装',
            color: AppColors.secondary,
            onTap: () {
              // TODO: 换装逻辑
            },
          ),
          _buildActionButton(
            icon: Icons.camera_alt,
            label: '拍照',
            color: AppColors.accent,
            onTap: () {
              // TODO: 拍照逻辑
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  /// 底部导航栏
  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        setState(() => _currentNavIndex = index);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '首页',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outlined),
          activeIcon: Icon(Icons.people),
          label: '社区',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: '背包',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: '我的',
        ),
      ],
    );
  }

  void _showHeartAnimation(Offset position) {
    // TODO: 实现爱心飘散动画
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
