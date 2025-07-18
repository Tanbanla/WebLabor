import 'package:flutter/material.dart';
import 'package:web_labor_contract/API/Login_Controller/api_login_controller.dart';
import 'package:web_labor_contract/Screen/User/Home/home_screen.dart';
import 'package:web_labor_contract/Screen/User/Home/navigation_drawer.dart';
import 'package:web_labor_contract/Screen/User/LoginScreen/login_screen.dart';
import 'package:web_labor_contract/Screen/User/LoginScreen/sign_in_screen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MenuScreen()
      // Consumer<AuthState>(
      //   builder: (context, authState, child) {
      //     return authState.isAuthenticated
      //         ? const MenuScreen()
      //         : const SignInScreen();
      //   },
      // ),
    );
  }
}
