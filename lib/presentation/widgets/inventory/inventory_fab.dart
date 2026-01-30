import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 背包悬浮按钮
///
/// 点击后展开道具选择弹窗
class InventoryFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isExpanded;

  const InventoryFAB({
    super.key,
    required this.onPressed,
    this.isExpanded = false,
  });

  @override
  State<InventoryFAB> createState() => _InventoryFABState();
}

class _InventoryFABState extends State<InventoryFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(InventoryFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 3.14159 * 2,
          child: child,
        );
      },
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: AppColors.primary,
        elevation: 6,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            widget.isExpanded ? Icons.close : Icons.backpack,
            key: ValueKey(widget.isExpanded),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
