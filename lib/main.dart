import 'package:flutter/material.dart';
import 'package:web_labor_contract/Screen/User/Home/home_screen.dart';
import 'package:web_labor_contract/Screen/User/Home/navigation_drawer.dart';
import 'package:web_labor_contract/Screen/User/LoginScreen/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner:  false,
      home: Scaffold(
        body:  MenuScreen(),
      ),
    );
  }
}