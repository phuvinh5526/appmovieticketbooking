import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:movieticketbooking/View/splash_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'Providers/user_provider.dart';
import 'Providers/ticket_provider.dart';
import 'Utils/data_import_util.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Khởi tạo Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. NẠP TOÀN BỘ DỮ LIỆU (Chạy 1 lần để có dữ liệu hiển thị)
    // Sau khi nạp thành công và dữ liệu hiện trên App, hãy thêm dấu // vào đầu dòng này
    // await DataImportUtil.importAllDataDirectly();

    print('Firebase initialized and ALL data imported successfully');
  } catch (e) {
    print('Error during initialization: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TicketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Đặt Vé Xem Phim',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 26, color: Colors.grey),
          bodyMedium: TextStyle(
              fontSize: 18, color: const Color.fromARGB(255, 184, 49, 49)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
