import 'package:flutter/material.dart';

/// 应用颜色定义
class AppColors {
  AppColors._();

  // 主色 - 温暖橙色
  static const Color primary = Color(0xFFFF9F5A);
  static const Color primaryLight = Color(0xFFFFBE8A);
  static const Color primaryDark = Color(0xFFE8823D);

  // 辅助色 - 柔和粉色
  static const Color secondary = Color(0xFFFFB5C5);
  static const Color secondaryLight = Color(0xFFFFD4DE);
  static const Color secondaryDark = Color(0xFFE8909F);

  // 强调色 - 活力蓝
  static const Color accent = Color(0xFF5BC0EB);

  // 背景色
  static const Color background = Color(0xFFFFF8F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFAF5);

  // 文字颜色
  static const Color textPrimary = Color(0xFF3D3D3D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // 状态颜色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF2196F3);

  // 状态条颜色
  static const Color happinessColor = Color(0xFFFFD700);
  static const Color hungerColor = Color(0xFFFF7043);
  static const Color energyColor = Color(0xFF42A5F5);
  static const Color healthColor = Color(0xFF66BB6A);
  static const Color cleanlinessColor = Color(0xFF81D4FA);

  // 边框颜色
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFF0F0F0);

  // 遮罩颜色
  static const Color overlay = Color(0x80000000);

  // 渐变色
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// 纪念模式颜色
class MemorialColors {
  MemorialColors._();

  static const Color background = Color(0xFFFFF8E7);
  static const Color primary = Color(0xFFD4A574);
  static const Color accent = Color(0xFFE8C4A0);
  static const Color text = Color(0xFF5C4033);
  static const Color starlight = Color(0xFFFFFACD);
  static const Color warmGlow = Color(0xFFFFF0D0);
}
