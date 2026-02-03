import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/pet_model.dart';

/// 放生确认对话框
///
/// 二次确认机制：用户需要输入宠物名称才能确认放生
class ReleaseConfirmDialog extends StatefulWidget {
  final PetModel pet;

  const ReleaseConfirmDialog({
    super.key,
    required this.pet,
  });

  /// 显示放生确认对话框
  ///
  /// 返回 true 表示用户确认放生，false 表示取消
  static Future<bool> show(BuildContext context, PetModel pet) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReleaseConfirmDialog(pet: pet),
    );
    return result ?? false;
  }

  @override
  State<ReleaseConfirmDialog> createState() => _ReleaseConfirmDialogState();
}

class _ReleaseConfirmDialogState extends State<ReleaseConfirmDialog> {
  final _nameController = TextEditingController();
  bool _isNameMatch = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkNameMatch);
  }

  void _checkNameMatch() {
    setState(() {
      _isNameMatch = _nameController.text.trim() == widget.pet.name;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text('确定要放生吗？'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 宠物信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 宠物头像
                  _buildPetAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pet.name,
                          style: AppTextStyles.h4,
                        ),
                        Text(
                          'Lv.${widget.pet.stats.level} · ${widget.pet.species.displayName}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 警告提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此操作不可恢复，宠物数据将永久删除',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 确认输入提示
            Text(
              '请输入宠物名称确认：',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // 名称输入框
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: widget.pet.name,
                hintStyle: TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _isNameMatch ? Colors.red : AppColors.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _isNameMatch
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (_isNameMatch) {
                  Navigator.pop(context, true);
                }
              },
            ),

            if (!_isNameMatch && _nameController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '名称不匹配',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            '取消',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isNameMatch ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: const Text('确认放生'),
        ),
      ],
    );
  }

  Widget _buildPetAvatar() {
    if (widget.pet.cartoonAvatarUrl != null &&
        widget.pet.cartoonAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(widget.pet.cartoonAvatarUrl!),
        backgroundColor: AppColors.card,
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      child: Icon(
        Icons.pets,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}

/// PetSpecies 扩展 - 显示名称
extension PetSpeciesDisplayName on PetSpecies {
  String get displayName {
    switch (this) {
      case PetSpecies.cat:
        return '猫咪';
      case PetSpecies.dog:
        return '狗狗';
      case PetSpecies.rabbit:
        return '兔子';
      case PetSpecies.hamster:
        return '仓鼠';
      case PetSpecies.bird:
        return '小鸟';
      case PetSpecies.other:
        return '其他';
    }
  }
}
