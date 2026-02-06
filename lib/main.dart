import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'services/cloudbase_auth_http_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive 本地存储
  await Hive.initFlutter();

  // 初始化 CloudBase 认证服务
  final authService = CloudbaseAuthHttpService();
  await authService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        // 注入已初始化的认证服务
        authServiceProvider.overrideWithValue(authService),
      ],
      child: const CatClubApp(),
    ),
  );
}
