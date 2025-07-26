import 'package:flutter/material.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Screen/User/Home/home_screen.dart';
import 'package:web_labor_contract/Screen/User/Home/navigation_drawer.dart';
import 'package:web_labor_contract/Screen/User/LoginScreen/sign_in_screen.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: [Locale('vi'), Locale('ja')],
      path: 'assets/translations',
      fallbackLocale: Locale('vi'),
      child: ChangeNotifierProvider(
        create: (context) => AuthState(), // Tạo instance của AuthState
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
      home: //MenuScreen()
      Consumer<AuthState>(
        builder: (context, authState, child) {
          return authState.isAuthenticated
              ? const MenuScreen()
              : const SignInScreen();
        },
      ),
    );
  }
}