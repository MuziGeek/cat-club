import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../providers/check_in_provider.dart';
import '../../../providers/inventory_provider.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/photo_upload_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/storage_service.dart';
import '../../router/app_router.dart';
import '../../widgets/inventory/inventory_fab.dart';
import '../../widgets/inventory/inventory_popup.dart';
import '../../widgets/pet/interactive_pet_widget.dart';
import '../../widgets/pet/pet_selector.dart';
import '../../widgets/pet/pet_status_bar.dart';
import '../../widgets/photo/photo_picker_sheet.dart';
import 'check_in_dialog.dart';

/// 宠物房间主页面
///
/// 沉浸式交互设计：
/// - 点击宠物：抚摸
/// - 长按宠物：休息
/// - 双击宠物：玩耍
/// - 拖拽道具到宠物：喂食/清洁
class PetRoomPage extends ConsumerStatefulWidget {
  const PetRoomPage({super.key});

  @override
  ConsumerState<PetRoomPage> createState() => _PetRoomPageState();
}

class _PetRoomPageState extends ConsumerState<PetRoomPage>
    with WidgetsBindingObserver {
  bool _isInventoryOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAutoSelectListener();
      _syncStatusOnInit();
      _checkAndShowCheckInDialog();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncStatusOnResume();
    }
  }

  /// 应用启动时同步状态
  void _syncStatusOnInit() {
    final petId = ref.read(selectedPetIdProvider);
    if (petId != null) {
      ref.read(petInteractionProvider.notifier).syncDecayedStatusIfNeeded(petId);
    }
  }

  /// 应用恢复时同步状态
  void _syncStatusOnResume() {
    final petId = ref.read(selectedPetIdProvider);
    if (petId != null) {
      ref.read(petInteractionProvider.notifier).syncDecayedStatusIfNeeded(petId);
    }
  }

  /// 检查并显示签到对话框
  void _checkAndShowCheckInDialog() async {
    // 延迟一下等页面加载完成
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final checkInState = ref.read(checkInProvider);
    if (!checkInState.hasCheckedInToday && !checkInState.isLoading) {
      final success = await showCheckInDialog(context);
      if (success && mounted) {
        // 签到成功，强制刷新用户数据
        ref.invalidate(currentUserProvider);
        ref.read(inventoryNotifierProvider.notifier).refresh();
      }
    }
  }

  void _setupAutoSelectListener() {
    ref.listenManual(userPetsProvider, (previous, next) {
      next.whenData((pets) {
        final selectedPetId = ref.read(selectedPetIdProvider);

        // 检查当前选中的宠物是否还存在（处理删除后的切换）
        final selectedPetExists = pets.any((p) => p.id == selectedPetId);

        if (!selectedPetExists) {
          if (pets.isEmpty) {
            // 没有宠物了，清空选中状态
            ref.read(selectedPetIdProvider.notifier).state = null;
          } else {
            // 切换到第一只宠物
            ref.read(selectedPetIdProvider.notifier).state = pets.first.id;
          }
        } else if (selectedPetId == null && pets.isNotEmpty) {
          // 初始加载时自动选中第一只
          ref.read(selectedPetIdProvider.notifier).state = pets.first.id;
        }
      });
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final petAsync = ref.watch(selectedPetWithDecayProvider);
    final petsAsync = ref.watch(userPetsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: petsAsync.when(
          data: (pets) {
            if (pets.isEmpty) {
              return _buildNoPetView();
            }
            return Stack(
              children: [
                // 主内容
                Column(
                  children: [
                    _buildTopBar(userAsync),
                    // 宠物切换栏（多只宠物时显示）
                    const PetSelector(),
                    Expanded(
                      child: _buildPetArea(petAsync),
                    ),
                    _buildStatusBars(petAsync),
                    const SizedBox(height: 80), // 为底部弹窗留空间
                  ],
                ),

                // 背包弹窗
                if (_isInventoryOpen)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: InventoryPopup(
                      onClose: () => setState(() => _isInventoryOpen = false),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('加载失败: $e')),
        ),
      ),
      floatingActionButton: petsAsync.valueOrNull?.isNotEmpty == true
          ? InventoryFAB(
              isExpanded: _isInventoryOpen,
              onPressed: () {
                setState(() => _isInventoryOpen = !_isInventoryOpen);
              },
            )
          : null,
    );
  }

  /// 无宠物视图
  Widget _buildNoPetView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '你还没有宠物',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 8),
          Text(
            '创建你的第一只虚拟宠物吧',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.petCreate),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('创建宠物', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 顶部信息栏
  Widget _buildTopBar(AsyncValue<dynamic> userAsync) {
    final user = userAsync.valueOrNull;
    final int coins = (user?.coins as int?) ?? 0;
    final int diamonds = (user?.diamonds as int?) ?? 0;

    final pet = ref.watch(selectedPetWithDecayProvider).valueOrNull;
    final level = pet?.stats.level ?? 1;

    final checkInState = ref.watch(checkInProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 签到按钮
          GestureDetector(
            onTap: () async {
              print('[PET_ROOM] 签到按钮点击');
              final success = await showCheckInDialog(context);
              print('[PET_ROOM] 签到对话框返回: success=$success');
              if (success && mounted) {
                // 签到成功，强制刷新用户数据
                print('[PET_ROOM] 正在 invalidate currentUserProvider');
                ref.invalidate(currentUserProvider);
                ref.read(inventoryNotifierProvider.notifier).refresh();
                print('[PET_ROOM] invalidate 完成');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: checkInState.hasCheckedInToday
                    ? Colors.grey[200]
                    : const Color(0xFFFFE0E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                checkInState.hasCheckedInToday
                    ? Icons.check_circle
                    : Icons.calendar_today,
                color: checkInState.hasCheckedInToday
                    ? Colors.grey
                    : const Color(0xFFFF6B6B),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 金币显示（点击进入商店）
          GestureDetector(
            onTap: () => context.push(AppRoutes.shop),
            child: Container(
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
                  Text(_formatNumber(coins), style: AppTextStyles.numberSmall),
                  const SizedBox(width: 4),
                  const Icon(Icons.add_circle_outline, color: Colors.grey, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 钻石显示（点击进入商店）
          GestureDetector(
            onTap: () => context.push(AppRoutes.shop),
            child: Container(
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
                  Text(_formatNumber(diamonds), style: AppTextStyles.numberSmall),
                ],
              ),
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
                Text('Lv.$level', style: AppTextStyles.numberSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 设置按钮
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }

  /// 宠物展示区域（使用沉浸式交互组件）
  Widget _buildPetArea(AsyncValue<PetModel?> petAsync) {
    return petAsync.when(
      data: (pet) {
        if (pet == null) {
          return const Center(child: Text('请选择宠物'));
        }
        return InteractivePetWidget(
          pet: pet,
          onPet: () => _handlePet(pet.id),
          onRest: () => _handleRest(pet.id),
          onPlay: () => _handlePlay(pet.id),
          onAvatarTap: () => _handleUpdatePhoto(pet.id),
          onItemDropped: (item) => _handleItemDropped(pet.id, item),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载宠物失败: $e')),
    );
  }

  /// 状态条区域
  Widget _buildStatusBars(AsyncValue<PetModel?> petAsync) {
    final pet = petAsync.valueOrNull;
    final status = pet?.status ?? const PetStatus();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PetStatusBar(
                  label: '心情',
                  value: status.happiness,
                  color: AppColors.happinessColor,
                  icon: Icons.sentiment_satisfied_alt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PetStatusBar(
                  label: '饱腹',
                  value: status.hunger,
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
                  value: status.energy,
                  color: AppColors.energyColor,
                  icon: Icons.bolt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PetStatusBar(
                  label: '健康',
                  value: status.health,
                  color: AppColors.healthColor,
                  icon: Icons.favorite,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PetStatusBar(
            label: '清洁',
            value: status.cleanliness,
            color: AppColors.cleanlinessColor,
            icon: Icons.bathtub,
          ),
        ],
      ),
    );
  }

  // === 交互处理方法 ===

  /// 处理抚摸
  void _handlePet(String petId) async {
    final success = await ref.read(petInteractionProvider.notifier).pet(petId);
    if (success && mounted) {
      _showFeedback('抚摸成功', '心情 +15, 亲密度 +10', Icons.favorite, Colors.pink);
    }
  }

  /// 处理休息
  void _handleRest(String petId) async {
    final success = await ref.read(petInteractionProvider.notifier).rest(petId);
    if (success && mounted) {
      _showFeedback('休息完成', '精力 +30', Icons.bedtime, AppColors.energyColor);
    }
  }

  /// 处理玩耍
  void _handlePlay(String petId) async {
    final success = await ref.read(petInteractionProvider.notifier).play(petId);
    if (success && mounted) {
      _showFeedback('玩耍成功', '心情 +20, 精力 -10', Icons.sports_esports, AppColors.happinessColor);
    }
  }

  /// 处理更新照片
  void _handleUpdatePhoto(String petId) async {
    // 显示照片选择弹窗
    final selected = await PhotoPickerSheet.show(context);

    if (!selected || !mounted) return;

    // 获取选中的照片
    final photoState = ref.read(photoUploadProvider);
    final photoFile = photoState.previewFile;

    if (photoFile == null) {
      _showSnackBar('未选择照片');
      return;
    }

    // 显示上传中提示
    _showSnackBar('正在上传照片...');

    // 上传照片
    final storageService = ref.read(storageServiceProvider);
    final newUrl = await ref.read(petInteractionProvider.notifier).updatePetPhoto(
          petId: petId,
          photoFile: photoFile,
          storageService: storageService,
        );

    // 清理状态
    ref.read(photoUploadProvider.notifier).reset();

    if (!mounted) return;

    if (newUrl != null) {
      _showFeedback('更新成功', '宠物照片已更新', Icons.check_circle, Colors.green);
    } else {
      _showSnackBar('照片上传失败，请重试');
    }
  }

  /// 处理道具拖放
  void _handleItemDropped(String petId, ItemModel item) async {
    // 关闭背包弹窗
    setState(() => _isInventoryOpen = false);

    // 使用道具
    final used = ref.read(inventoryNotifierProvider.notifier).useItem(item);
    if (!used) {
      _showSnackBar('道具不足');
      return;
    }

    bool success = false;
    String title = '';
    String message = '';
    IconData icon = Icons.check;
    Color color = AppColors.primary;

    // 根据道具类型执行不同操作
    if (item.category == ItemCategory.food) {
      // 食物类道具 - 喂食
      final hungerGain = item.effects['hunger'] ?? 20;
      success = await ref.read(petInteractionProvider.notifier).feed(petId, hungerGain: hungerGain);
      title = '喂食成功';
      message = '饱腹度 +$hungerGain';
      icon = Icons.restaurant;
      color = AppColors.hungerColor;
    } else {
      // 其他道具 - 清洁
      final cleanlinessGain = item.effects['cleanliness'] ?? 25;
      success = await ref.read(petInteractionProvider.notifier).clean(petId, cleanlinessGain: cleanlinessGain);
      title = '清洁完成';
      message = '清洁度 +$cleanlinessGain';
      icon = Icons.bathtub;
      color = AppColors.cleanlinessColor;
    }

    if (success && mounted) {
      _showFeedback(title, message, icon, color);
    }
  }

  /// 显示反馈弹窗
  void _showFeedback(String title, String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
      ),
    );
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
