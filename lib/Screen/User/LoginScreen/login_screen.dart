import 'dart:math';
import 'package:page_transition/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Screen/User/Home/home_screen.dart';
import 'package:web_labor_contract/Common/custom_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Center(
      child: Container(
        height: size.height - 120,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'LABOR CONTRACT EVALUATION',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Common.primaryColor,
                ),
              ),
              Image.asset('assets/img/signin.png', height: 190),
              const SizedBox(height: 8),
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w700,
                  color: Common.primaryColor,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 30),
              const CustomField(
                icon: Icons.alternate_email,
                obscureText: false,
                hinText: 'ADID',
              ),
              const SizedBox(height: 16),
              const CustomField(
                icon: Icons.lock,
                obscureText: true,
                hinText: 'Enter Password',
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen() ,
                          ),
                        );
                  // Navigator.pushReplacement(
                  //   context,
                  //   PageTransition(
                  //       child: const HomeScreen(),
                  //       type: PageTransitionType.bottomToTop));
                },
                child: Container(
                  width: size.width / 5,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Common.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: const Center(
                    child: Text(
                      'Sign In',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("-----------"),
                    Image.asset(
                      'assets/img/logo_company.png',
                      height: 120,
                      width: 120,
                    ),
                    const Text("-----------"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
