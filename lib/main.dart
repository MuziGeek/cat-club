import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'config/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase（使用 try-catch 避免重复初始化错误）
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // 忽略重复初始化错误
    debugPrint('Firebase already initialized: $e');
  }

  // 初始化 Hive 本地存储
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: CatClubApp(),
    ),
  );
}
