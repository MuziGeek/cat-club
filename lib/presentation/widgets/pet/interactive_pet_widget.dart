import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/pet_model.dart';

/// 宠物当前行为状态
enum PetBehavior {
  idle,      // 待机
  happy,     // 开心（被抚摸）
  eating,    // 进食
  sleeping,  // 休息
  playing,   // 玩耍
  cleaning,  // 被清洁
}

/// 可交互宠物组件
///
/// 支持手势交互：
/// - 单击：抚摸
/// - 长按：休息
/// - 双击：玩耍
/// - 接受拖拽道具：喂食/清洁
class InteractivePetWidget extends StatefulWidget {
  final PetModel pet;
  final VoidCallback? onPet;           // 抚摸回调
  final VoidCallback? onRest;          // 休息回调
  final VoidCallback? onPlay;          // 玩耍回调
  final void Function(ItemModel)? onItemDropped;  // 道具拖放回调

  const InteractivePetWidget({
    super.key,
    required this.pet,
    this.onPet,
    this.onRest,
    this.onPlay,
    this.onItemDropped,
  });

  @override
  State<InteractivePetWidget> createState() => _InteractivePetWidgetState();
}

class _InteractivePetWidgetState extends State<InteractivePetWidget>
    with SingleTickerProviderStateMixin {
  PetBehavior _behavior = PetBehavior.idle;
  bool _isDragOver = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 处理单击 - 抚摸
  void _handleTap() {
    HapticFeedback.lightImpact();
    _playFeedbackAnimation();
    _setBehaviorTemporarily(PetBehavior.happy, duration: const Duration(seconds: 1));
    widget.onPet?.call();
  }

  /// 处理长按 - 休息
  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    _playFeedbackAnimation();
    _setBehaviorTemporarily(PetBehavior.sleeping, duration: const Duration(seconds: 2));
    widget.onRest?.call();
  }

  /// 处理双击 - 玩耍
  void _handleDoubleTap() {
    HapticFeedback.heavyImpact();
    _playFeedbackAnimation();
    _setBehaviorTemporarily(PetBehavior.playing, duration: const Duration(seconds: 1));
    widget.onPlay?.call();
  }

  /// 处理道具拖入
  void _handleItemDropped(ItemModel item) {
    HapticFeedback.heavyImpact();
    _playFeedbackAnimation();

    // 根据道具类型设置行为
    if (item.category == ItemCategory.food) {
      _setBehaviorTemporarily(PetBehavior.eating, duration: const Duration(seconds: 1));
    } else {
      _setBehaviorTemporarily(PetBehavior.cleaning, duration: const Duration(seconds: 1));
    }

    widget.onItemDropped?.call(item);
  }

  /// 临时设置行为状态
  void _setBehaviorTemporarily(PetBehavior behavior, {required Duration duration}) {
    setState(() => _behavior = behavior);
    Future.delayed(duration, () {
      if (mounted) {
        setState(() => _behavior = PetBehavior.idle);
      }
    });
  }

  /// 播放反馈动画
  void _playFeedbackAnimation() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  /// 获取宠物图标（根据状态）
  IconData _getPetIcon() {
    // 优先显示行为状态图标
    switch (_behavior) {
      case PetBehavior.sleeping:
        return Icons.nights_stay;
      case PetBehavior.eating:
        return Icons.restaurant;
      case PetBehavior.playing:
        return Icons.sports_esports;
      case PetBehavior.cleaning:
        return Icons.bathtub;
      case PetBehavior.happy:
        return Icons.favorite;
      case PetBehavior.idle:
        break;
    }

    // 根据物种和心情返回图标
    final status = widget.pet.status;

    // 饥饿状态优先
    if (status.hunger < 30) {
      return Icons.restaurant_menu;
    }

    // 根据心情选择表情
    if (status.happiness > 70) {
      return Icons.sentiment_very_satisfied;
    } else if (status.happiness > 30) {
      return Icons.sentiment_satisfied;
    } else {
      return Icons.sentiment_dissatisfied;
    }
  }

  /// 获取宠物颜色
  Color _getPetColor() {
    switch (widget.pet.appearance.furColor.toLowerCase()) {
      case 'orange':
        return Colors.orange;
      case 'white':
        return Colors.grey.shade400;
      case 'black':
        return Colors.black87;
      case 'brown':
        return Colors.brown;
      case 'gray':
      case 'grey':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  /// 获取状态提示文字
  String _getStatusHint() {
    switch (_behavior) {
      case PetBehavior.happy:
        return '喵~ 好舒服';
      case PetBehavior.sleeping:
        return 'Zzz...';
      case PetBehavior.eating:
        return '好吃!';
      case PetBehavior.playing:
        return '好开心!';
      case PetBehavior.cleaning:
        return '干干净净~';
      case PetBehavior.idle:
        break;
    }

    // 根据状态给出提示
    final status = widget.pet.status;
    if (status.hunger < 30) return '好饿...';
    if (status.happiness < 30) return '需要关爱';
    if (status.energy < 30) return '好累...';
    return '点击、长按或双击与我互动';
  }

  @override
  Widget build(BuildContext context) {
    final petColor = _getPetColor();

    return DragTarget<ItemModel>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isDragOver = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isDragOver = false);
      },
      onAcceptWithDetails: (details) {
        setState(() => _isDragOver = false);
        _handleItemDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: _isDragOver
                ? Border.all(color: AppColors.primary, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: _isDragOver
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isDragOver ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 背景渐变
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (_isDragOver ? AppColors.primary : AppColors.primaryLight)
                              .withOpacity(0.1),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 宠物名称和心情
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Text(widget.pet.name, style: AppTextStyles.petName),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.pet.moodDescription} ♪',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),

              // 可交互宠物区域
              Center(
                child: GestureDetector(
                  onTap: _handleTap,
                  onLongPress: _handleLongPress,
                  onDoubleTap: _handleDoubleTap,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_bounceAnimation.value),
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 宠物形象
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: petColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: _behavior != PetBehavior.idle
                                ? [
                                    BoxShadow(
                                      color: petColor.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : null,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _getPetIcon(),
                              key: ValueKey(_behavior),
                              size: 80,
                              color: petColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 状态提示
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _getStatusHint(),
                            key: ValueKey(_behavior),
                            style: AppTextStyles.caption.copyWith(
                              fontStyle: _behavior == PetBehavior.idle
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: _behavior == PetBehavior.idle
                                  ? AppColors.textHint
                                  : petColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 亲密度显示
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.pink, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.pet.intimacyLevelName,
                        style: AppTextStyles.caption.copyWith(color: Colors.pink),
                      ),
                    ],
                  ),
                ),
              ),

              // 拖拽提示
              if (_isDragOver)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '松开使用',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
