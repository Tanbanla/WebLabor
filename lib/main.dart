import 'package:flutter/material.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Screen/User/Home/navigation_drawer.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:web_labor_contract/Screen/User/LoginScreen/sign_in_screen.dart';
import 'package:get/get.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  Get.put(AuthState());
  // Khởi tạo AuthState và load dữ liệu đã lưu
  final authState = AuthState();
  await authState.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('vi'), Locale('ja')],
      path: 'assets/translations',
      fallbackLocale: Locale('vi'),
      child: ChangeNotifierProvider(
        create: (context) => authState,
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Consumer<AuthState>(
        builder: (context, authState, child) {
          if (authState.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return authState.isAuthenticated
              ? const MenuScreen()
              : const SignInScreen();
        },
      ),
    );
  }
}
